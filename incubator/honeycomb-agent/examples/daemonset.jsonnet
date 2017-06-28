local k = import "ksonnet.beta.2/k.libsonnet";

local honeycomb = import "../honeycomb-agent.libsonnet";

local conf = {
  namespace:: "kube-system",
  rbac:: {
    accountName:: "honeycomb-serviceaccount",
  },
  volume:: {
    varlogName:: "varlog",
    podlogsName:: "varlibdockercontainers",
  },
  configMap:: {
    data:: |||
      apiHost: https://api.honeycomb.io
      watchers:
        - dataset: kubernetestest
          parser: json
          namespace: "default"
          labelSelector: "app=nginx"
        - dataset: mysql
          labelSelector: "app=mysql"
          parser: mysql
      verbosity: debug
|||,
  },
  secret:: {
    key:: "foo" //error "No key specified",
  },
};

// Create a basic Honeycomb agent DaemonSet. This gets deployed on
// every node in the cluster.
local daemonSet =
  honeycomb.app.daemonSetBuilder.new("honeycomb-agent-v1.1", conf) + {
    // Customizations. Add pod logs to the Honeycomb agent DaemonSet,
    // so that it can tail `stdout` of selected pods.
    daemonSet+:: honeycomb.mixin.daemonSet.addHostMountedPodLogs(
      conf.volume.varlogName, conf.volume.podlogsName),
  };

k.core.v1.list.new(daemonSet.toArray())
