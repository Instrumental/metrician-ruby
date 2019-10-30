#!/bin/ruby
supported_rails_versions = %w[5.1.3 5.2.0 6.0.0]

supported_gem_groups = {
  memcache_not_dalli: %w[
                    delayed_job_active_record
                    honeybadger
                    memcached
                    mysql2
                    redis
                    resque
                    sidekiq],
  dalli_not_memcache: %w[dalli
                    delayed_job_active_record
                    honeybadger
                    pg
                    redis
                    resque
                    sidekiq]
}

development_gem_names = ["instrumental_agent",
                         "rake",
                         "byebug",
                         "gemika",
                         "database_cleaner",
                         "rack-test",
                         "simplecov",
                         "rspec"
                        ]


abort "Please execute this script in the project root" unless File.exist?(".travis.yml")

supported_rails_versions.each do |rails_version|
  supported_gem_groups.each do |group_name, gem_names|
    gemfile = <<~GEMFILE
    source 'https://rubygems.org'
     
    # Runtime dependencies
    gem 'rails', '~>#{rails_version}'
     
    GEMFILE

    gemfile << "# Supported Gems\n"
    gem_names.each do |gem_name|
      gemfile << "gem '#{gem_name}'\n"
    end

    gemfile << "# Development Gems\n"
    development_gem_names.each do |gem_name|
      gemfile << "gem '#{gem_name}'\n"
    end

    gemfile << "# Gem under test\n"
    gemfile << "gem 'metrician', :path => '..'"

    # write a Gemfile
    filename = "Gemfile.rails_#{rails_version}.#{group_name}"
    file_path = "gemfiles/#{filename}"
    puts file_path # this is here for easy copy-paste from the terminal to .travis.yml

    File.open(file_path, "w") do |file|
      file.write(gemfile)
    end
  end

  # update for each version of Ruby?
end





# class GemInfo
#   def initialize(gem_name)
#     @gem_name = gem_name
#   end

#   def versions
#   end

#   def latest_version
#   end

#   # def versions_in_timeframe(start, end)
#   # end

#   def latest_in_timeframe(start, end)
#   end
  
# end

# def rubygems
#   Faraday.new(:url => 'https://rubygems.org/api/v1')
# end


