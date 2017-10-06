// apiVersion: 0.1
// name: io.ksonnet.pkg.non-persistent-tomcat
// description: Apache Tomcat, or Tomcat, is an open-source web server and servlet container. This
  // package deploys a stateless tomcat container, service and secret to your cluster

// Required Parameters
// @param namespace string Namespace in which to put the application
// @param name string Name to give to each of the components.
// @param tomcatUser string Username for tomcat manager page, if not specified tomcat will not assign users
// @param tomcatPassword string Tomcat manager page password, to be encrypted and included in Secret API object


local k = import 'ksonnet.beta.2/k.libsonnet';
local tc = import '../../tomcat.libsonnet';

local namespace = "import 'param://namespace'";
local name = "import 'param://name'";
local tomcatUser = "import 'param://tomcatUser'";
local tomcatPassword = "import 'param://tomcatPassword'";
local passwordSecretName = "import 'param://passwordSecretName/name' ";
    // is this the right syntax for piping the value from name into passwordSecretName?
local labels = "import 'param://labels/{app:name}'";
local selector = "import 'param://labels/{app:name}'";

k.core.v1.list.new([
  tc.parts.deployment.nonPersistent(namespace,name, tomcatUser,passwordSecretName),
  tc.parts.pvc(namespace, name),
  tc.parts.secret(namespace, name, tomcatPassword),
  tc.parts.svc(namespace,name)
  ])

