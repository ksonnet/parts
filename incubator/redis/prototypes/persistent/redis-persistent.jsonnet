// apiVersion: 0.1
// name: io.ksonnet.pkg.nginx-server-block
// description: NGINX (pronounced "engine-x") is an open source reverse proxy server for HTTP,
// HTTPS, SMTP, POP3, and IMAP protocols, as well as a load balancer, HTTP
// cache, and a web server (origin server).
//
// Server blocks are the NGINX equivalent of Apache vhosts. (explanation)
// @param namespace string Namespace in which to put the application
// @param name string Name to give to each of the components.
// @param some-other-thing number-or-string Does something fancy or whatever

local k = import 'ksonnet.beta.2/k.libsonnet';
local redis = import '../../redis.libsonnet';

local namespace = "import 'param://namespace'";
local name = "import 'param://name'";
local redisPassword = "import 'param://tomcatPassword'";
local secretName = "import 'param://passwordSecretName/name'";


local storageClass = "import 'param://storageClass/null";
local claimName = "import 'param://storageClass/name";
local labels = "import 'param://labels/{app:name}'";
local selector = "import 'param://labels/{app:name}'";
local metricEnabled = "import 'param://metricEnabled/false";

k.core.v1.list.new([
  redis.parts.deployment.persistent(namespace, name, secretName),
  redis.parts.pvc(namespace, name),
  redis.parts.secret(namespace, name, redisPassword),
  redis.parts.svc.metricDisabled(namespace, name),
])

