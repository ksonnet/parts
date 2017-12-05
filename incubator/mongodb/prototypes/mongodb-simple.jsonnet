// @apiVersion 0.0.1
// @name io.ksonnet.pkg.mongodb-simple
// @description deploys a simple instance of MongoDB. It runs as a Deployment
//   backed by a PersistentVolumeClaim, and is exposed to the network using a
//   Service. Passwords are stored in a Secret.
// @shortDescription A simple MongoDB deployment, backed by persistent storage.
// @param namespace string Namespace (metadata) that the MongoDB resources
//  are created under
// @param name string Name (metadata) to identify all resources defined by this
//  prototype
// @param rootPassword string Password for the root user
// @param password string Password for new user

local k = import 'k.libsonnet';
local mongo = import 'incubator/mongodb/mongodb.libsonnet';

local namespace = import 'param://namespace/';
local appName = import 'param://name';
local rootPassword = import 'param://rootPassword';
local password = import 'param://password';

k.core.v1.list.new([
  mongo.parts.deployment.persistent(namespace, appName),
  mongo.parts.pvc(namespace, appName),
  mongo.parts.secrets(namespace, appName, rootPassword, password),
  mongo.parts.service(namespace, appName)
])
