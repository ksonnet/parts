// @apiVersion 0.0.1
// @name io.ksonnet.pkg.nginx-server-block
// @description When generated and applied, this prototype deploys stateless nginx server with server blocks (roughly equivalent
//   to Apache virtual hosts). The nginx container is deployed using a
//   Kubernetes deployment, and is exposed to a network with a service. The configMap is used to specify the files served.
// @param namespace string Namespace to specify destination within cluster
// @param name string Name of app to attach as identifier to all parts
// @param sbConfig string Server block configuration data to store

local k = import 'ksonnet.beta.2/k.libsonnet';
local nginx = import 'incubator/nginx/nginx.libsonnet';

local namespace = import 'param://namespace';
local appName = import 'param://name';
local serverBlockConfig = import 'param://serverblockconfig'

k.core.v1.list.new([
  nginx.parts.deployment.withServerBlock(namespace, appName),
  nginx.parts.service(namespace, appName),
  nginx.parts.serverBlockConfigMap(namespace, appName, serverBlockConfig),
])
