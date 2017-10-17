// @apiVersion 0.0.1
// @name io.ksonnet.pkg.memcached-simple
// @description deploys Memcached on your cluster. It runs as a StatefulSet,
//   using 3 replicas and a pod distribution budget (PDB). Memcached
//   is exposed as a Service, and can be accessed via port 11211 within the
//   cluster.
// @param namespace string Namespace (metadata) that the Memcached resources
//   are created under
// @param name string Name (metadata) to identify all resources defined by this
//   prototype

// TODO: Add MaxItemMemory=64 as a param like the k8s/charts?

local k = import 'ksonnet.beta.2/k.libsonnet';
local memcached = import 'incubator/memcached/memcached.libsonnet';

local namespace = import 'param://namespace';
local appName = import 'param://name';

k.core.v1.list.new([
  memcached.parts.pdb(namespace, appName),
  memcached.parts.statefulset.withHardAntiAffinity(namespace, appName),
  memcached.parts.service(namespace, appName)
])
