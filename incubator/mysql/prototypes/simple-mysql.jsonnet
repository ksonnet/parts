// @apiVersion 0.1
// @name io.ksonnet.pkg.simple-mysql
// @description deploys a MySQL instance. It runs as a Deployment backed by a
//   PersistentVolumeClaim, and is exposed to the network with a Service. The
//   passwords are stored in a Secret.
// @shortDescription A simple MySQL deployment, backed by persistent storage.
// @param namespace string Namespace (metadata) that the MySQL resources are
//  created under
// @param name string Name (metadata) to identify all resources defined by this
//  prototype
// @param mySqlaRootPassword string Password for the root user
// @param mysqlPassword string Password for new use

local k = import 'k.libsonnet';
local mysql = import '../mysql.libsonnet';

local namespace = import 'param://namespace';
local name = import 'param://name';
local mysqlRootPassword = import 'param://mysqlRootPassword';
local mysqlPassword = import 'param://mysqlPassword';

k.core.v1.list.new([
  mysql.parts.configMap(namespace, name),
  mysql.parts.deployment.persistent(namespace, name, name, name),
  mysql.parts.pvc(namespace, name),
  mysql.parts.secret(namespace, name, mysqlPassword, mysqlRootPassword),
  mysql.parts.svc(namespace, name)
])
