local env = std.extVar("__ksonnet/environments");
local params = std.extVar("__ksonnet/params").components.mongodb;
local k = import 'k.libsonnet';
local mongo = import '../mongodb.libsonnet';

local namespace = env.namespace;
local appName = params.name;
local rootPassword = params.rootPassword;
local password = params.password;

k.core.v1.list.new([
  mongo.parts.deployment.persistent(namespace, appName),
  mongo.parts.pvc(namespace, appName),
  mongo.parts.secrets(namespace, appName, rootPassword, password),
  mongo.parts.service(namespace, appName),
])
