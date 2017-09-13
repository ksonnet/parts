local k = import "ksonnet.beta.2/k.libsonnet";
local apache = import "../apache.libsonnet";


local namespace = "default";
local name = "apache-app";

k.core.v1.list.new(
  [
    apache.parts.deployment(namespace, name),
    apache.parts.svc(namespace, name)
  ]
)