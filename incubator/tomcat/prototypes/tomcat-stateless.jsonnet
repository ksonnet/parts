// @apiVersion 0.0.1
// @name io.ksonnet.pkg.non-persistent-tomcat
// @description eploys a stateless Tomcat server. *NOTE: It is NOT backed by a
//   PersistentVolumeClaim*. It runs as a Deployment, and is exposed to the
//   network with a Service. The password is stored in a Secret.
// @shortDescription A simple, stateless Tomcat app server.
// @param namespace string Namespace (metadata) that the Tomcat resources are
//   created under
// @param name string Name (metadata) to identify all resources defined by this
//   prototype
// @param tomcatUser string Username for the Tomcat manager page. If not
//   specified, Tomcat will not assign users.
// @param tomcatPassword string Password for the Tomcat manager page.

local k = import 'k.libsonnet';
local tc = import 'incubator/tomcat/tomcat.libsonnet';

local namespace = import 'param://namespace';
local name = import 'param://name';
local tomcatUser = import 'param://tomcatUser';
local tomcatPassword = import 'param://tomcatPassword';

k.core.v1.list.new([
  tc.parts.deployment.nonPersistent(namespace, name, tomcatUser, name),
  tc.parts.secret(namespace, name, tomcatPassword),
  tc.parts.svc(namespace,name)
])
