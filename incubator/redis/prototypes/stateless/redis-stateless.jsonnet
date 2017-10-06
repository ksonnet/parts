// apiVersion: 0.1
// name: io.ksonnet.pkg.redis-persistent
// description: Redis is an advanced key-value cache and store. Often referred to as a data
//  structure server since keys can contain structures as simple as strings,
// hashes and as complex as bitmaps and hyperloglogs. This package will deploy
// redis , a secret to hold your database password
// and a service to expose your deployment.
//
// @param namespace string Namespace in which to put the application
// @param name string Name to give to each of the components.
// @param redisPassword string Redis database page password, to be encrypted and included in Secret API object

local k = import 'ksonnet.beta.2/k.libsonnet';
local redis = import '../../redis.libsonnet';

local namespace = "import 'param://namespace'";
local name = "import 'param://name'";
local redisPassword = "import 'param://tomcatPassword'";

local secretName = "import 'param://passwordSecretName/name'";
local labels = "import 'param://labels/{app:name}'";
local selector = "import 'param://selector/{app:name}'";
local metricEnabled = "import 'param://metricEnabled/false";

k.core.v1.list.new([
  redis.parts.deployment.nonPersistent(namespace, name, secretName),
  redis.parts.secret(namespace, name, redisPassword),
  redis.parts.svc.metricDisabled(namespace, name),
])

