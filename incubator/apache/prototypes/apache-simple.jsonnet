// @apiVersion 0.0.1
// @name io.ksonnet.pkg.apache-simple
// @description runs Apache HTTP Server as a Deployment, and exposes it to
//   the network using a Service.
// @param namespace string Namespace (metadata) that the Apache resources are
//   created under; default is 'default'
// @param name string Name (metadata) to identify all resources defined by this
//   prototype

local k = import 'ksonnet.beta.2/k.libsonnet';
local apache = import 'incubator/apache/apache.libsonnet';

local namespace = import 'param://namespace';
local appName = import 'param://name';

k.core.v1.list.new([
  apache.parts.deployment(namespace, appName),
  apache.parts.svc(namespace, appName)
])
