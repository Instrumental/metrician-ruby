# Instrumental Reporters

Automatically get metrics for [Instrumental](https://instrumentalapp.com) from your Ruby application.

## Automatic Metrics For Ruby

Automatic metrics for commonly used Ruby gems like ActiveRecord, Redis, Memcache, Dalli, Delayed Job and generic method tracing.

Activate automatically via:

```
InstrumentalReporters.activate(YOUR_API_KEY)
```

Alternatively, you can initialize your Agent manually and assign it like so:

```
agent = Instrumental::Agent.new
InstrumentalReporters.agent = agent
InstrumentalReporters.activate
```


## Rails Middleware

We can do some neat stuff automatically in a rails app using the power of rack middleware. This will get you:

* request time, broken down by controller and action
* middleware execution time
* content length
* web server queue time (for servers that set HTTP_X_QUEUE_START like nginx)

By default the middleware will be inserted into your stack automatically. If you control your middleware stack manually, you can load the functionality using the following manual instructions:

We need to load some middleware in a specific way. In your application.rb file:

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
