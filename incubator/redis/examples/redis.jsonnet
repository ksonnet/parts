local k = import 'ksonnet.beta.2/k.libsonnet';
local redis = import '../redis.libsonnet';

k.core.v1.list.new([
  redis.parts.deployment.persistent("dev-alex", "redis-app",true),
  redis.parts.networkPolicy.denyExternal('dev-alex', "redis-app", true, true),
  redis.parts.pvc('dev-alex',  "redis-app", "-"),
  redis.parts.secret('dev-alex', "redis-app", 'redisPassword'),
  redis.parts.svc.metricDisabled("dev-alex", "redis-app"),
])
