local k = import "ksonnet.beta.2/k.libsonnet";
local nodeJS = import "../nodejs.libsonnet";


local namespace = "default";
local name = "node-app";

k.core.v1.list.new(
  [
    nodeJS.parts.deployment.persistent(namespace, name),
    nodeJS.parts.pvc(namespace, name),
    nodeJS.parts.svc(namespace, name),
  ]
)