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
