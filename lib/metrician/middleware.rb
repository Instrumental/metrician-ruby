module Metrician
  module Middleware
    ENV_REQUEST_TOTAL_TIME   = "METRICIAN_REQUEST_TOTAL_TIME".freeze
    ENV_QUEUE_START_KEYS     = ["X-Request-Start".freeze,
                                "X-Queue-Start".freeze,
                                "X-REQUEST-START".freeze,
                                "X_REQUEST_START".freeze,
                                "HTTP_X_QUEUE_START".freeze]
    ENV_CONTROLLER_PATH      = "action_controller.instance".freeze
    ENV_REQUEST_PATH         = "REQUEST_PATH".freeze
    HEADER_CONTENT_LENGTH    = "Content-Length".freeze
    ASSET_CONTROLLER_ROUTE   = "assets".freeze
    UNKNOWN_CONTROLLER_ROUTE = "unknown_endpoint".freeze
    UNKNOWN_ACTION           = "unknown_action".freeze
    ASSET_PATH_MATCHER       = %r|\A/{0,2}/assets|.freeze
    APDEX_SATISFIED_METRIC   = "web.apdex.satisfied".freeze
    APDEX_TOLERATED_METRIC   = "web.apdex.tolerated".freeze
    APDEX_FRUSTRATED_METRIC  = "web.apdex.frustrated".freeze

    def self.configuration
      @configuration ||= Metrician.configuration[:request_timing]
    end

    def self.enabled?
      @enabled ||= configuration[:enabled]
    end

    def self.request_timing_required?
      request? || apdex?
    end

    def self.request?
      @request ||= configuration[:request][:enabled]
    end

    def self.error?
      @request ||= configuration[:error][:enabled]
    end

    def self.idle?
      @idle ||= configuration[:idle][:enabled]
    end

    def self.response_size?
      @response_size ||= configuration[:response_size][:enabled]
    end

    def self.middleware?
      @middleware ||= configuration[:middleware][:enabled]
    end

    def self.queue_time?
      @queue_time ||= configuration[:queue_time][:enabled]
    end

    def self.route_tracking?
      @route_tracking ||= configuration[:route_tracking][:enabled]
    end

    def self.apdex?
      @apdex ||= configuration[:apdex][:enabled]
    end
  end
end
