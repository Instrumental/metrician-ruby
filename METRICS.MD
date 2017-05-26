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

*In development mode, you can expect to record one each of the following per
 asset on the page because they are served by Rack*

* `web.request`
* `web.request.assets`
* `web.request.middleware`
* `web.request.idle`
* `web.response_size`
* `web.response_size.assets`
