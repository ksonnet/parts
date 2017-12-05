// @apiVersion 0.0.1
// @name io.ksonnet.pkg.apache-simple
// @description runs Apache HTTP Server as a Deployment, and exposes it to
// the network using a Service.
// @shortDescription A simple, stateless Apache HTTP server.
// @param namespace string Namespace (metadata) that the Apache resources are
// created under; default is 'default'
// @param name string Name (metadata) to identify all resources defined by this
// prototype

local k = import 'k.libsonnet';
local apache = import 'incubator/apache/apache.libsonnet';

local namespace = import 'param://namespace';
local appName = import 'param://name';

k.core.v1.list.new([
  apache.parts.deployment(namespace, appName),
  apache.parts.svc(namespace, appName)
])
