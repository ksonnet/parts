// @apiVersion 0.0.1
// @name io.ksonnet.pkg.stateless-tomcat
// @description Deploys a stateless Tomcat server. Server is deployed using a Kubernetes
//   deployment, and exposed to the network using a service. The password is stored as a secret.
// @param namespace string Namespace in which to put the application
// @param name string Name to give to each of the components.
// @param tomcatUser string Username for tomcat manager page, if not specified tomcat will not assign users
// @param tomcatPassword string Tomcat manager page password, to be encrypted and included in Secret Object

local k = import 'ksonnet.beta.2/k.libsonnet';
local tc = import 'incubator/tomcat/tomcat.libsonnet';

local namespace = "import 'param://namespace'";
local name = "import 'param://name'";
local tomcatUser = "import 'param://tomcatUser'";
local tomcatPassword = "import 'param://tomcatPassword'";

k.core.v1.list.new([
  tc.parts.deployment.nonPersistent(namespace, name, tomcatUser, name),
  tc.parts.secret(namespace, name, tomcatPassword),
  tc.parts.svc(namespace,name)
])
