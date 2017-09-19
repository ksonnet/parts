local k = import 'ksonnet.beta.2/k.libsonnet';
local redis = import '../redis.libsonnet';

k.core.v1.list.new([
  redis.parts.deployment.persistent("dev-alex", "redis-app",true),
  redis.parts.networkPolicy.allowExternal('dev-alex', true, true),
  redis.parts.pvc.pvcBase('dev-alex', "-"),
  redis.parts.secret('dev-alex', 'Zm9vYmFy'),
  redis.parts.svc.metricEnabled("dev-alex"),
])
