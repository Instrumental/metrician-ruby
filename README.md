# Metrician

Automatically get metrics for [Instrumental](https://instrumentalapp.com) from your Ruby on Rails (RoR) application.

[![Build Status](https://travis-ci.org/Instrumental/metrician-ruby.svg?branch=master)](https://travis-ci.org/Instrumental/metrician-ruby)

## Automatic Metrics For Ruby

Automatic metrics for commonly used Ruby gems:

* ActiveRecord
* Redis
* Memcached
* Dalli
* Delayed Job
* Sidekiq
* Resque
* Honeybadger

Request Metrics:

* apdex metrics
* request time, broken down by controller and action
* middleware execution time
* idle time
* content length
* web server queue time (for servers that set HTTP_X_QUEUE_START like nginx)

And also you can report generic method timing.

## Installation

```
gem install metrician instrumental_agent
```

Grab your project token from [https://instrumentalapp.com/docs/tokens](https://instrumentalapp.com/docs/tokens) and activate metrician with:

```
I = Instrumental::Agent.new(PROJECT_TOKEN)
Metrician.activate(I)
```

## Configuration

### Rack Middleware

In rails, the middleware will be inserted into your middleware stack automatically. If you control your middleware stack manually in rails, you can load the functionality using the following manual instructions:

In your application.rb file:

```ruby
# request timing should be first so we get the correct queue time and start the
# middleware timer
config.middleware.insert_before("ActionDispatch::Static", "RequestTiming")

# if you want to track content length add the rack middleware
config.middleware.insert_before("ActionDispatch::Static", "Rack::ContentLength")

# application timing should be last/just before the request is processed
config.middleware.use("ApplicationTiming")
```

If you run `rake middleware`, you should see something like:

```shell
use RequestTiming
use Rack::ContentLength
use ActionDispatch::Static
# etc.
use ActionDispatch::BestStandardsSupport
use ApplicationTiming
run YOUR_APP::Application.routes
```

Your exception tracking middleware may try to get in first (hey, Honeybadger), so you will have to change the load order in an initializer, because we want to track that as middleware time, too.


## Release Process

1. Pull latest master
1. Merge feature branch(es) into master
1. Verify all ruby/rails/gem testing versions are up-to-date
3. `script/test`
4. Increment version in:
  - `lib/metrician/version.rb`
5. Run `rake matrix:install` to generate new gem lockfiles
6. Update [CHANGELOG.md](CHANGELOG.md)
7. Commit "Release vX.Y.Z"
8. Push to GitHub
9. Release packages: `rake release`
10. Verify package release at https://rubygems.org/gems/metrician

## Verify/Add/Update gems
If you're adding support for a new gem or there's a new version of an already supported gem, these steps are for you.

1. add new ruby versions to .travis.yml
1. remove unsupported ruby versions from .travis.yml
1. add new rails versions to script/generate
1. remove unsupported versions of rails from script/generate
1. remove gemfiles for those versions of rails from gemfiles directory
1. remove bundler 1.x references from script/setup and .travis.yml if no longer required
1. review tests for removed gem versions and check for vestigial code (i.e. disabled vs. report_data for honeybadger)
1. add new gem(s) to each gem group in script/generate
1. run script/generate
1. run script/setup
1. run script/test


## Version Policy

This library follows [Semantic Versioning 2.0.0](http://semver.org).
