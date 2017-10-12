// @apiVersion 0.1
// @name io.ksonnet.pkg.persistent-maria
// @description MariaDB is an open source relational database it provides a SQL interface for
//   accessing data. The latest versions of MariaDB also include GIS and JSON
//   features. This package deploys a maria container backed by a mounted
//   persistent volume claim, a secret, and service to expose your deployment.
// @param namespace string Namespace to specify destination within cluster, defaults to 'default'
// @param name string Metadata name for each of the deployment components
// @param mariaRootPassword string Password for root user

local k = import 'ksonnet.beta.2/k.libsonnet';
local maria = import '../../maria.libsonnet';

local namespace = "import 'param://namespace'";
local name = "import 'param://name'";
local mariaRootPassword = "import 'param://mariaRootPassword'";
local passwordSecretName = "import 'param://passwordSecretName/name' ";

local labels = "import 'param://labels/{app:name}'";
local selector = "import 'param://labels/{app:name}'";

k.core.v1.list.new([
  maria.parts.deployment.persistent(namespace, name, passwordSecretName),
  maria.parts.pvc(namespace, name),
  maria.parts.secret(namespace, name, mariaRootPassword),
  maria.parts.svc(namespace, name)
  ])

