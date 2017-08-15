module Metrician
  module Middleware
    # RequestTiming and ApplicationTiming work in concert to time the middleware
    # separate from the request processing. RequestTiming should be the first
    # or near first middleware loaded since it will be timing from the moment
    # the the app server is hit and setting up the env for tracking the
    # middleware execution time. RequestTiming should be the last or near
    # last middleware loaded as it times the application execution (separate from
    # middleware).
    class RequestTiming

      WEB_METRIC = "web".freeze

      def initialize(app)
        @app = app
      end

      def call(env)
        process_start_time = Time.now.to_f
        response_size = 0

        if Middleware.queue_time?
          queue_start_time = self.class.extract_request_start_time(env)
          gauge(:queue_time, process_start_time - queue_start_time) if queue_start_time
        end

        if Middleware.idle?
          if @request_end_time
            gauge(:idle, process_start_time - @request_end_time)
            @request_end_time = nil
          end
        end

        begin
          status, headers, body = @app.call(env)
          [status, headers, body]
        ensure
          if need_route?
            current_route = self.class.extract_route(
              controller: env[ENV_CONTROLLER_PATH],
              path: env[ENV_REQUEST_PATH]
            )
            if Middleware.request_timing_required?
              request_time = env[ENV_REQUEST_TOTAL_TIME].to_f
              env[ENV_REQUEST_TOTAL_TIME] = nil
            end
            if Middleware.request?
              gauge(:request, request_time, current_route)
            end
            if Middleware.apdex?
              apdex(request_time)
            end
            if Middleware.error?
              # We to_i the status because in some circumstances it is a
              # Fixnum and some it is a string. Because why not.
              increment(:error, current_route) if $ERROR_INFO || status.to_i >= 500
            end
            if Middleware.response_size?
              # Note that 30xs don't have content-length, so cached
              # items will report other metrics but not this one
              response_size = self.class.get_response_size(headers: headers, body: body)
              if response_size && !response_size.to_s.strip.empty?
                gauge(:response_size, response_size.to_i, current_route)
              end
            end
          end

          if Middleware.middleware?
            middleware_time = (Time.now.to_f - process_start_time) - request_time
            gauge(:middleware, middleware_time)
          end

          @request_end_time = Time.now.to_f
        end
      end

      def gauge(kind, value, route = nil)
        Metrician.gauge("#{WEB_METRIC}.#{kind}", value)
        if route && Middleware.route_tracking?
          Metrician.gauge("#{WEB_METRIC}.#{kind}.#{route}", value)
        end
      end

      def increment(kind, route = nil)
        Metrician.increment("#{WEB_METRIC}.#{kind}")
        if route && Middleware.route_tracking?
          Metrician.increment("#{WEB_METRIC}.#{kind}.#{route}")
        end
      end

      def need_route?
        Middleware.request? ||
          Middleware.error? ||
          Middleware.response_size?
      end

      def apdex(request_time)
        satisfied_threshold = Middleware.configuration[:apdex][:satisfied_threshold]
        tolerated_threshold = satisfied_threshold * 4

        case
        when request_time <= satisfied_threshold
          Metrician.gauge(APDEX_SATISFIED_METRIC, request_time)
        when request_time <= tolerated_threshold
          Metrician.gauge(APDEX_TOLERATED_METRIC, request_time)
        else
          Metrician.gauge(APDEX_FRUSTRATED_METRIC, request_time)
        end
      end

      def self.extract_request_start_time(env)
        return if no_queue_start_marker?
        unless queue_start_marker
          define_queue_start_marker(env)
        end
        return if no_queue_start_marker?
        result = env[queue_start_marker].to_f
        result > 1_000_000_000 ? result : nil
      end

      def self.no_queue_start_marker?
        @no_queue_start_marker
      end

      def self.queue_start_marker
        @queue_start_marker
      end

      def self.define_queue_start_marker(env)
        @queue_start_marker = ENV_QUEUE_START_KEYS.detect do |key|
          env.keys.include?(key)
        end
        @no_queue_start_marker = @queue_start_marker.nil?
      end

      def self.extract_route(controller:, path:)
        unless controller
          return ASSET_CONTROLLER_ROUTE if path =~ ASSET_PATH_MATCHER
          return UNKNOWN_CONTROLLER_ROUTE
        end
        controller_name = Metrician.dotify(controller.class)
        action_name     = controller.action_name.blank? ? UNKNOWN_ACTION : controller.action_name
        method_name     = controller.request.request_method.to_s
        "#{controller_name}.#{action_name}.#{method_name}".downcase
      end

      def self.get_response_size(headers:, body:)
        return headers[HEADER_CONTENT_LENGTH] if headers && headers[HEADER_CONTENT_LENGTH]
        body.first.length.to_s if body.respond_to?(:length) && body.length == 1
      end

    end
  end
end
