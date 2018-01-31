local env = std.extVar("__ksonnet/environments");
local params = std.extVar("__ksonnet/params").components.nginx;
local k = import 'k.libsonnet';
local nginx = import '../nginx.libsonnet';

local namespace = env.namespace;
local appName = params.name;

k.core.v1.list.new([
  nginx.parts.deployment.withServerBlock(namespace, appName),
  nginx.parts.service(namespace, appName),
  nginx.parts.serverBlockConfigMap(namespace, appName),
])
