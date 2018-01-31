local env = std.extVar("__ksonnet/environments");
local params = std.extVar("__ksonnet/params").components.memcached;
local k = import 'k.libsonnet';
local memcached = import '../memcached.libsonnet';

local myNamespace = env.namespace;
local appName = params.name;

k.core.v1.list.new([
  memcached.parts.pbd(myNamespace, appName),
  memcached.parts.statefulset.withHardAntiAffinity(myNamespace, appName),
  memcached.parts.service(myNamespace, appName)
])
