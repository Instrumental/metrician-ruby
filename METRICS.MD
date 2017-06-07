# Metrics you can expect to report in a vanilla Rails app

### `GET /users`

* `active_record.users.find`
* `database.sql`
* `database.sql.select`
* `web.request`
* `web.request.users_controller.index.get`
* `web.request.middleware`
* `web.request.idle`
* `web.response_size`
* `web.response_size.users_controller.index.get`

*You may also see another instance of `database.sql` and an instance of `database.sql.other` if the table schema is loaded.*

*In development mode, you can expect to record one each of the following **per asset** on the page because they are served by Rack*

* `web.request`
* `web.request.assets`
* `web.request.middleware`
* `web.request.idle`
* `web.response_size`
* `web.response_size.assets`


### `PATCH /redis`

Assuming we have a form for setting a redis value, and a controller that looks like this:

```ruby
class RedisController < ApplicationController
  def show
    @value = $redis.get("foo")
  end

  def update
    $redis.set("foo", params[:value])
    redirect_to(redis_path)
  end
end
```

In addition to request metrics similar to those described above, we can expect the following redis-specific metrics to be recorded:

* `redis.set` - during the update
* `redis.get` - during the redirect/show

