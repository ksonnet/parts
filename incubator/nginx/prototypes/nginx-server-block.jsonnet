// @apiVersion 0.0.1
// @name io.ksonnet.pkg.nginx-server-block
// @description deploys a simple, stateless nginx server *with server blocks*
//   (roughly equivalent to nginx virtual hosts). The nginx server runs as a
//   Deployment, and is exposed to the network with a Service.
// @param namespace string Namespace (metadata) that the nginx resources are
//   created under
// @param name string Name (metadata) to identify all resources defined by this
//   prototype

// TODO: How should the ServerBlockConf be exposed to the user? Not quite sure what the default does except for setting web server to port 80.

local k = import 'ksonnet.beta.2/k.libsonnet';
local nginx = import 'incubator/nginx/nginx.libsonnet';

local namespace = import 'param://namespace';
local appName = import 'param://name';

k.core.v1.list.new([
  nginx.parts.deployment.withServerBlock(namespace, appName),
  nginx.parts.service(namespace, appName),
  nginx.parts.serverBlockConfigMap(namespace, appName),
])
