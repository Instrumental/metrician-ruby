require "yaml"

module Instrumental
  class Configuration
    FileMissing = Class.new(StandardError)

    def self.load
      if env_location
        # this should never raise unless a bad ENV setting has been set
        raise(FileMissing.new(env_location)) unless File.exist?(env_location)
        return YAML.load(env_location)
      end

      if File.exist?(app_location)
        return YAML.load_file(app_location)
      end

      YAML.load_file(gem_location)
    end

    def self.env_location
      ENV["METRICIAN_CONFIG"]
    end

    def self.app_location
      File.join(Dir.pwd, "config", "metrician.yaml")
    end

    def self.gem_location
      File.expand_path("../../../config/metrician.yaml", __FILE__)
    end
  end
end
