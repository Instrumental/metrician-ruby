module Metrician

  class ActiveRecord < Reporter

    def self.enabled?
      !!defined?(::ActiveRecord) &&
        Metrician.configuration[:database][:enabled]
    end

    def instrument
      ::ActiveRecord::ConnectionAdapters::AbstractAdapter.module_eval do
        include QueryInterceptor
      end
    end

  end

  module QueryInterceptor

    COMMAND_EXP  = /^(select|update|insert|delete|show|begin|commit|rollback|describe)/i
    SQL_EXP      = /#{COMMAND_EXP} (?:into |from |.+? from )?(?:[`"]([a-z_]+)[`"])?/i
    OTHER        = "other".freeze
    QUERY_METRIC = "database.query"

    def self.included(instrumented_class)
      # You might wonder why this exception-based flow control is here instead of
      # something more sane like
      # instrumented_class.method_defined?(:log_without_metrician)
      # The answer is that method_defined?, methods, instance_methods
      # and other reasonable ways of answering this question do not
      # work correctly in this circumstance.  They return false even
      # when log_without_metrician is defined on the class.  The
      # result is that the guard statement fails and runs this code
      # twice.  That makes log_without_metrician an alias of
      # log_with_metrician and causes infinite recursion :(
      already_defined = true
      begin
        already_defined = instrumented_class.new(nil).method(:log_without_metrician)
      rescue
        already_defined = false
      end

      return if already_defined
      instrumented_class.class_eval do
        alias_method :log_without_metrician, :log
        alias_method :log, :log_with_metrician
        protected :log
      end
    end

    def log_with_metrician(*args, &block)
      start_time = Time.now.to_f
      sql, name, _binds = args
      sql = sql.dup.force_encoding(Encoding::BINARY)
      config = Metrician.configuration[:database]
      metrics = []
      metrics << QUERY_METRIC if config[:query][:enabled]
      if [:command, :table, :command_and_table].any?{ |key| config[key][:enabled] }
        command, table = parse_sql(sql)
        metrics << "database.#{command}" if config[:command][:enabled] && command
        metrics << "database.#{table}" if config[:table][:enabled] && table
        metrics << "database.#{command}.#{table}" if config[:command_and_table][:enabled] && command && table
      end
      begin
        log_without_metrician(*args, &block)
      ensure
        duration = Time.now.to_f - start_time
        metrics.each { |m| Metrician.gauge(m, duration) }
      end
    end

    def parse_sql(sql)
      match = sql.match(SQL_EXP)
      command = (match && match[1].downcase) || OTHER
      table = (match && match[2] && match[2].downcase)
      [command, table]
    end

  end

end
