// @apiVersion 0.0.1
// @name io.ksonnet.pkg.nodejs-nonpersistent
// @description deploys a stateless node.js app. Its source code is available
//   at https://github.com/jbianquetti-nami/simple-node-app. The app runs as
//   a Deployment, and is exposed to the network using a Service.
// @param namespace string Namespace (metadata) that the app resources are
//   created under
// @param name string Name (metadata) to identify all resources defined by this
//   prototype

local k = import 'ksonnet.beta.2/k.libsonnet';
local nodeJS = import 'incubator/node/nodejs.libsonnet';

local namespace = import 'param://namespace';
local appName = import 'param://name';

k.core.v1.list.new([
  nodeJS.parts.deployment.nonPersistent(namespace, appName),
  nodeJS.parts.svc(namespace, appName)
])
