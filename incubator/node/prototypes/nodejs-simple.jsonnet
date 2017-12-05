// @apiVersion 0.0.1
// @name io.ksonnet.pkg.nodejs-simple
// @description deploys a node.js app backed by a PersistentVolumeClaim. Its
//   source code is available at
//   https://github.com/jbianquetti-nami/simple-node-app. The app runs as a
//   Deployment, and is exposed to the network using a Service.
// @shortDescription A simple NodeJS app server with persistent storage.
// @param namespace string Namespace (metadata) that the app resources are
//   created under
// @param name string Name (metadata) to identify all resources defined by this
//   prototype


local k = import 'k.libsonnet';
local nodeJS = import 'incubator/node/nodejs.libsonnet';

local appName = import 'param://name';
local namespace = import 'param://namespace';

k.core.v1.list.new([
  nodeJS.parts.deployment.persistent(namespace, appName),
  nodeJS.parts.pvc(namespace, appName),
  nodeJS.parts.svc(namespace, appName)
])
