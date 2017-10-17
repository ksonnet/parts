// @apiVersion 0.1
// @name io.ksonnet.pkg.redis-persistent
// @description deploys a version of Redis that is backed by a
//   PersistentVolumeClaim. It runs as a Deployment, and is exposed to the
//   network with a Service. The password is stored in a Secret.
// @param namespace string Namespace (metadata) that the Redis resources are
//   created under
// @param name string Name (metadata) to identify all resources defined by this
//   prototype
// @param redisPassword string User password to access Redis

local k = import 'ksonnet.beta.2/k.libsonnet';
local redis = import 'incubator/redis/redis.libsonnet';

local namespace = import 'param://namespace';
local name = import 'param://name';
local redisPassword = import 'param://redisPassword';

k.core.v1.list.new([
  redis.parts.deployment.persistent(namespace, name, name),
  redis.parts.pvc(namespace, name),
  redis.parts.secret(namespace, name, redisPassword),
  redis.parts.svc.metricDisabled(namespace, name),
])
