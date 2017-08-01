require "yaml"

module Metrician
  class Configuration
    FileMissing = Class.new(StandardError)

    def self.load
      reset_dependents

      config = {}
      config_locations.reverse.each do |location|
        deep_merge!(config, YAML.load_file(location)) if File.exist?(location)
      end
      config
    end

    def self.config_locations
      [env_location, *app_locations, gem_location].compact
    end

    def self.env_location
      path = ENV["METRICIAN_CONFIG"]
      if path && !File.exist?(path)
        # this should never raise unless a bad ENV setting has been set
        raise(FileMissing.new(path))
      end
      path
    end

    def self.app_locations
      [
        File.join(Dir.pwd, "config", "metrician.yaml"),
        File.join(Dir.pwd, "config", "metrician.yml"),
      ]
    end

    def self.gem_location
      File.expand_path("../../../metrician.defaults.yaml", __FILE__)
    end

    def self.reset_dependents
      Metrician::Jobs.reset
      Metrician::Middleware.reset
    end

    def self.deep_merge!(this_hash, other_hash, &block)
      return this_hash unless other_hash
      other_hash.each_pair do |current_key, other_value|
        this_value = this_hash[current_key]

        this_hash[current_key] = if this_value.is_a?(Hash) && other_value.is_a?(Hash)
          this_value.deep_merge(other_value, &block)
        else
          if block_given? && this_hash.key?(current_key)
            block.call(current_key, this_value, other_value)
          else
            other_value
          end
        end
      end

      this_hash
    end
  end
end
