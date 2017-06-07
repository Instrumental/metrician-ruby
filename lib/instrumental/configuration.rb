require "yaml"

module Instrumental
  class Configuration
    FileMissing = Class.new(StandardError)

    def self.load
      raise(FileMissing.new(location)) unless File.exist?(location)
      YAML.load_file(location)
    end

    def self.location
      ENV["METRICIAN_CONFIG"] ||
        File.join(Dir.pwd, "config", "metrician.yaml")
    end
  end
end
