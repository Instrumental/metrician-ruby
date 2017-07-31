require "yaml"

module Metrician
  class Configuration
    FileMissing = Class.new(StandardError)

    def self.load
      reset_dependents

      config = {}
      [
        env_location,
        app_location,
        gem_location,
      ].compact.each do |location|
        config = merge(config, YAML.load_file(location)) if File.exist?(location)
      end
      config
    end

    def self.merge(a_config, b_config)
      return {} unless b_config
      new_config = {}
      (a_config.keys + b_config.keys).each do |key|
        new_config[key] =
          if a_config[key].kind_of?(Hash)
            merge(a_config[key], b_config[key])
          else
            a_config[key] || b_config[key]
          end
      end
      new_config
    end

    def self.env_location
      path = ENV["METRICIAN_CONFIG"]
      if path && !File.exist?(path)
        # this should never raise unless a bad ENV setting has been set
        raise(FileMissing.new(path))
      end
      path
    end

    def self.app_location
      File.join(Dir.pwd, "config", "metrician.yaml")
    end

    def self.gem_location
      File.expand_path("../../../metrician.defaults.yaml", __FILE__)
    end

    def self.reset_dependents
      Metrician::Jobs.reset
      Metrician::Middleware.reset
    end
  end
end
