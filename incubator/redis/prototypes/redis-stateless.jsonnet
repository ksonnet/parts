// @apiVersion 0.0.1
// @name io.ksonnet.pkg.redis-stateless
// @description deploys a stateless version of Redis. *NOTE: This is NOT backed
//   by a PersistentVolumeClaim.* It is exposed to the network with a Service.
//   The password is stored in a Secret.
// @shortDescription A simple, stateless Redis deployment,
// @param namespace string Namespace (metadata) that the Redis resources are
//   created under
// @param name string Name (metadata) to identify all resources defined by this
//   prototype
// @param redisPassword string User password to access Redis

local k = import 'ksonnet.beta.2/k.libsonnet';
local redis = import 'incubator/redis/redis.libsonnet';
local namespace = import 'param://namespace';
local name = import 'param://name';
local redisPassword = import 'param://tomcatPassword';

k.core.v1.list.new([
  redis.parts.deployment.nonPersistent(namespace, name, name),
  redis.parts.secret(namespace, name, redisPassword),
  redis.parts.svc.metricDisabled(namespace, name),
])
