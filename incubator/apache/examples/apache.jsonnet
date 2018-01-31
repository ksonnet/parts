local env = std.extVar("__ksonnet/environments");
local params = std.extVar("__ksonnet/params").components.apache;
local k = import "k.libsonnet";
local apache = import "../apache.libsonnet";

local namespace = env.namespace;
local name = params.name;

k.core.v1.list.new(
  [
    apache.parts.deployment(namespace, name),
    apache.parts.svc(namespace, name)
  ]
)
