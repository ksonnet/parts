// @apiVersion 0.1
// @name io.ksonnet.pkg.persistent-tomcat
// @description When generated and applied this package will create a secret,
//   a deployment, mount a persistent volume claim, & expose the deployment via a
//   service.
// @param namespace string Namespace in which to put the application
// @param name string Name to give to each of the components
// @param tomcatUser string Username for tomcat manager page, if not specified tomcat will not assign users
// @param tomcatPassword string Tomcat manager page password, to be encrypted and included in Secret Object

local k = import 'ksonnet.beta.2/k.libsonnet';
local tc = import 'incubator/tomcat/tomcat.libsonnet';

local namespace = "import 'param://namespace'";
local name = "import 'param://name'";
local tomcatUser = "import 'param://tomcatUser'";
local tomcatPassword = "import 'param://tomcatPassword'";
local passwordSecretName = "import 'param://passwordSecretName/name' ";


k.core.v1.list.new([
  tc.parts.deployment.persistent(namespace, name, tomcatUser, passwordSecretName, name),
  tc.parts.pvc(namespace, name),
  tc.parts.secret(namespace, name, tomcatPassword),
  tc.parts.svc(namespace,name)
  ])

