// @apiVersion 0.0.1
// @name io.ksonnet.pkg.nginx-simple
// @description When generated and applied, this prototype deploys a stateless nginx web
//   server. The nginx container is deployed using a Kubernetes deployment, and
//   is exposed to a network through a service.
// @param namespace string Namespace to specify destination within cluster
// @param name string Name of app to attach as identifier to all parts

local k = import 'ksonnet.beta.2/k.libsonnet';
local nginx = import 'incubator/nginx/nginx.libsonnet';

local namespace = import 'param://namespace';
local appName = import 'param://name';

k.core.v1.list.new([
  nginx.parts.deployment.simple(namespace, appName),
  nginx.parts.service(namespace, appName),
])
