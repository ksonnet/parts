## tomcat
  #### Required params
  * namespace
  * name
  * tomcatUser
  * tomcatPassword
  * passwordSecretName

  #### Optional params
  * selector
  * storageClass
    <!-- - TODO: the library currently sets storage class as ""volume.beta.kubernetes.io/storage-class" this will be deprecated in favor of "storageClassName" in future releases -->
  * claimName: piped through from PVC metadata name (usually name)

  #### Flavors Possible
  * Persistent
  * NonPersistent
## redis
  <!--TODO: add name as a parameter in the redis library?  -->
  <!--TODO: Caught inconsistency two metricsEnabled on ln:205, 207 -->

  #### Required params
  * namespace
  * allowInbound
  * redisPassword *
  * secretName *

  #### Optional params
  * metricsEnabled
    - default: false
  * storageClassName
    - default: "_"
  * claimName
    - default: name (defaults.name)

  ### Flavors Possible
  * Persistent
  * NonPersistent
  * Persistent MetricDisabled
  * NonPersistent MetricDisabled
  * Persistent DenyExternal
  * NonPersistent DenyExternal
  * Persistent MetricDisabled DenyExternal
  * NonPersistent MetricDisabled DenyExternal



## mySQL
  #### Required params
  * namespace
  * name
  * mysqlRootPassword
  * mysqlPassword *
  * secretKeyName *

  #### Optional params
  * configurationFiles
  * labels
  * selector
  * storageClassName
  * mysqlAllowEmptyPasswords *
  * mysqlUser *
  * mysqlDatabase *
  * subPath string
  * persistenceEnabled * bool (and managed by overlay)
  * claimName *


  ### Flavors Possible
  * Persistent
  * NonPersistent
  * Persistent, Allow Empty Password
  * Non Persistent, Allow Empty Password



## mariaDB
    #### Required params
    * namespace
    * name
    * mariaRootPassword
    * mariadbPassword
    * passwordSecretName

    #### Optional params
    * metricsEnabled
    * labels
    * selector
    * storageClassName
    * mariaUserName
    * mariaDbName
    * existingClaim
    * configMapName

    ### Flavors Possible
    * Persistent
    * NonPersistent
    * Persistent, Insecure
    * Non Persistent, Insecure
    * Persistent, No Metrics, Insecure
    * NonPersistent, No Metrics, Insecure
## postgres
  #### Required params
  * namespace
  * name
  * postgresPassword *


  #### Optional params
  * metricsEnabled
    - default: true
  * externalIPArray
    - default: null
    - type: array
  * selector
    - default: {app: name}
  * storageClassName
    - default: "-"
  * podSelector
    - default: {matchLabels: {app: name}}
  * labels
    - default: {app: name}
  * existingClaim
    - default: name param
  * allowInbound
    - default: false

  * #### ** pgConfig object is not parameterized **

  ### Flavors Possible
  * Persistent Allow External
  * NonPersistent Allow External
    * Adding a set of denyExternal would be a trivial change but the overlay doesn't currently exist
# Create Prototypes

- [ ] create folders with prototype names
- [ ] create files within each folder  + cut and paste:
```
// apiVersion: 0.1
// name: io.ksonnet.pkg.nginx-server-block
// description: NGINX (pronounced "engine-x") is an open source reverse proxy server for HTTP,
// HTTPS, SMTP, POP3, and IMAP protocols, as well as a load balancer, HTTP
// cache, and a web server (origin server).
//
// Server blocks are the NGINX equivalent of Apache vhosts. (explanation)
// @param namespace string Namespace in which to put the application
// @param name string Name to give to each of the components.
// @param some-other-thing number-or-string Does something fancy or whatever


local k = import 'ksonnet.beta.2/k.libsonnet';
local nginx = import 'incubator/nginx/nginx.libsonnet';

local namespace = "import 'param://namespace'";
local appName = "import 'param://name'";

k.core.v1.list.new([
  nginx.parts.deployment.withServerBlock(namespace, appName),
  nginx.parts.service(namespace, appName),
  nginx.parts.serverBlockConfigMap(namespace, appName),
])
```

- [ ] write out parameters as comments `@param namespace string Namespace`i
- [ ] fix filename of imports
- [ ] add generated.yaml to each file  (generate in CL with `ks show -J ~/ksonnet-lib -f examples/OG_FILENAME` <- refers to original mixin .jsonnet file)
- [ ] Add new file `mixing.yaml`  with details:
```
{
  "name": "nginx",
  "version": "0.0.1",
  "description": "TODO: YOUR DESCRIPTION HERE",
  "author": "ksonnet team <ksonnet-help@heptio.com>",
  "contributors": [
    {
    "name": "Tehut Getahun",
    "email": "tehut@heptio.com"
    },
    {
    "name": "Tamiko Terada",
    "email": "tamiko@heptio.com"
    }
  ],
  "repository": {
    "type": "git",
    "url": "https://github.com/ksonnet/mixins"
  },
  "bugs": {
    "url": "https://github.com/ksonnet/mixins/issues"
  },
  "keywords": [
    "nginx",
    "server",
    "vhost",
    "server block"
  ],
  "license": "Apache 2.0"
}
``` json

FORMATTING:
	1. `import 'incubator/nginx.nginx.libsonnet`
	2. import `param://name/nginx-app`;
	3. Anything with a default would be a optional parameters.
	4. Wrap comments at 80 characters (not including the key i.e. "description"
	5.  `@param namespace`  to comment what they do
	6. Comment out a summery of what the prototype does: yes,. steal things from bitnami