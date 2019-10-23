### 0.2.0 [October 23, 2019]
* Sidekiq jobs now submit error data for all exceptions, including Exception, and not just those descending from StandardError

### 0.1.0 [September 5, 2017]
* **BREAKING** Rename Method Tracing -> Method Timing to reflect reality better. Metrics go from `tracer.<stuff>` to `timer.<stuff>`.

### 0.0.11 [August 18, 2017]
* Remove dependence on ActiveSupport

### 0.0.10 [August 17, 2017]
* Fix issue with cache lib detection

### 0.0.9 [August 16, 2017]
* Rename some metrics and add common prefix

### 0.0.8 [August 4, 2017]
* Integrate with memcached and dalli if both are available

### 0.0.7 [August 3, 2017]
* Allow partial config files
* Officially require Ruby 2
* Add separate DB command and table configs
* Don't add method tracing function by default
* Add example config file

### 0.0.6 [July 25, 2017]
* Fix edge case in web error tracking

### 0.0.5 [July 25, 2017]
* Automate Resque integration

### 0.0.4 [July 24, 2017]
* Handle exceptions in other middlewares for response size tracking

### 0.0.3 [July 20, 2017]
* Publish to Rubygems
