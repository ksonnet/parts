local k = import "ksonnet.beta.2/k.libsonnet";

local fluentd = import "incubator/fluentd/fluentd.libsonnet";

// Destructuring imports for base.
local container = k.core.v1.replicationController.mixin.spec.template.spec.containersType;
local ds = k.extensions.v1beta1.daemonSet;
local volume = k.core.v1.replicationController.mixin.spec.template.spec.volumesType;
local volumeMount = container.volumeMountsType;

local config = {
  namespace:: "elasticsearch",
  container:: {
    name:: "fluentd-es",
    tag:: "1.22",
  },
  daemonSet:: {
    name:: "fluentd-es-v1.22",
  },
  rbac:: {
    accountName:: "fluentd-serviceaccount"
  },
};

local ds =
  fluentd.app.daemonSetBuilder.new(config) +
  fluentd.app.daemonSetBuilder.configureForPodLogs(config);

local rbacObjs = fluentd.app.admin.rbacForPodLogs(config);

k.core.v1.list.new(
  ds.toArray() +
  rbacObjs.toArray()
)
