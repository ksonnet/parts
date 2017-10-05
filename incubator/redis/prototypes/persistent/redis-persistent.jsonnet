local k = import 'ksonnet.beta.2/k.libsonnet';
local redis = import '../../redis.libsonnet';

local namespace = "import 'param://namespace'";
local name = "import 'param://name'";
local tomcatUser = "import 'param://tomcatUser'";
local tomcatPassword = "import 'param://tomcatPassword'";
local passwordSecretName = "import 'param://passwordSecretName/name' ";
    // is this the right syntax for piping the value from name into passwordSecretName?

local storageClass = "import 'param://storageClass/null";
local claimName = "import 'param://storageClass/name";
local labels = "import 'param://labels/{app:name}'";
local selector = "import 'param://labels/{app:name}'";

k.core.v1.list.new([
  redis.parts.deployment.persistent("dev-alex", "redis-app",true),
  redis.parts.networkPolicy.denyExternal('dev-alex', true, true),
  redis.parts.pvc('dev-alex', "redis-app"),
  redis.parts.secret('dev-alex', 'Zm9vYmFy'),
  redis.parts.svc.metricDisabled("dev-alex", "redis-app"),
])

