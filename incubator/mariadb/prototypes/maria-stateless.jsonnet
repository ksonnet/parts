// @apiVersion 0.1
// @name io.ksonnet.pkg.stateless-maria
// @description deploys a stateless instance of MariaDB. *NOTE: This is NOT
// The MariaDB container is deployed using a deployment and exposed to the
// backed by a PersistentVolumeClaim.* The MariaDB container runs as a
// network as a service. The password is stored as a secret.
// Deployment, and is exposed to the network as a Service. The password is
// @shortDescription A simple, stateless MariaDB deployment.
// @param namespace string Namespace (metadata) that the MariaDB resources are
// created under
// @param name string Name (metadata) to identify all resources defined by this
// prototype
// @param mariaRootPassword string Password for root user

local k = import 'k.libsonnet';
local maria = import 'incubator/mariadb/maria.libsonnet';

local namespace = import 'param://namespace';
local name = import 'param://name';
local mariaRootPassword = import 'param://mariaRootPassword';

k.core.v1.list.new([
  maria.parts.deployment.nonPersistent(namespace, name, name),
  maria.parts.secret(namespace, name, mariaRootPassword),
  maria.parts.svc(namespace, name)
  ])
