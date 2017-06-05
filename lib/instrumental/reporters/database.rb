module Instrumental

  class Database < Reporter

    def self.enabled?
      !!defined?(ActiveRecord)
    end

    def instrument
      ActiveRecord::ConnectionAdapters::AbstractAdapter.module_eval do
        include QueryInterceptor
      end
    end

  end

  module QueryInterceptor

    SQL_TYPE_EXP = /^(select|update|insert|delete|show|begin|commit|rollback|describe)/i

    def self.included(instrumented_class)
      return if instrumented_class.method_defined?(:log_without_instrumental)
      instrumented_class.class_eval do
        alias_method :log_without_instrumental, :log
        alias_method :log, :log_with_instrumental
        protected :log
      end
    end

    def log_with_instrumental(*args, &block)
      start_time = Time.now.to_f
      sql, name, _binds = args
      sql = sql.dup.force_encoding(Encoding::BINARY)
      metrics = [metric_for_name(name, sql), metric_for_sql(sql), "database.sql"].compact

      begin
        log_without_instrumental(*args, &block)
      ensure
        duration = Time.now.to_f - start_time
        metrics.each { |m| InstrumentalReporters.gauge(m, duration) }
      end
    end

    def metric_for_name(name, sql)
      if name && (parts = name.split(" ")) && parts.size == 2
        model = parts.first
        operation = parts.last.downcase
        op_name = case operation
                  when "load", "count", "exists" then "find"
                  when "indexes", "columns" then nil # fall back to DirectSQL
                  when "destroy", "find", "create" then operation
                  when "save", "update" then "update"
                  else
                    operation if model == "Join"
                  end
        return "active_record.#{InstrumentalReporters.dotify(model)}.#{op_name}" if op_name
      end

      if sql =~ /^INSERT INTO `([a-z_]+)` /
        "active_record.#{instrumentable_for_table_name(Regexp.last_match(1))}.create"
      elsif sql =~ /^UPDATE `([a-z_]+)` /
        "active_record.#{instrumentable_for_table_name(Regexp.last_match(1))}.update"
      elsif sql =~ /^DELETE FROM `([a-z_]+)` /
        "active_record.#{instrumentable_for_table_name(Regexp.last_match(1))}.destroy"
      elsif sql =~ /^SELECT .+ FROM `([a-z_]+)` /
        "active_record.#{instrumentable_for_table_name(Regexp.last_match(1))}.find"
      end
    end

    def metric_for_sql(sql)
      if sql =~ SQL_TYPE_EXP
        "database.sql.#{Regexp.last_match(1).downcase}"
      else
        "database.sql.other"
      end
    end

    def instrumentable_for_table_name(table_name)
      @table_name_to_model ||= {}
      klass_name =
        @table_name_to_model[table_name] ||=
          (ActiveRecord::Base.descendants.detect { |k| k.table_name == table_name }.try(:name) || table_name)
      InstrumentalReporters.dotify(klass_name)
    end

  end

end
