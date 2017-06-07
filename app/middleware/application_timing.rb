module Instrumental
  # RequestTiming and ApplicationTiming work in concert to time the middleware
  # separate from the request processing. RequestTiming should be the first
  # or near first middleware loaded since it will be timing from the moment
  # the the app server is hit and setting up the env for tracking the
  # middleware execution time. RequestTiming should be the last or near
  # last middleware loaded as it times the application execution (separate from
  # middleware).
  class ApplicationTiming

    def initialize(app)
      @app = app
    end

    def call(env)
      start_time = Time.now.to_f
      @app.call(env)
    ensure
      env["REQUEST_TOTAL_TIME"] = (Time.now.to_f - start_time)
    end

  end
end
