// @apiVersion 0.1
// @name io.ksonnet.pkg.stateless-maria
// @description MariaDB is an open source relational database it provides a SQL interface for
//   accessing data. This MariaDB mixin library contains Ksonnet prototypes of preconfigured
// components to help you easily deploy a MariaDB app to your Kubernetes cluster.
// @param namespace string Namespace in which to put the application
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
  maria.parts.deployment.nonPersistent(namespace, name, passwordSecretName),
  maria.parts.secret(namespace, name, mariaRootPassword),
  maria.parts.svc(namespace, name)
  ])

