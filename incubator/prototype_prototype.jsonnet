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
local nginx = import 'incubator/nginx/nginx.libsonnet';

local namespace = "import 'param://namespace'";
local appName = "import 'param://name'";

k.core.v1.list.new([
  nginx.parts.deployment.withServerBlock(namespace, appName),
  nginx.parts.service(namespace, appName),
  nginx.parts.serverBlockConfigMap(namespace, appName),
])