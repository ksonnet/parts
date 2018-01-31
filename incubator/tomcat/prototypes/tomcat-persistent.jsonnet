// @apiVersion 0.1
// @name io.ksonnet.pkg.persistent-tomcat
// @description Deploys a stateful Tomcat server, backed by a persistent volume. Server is
//   deployed using a Kubernetes deployment, and exposed to the network using a
//   service. The password is stored as a secret.
// @shortDescription A simple Tomcat app server, backed with persistent storage.
// @param name string Name to give to each of the components
// @param tomcatUser string Username for tomcat manager page, if not specified tomcat will not assign users
// @param tomcatPassword string Tomcat manager page password, to be encrypted and included in Secret API object

local k = import 'k.libsonnet';
local tc = import 'incubator/tomcat/tomcat.libsonnet';

local namespace = import 'env://namespace';
local name = import 'param://name';
local tomcatUser = import 'param://tomcatUser';
local tomcatPassword = import 'param://tomcatPassword';
local passwordSecretName = import 'param://passwordSecretName/name';


k.core.v1.list.new([
  tc.parts.deployment.persistent(namespace, name, tomcatUser, passwordSecretName, name),
  tc.parts.pvc(namespace, name),
  tc.parts.secret(namespace, name, tomcatPassword),
  tc.parts.svc(namespace,name)
  ])
