if Gemika::Env.gem?('activerecord')
  require "rails/all"

  class TestRailsApp < Rails::Application
    secrets.secret_token    = "secret_token"
    secrets.secret_key_base = "secret_key_base"

    config.logger = Logger.new($stdout)
    Rails.logger = config.logger

    routes.draw do
      get "/", to: "foobars#index"
    end
  end

  class FoobarsController < ActionController::Base
    include Rails.application.routes.url_helpers

    def index
      render inline: "foobar response"
    end
  end
end
