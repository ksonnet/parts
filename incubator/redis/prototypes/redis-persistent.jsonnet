// @apiVersion 0.1
// @name io.ksonnet.pkg.redis-persistent
// @description Redis backed by a persistent volume claim. Redis is deployed using a Kubernetes
//   deployment, exposed to the network with a service, with a password stored
//   in a secret.
// @param namespace string Namespace in which to put the application
// @param name string Name to give to each of the components
// @param redisPassword string User password to supply to redis

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
