// @apiVersion 0.0.1
// @name io.ksonnet.pkg.postgres-simple
// @description deploys a postgres instance. It runs as a Deployment backed by
//   a PersistentVolumeClaim, and exposed to the network with a Service. The
//   passwords are stored in a Secret.
// @param namespace string Namespace (metadata) that the postgres resources are
//   created under
// @param name string Name (metadata) to identify all resources defined by this
//   prototype
// @param password string Password for the root user.

local k = import 'ksonnet.beta.2/k.libsonnet';
local psg = import 'incubator/postgres/postgres.libsonnet';

local appName = import 'param://name';
local namespace = import 'param://namespace';
local password = import 'param://password';

k.core.v1.list.new([
  psg.parts.deployment.persistent(namespace, appName),
  psg.parts.pvc(namespace, appName),
  psg.parts.secrets(namespace, appName, password),
  psg.parts.service(namespace, appName)
])
