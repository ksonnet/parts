// -------------------------------------------------------------------
// A Honeycomb agent DaemonSet example using the
// `honeycomb-agent.libsonnet` library.
//
// This example:
//
// 1. Creates a basic Honeycomb agent DaemonSet, so that the agent
//    gets deployed on each node.
// 2. Specifies which logs to consume with `conf.configMap.data`.
//    Every agent will parse this data and consume all logging data
//    in the streams specified.
// -------------------------------------------------------------------

// NOTE: For these imports you must invoke the Jsonnet CLI with -J
// flags pointing at (1) the ksonnet library root, and (2) the root
// of the mixins repository.
local k = import "ksonnet.beta.2/k.libsonnet";
local honeycomb = import "incubator/honeycomb-agent/honeycomb-agent.libsonnet";

// Configuration. Specifies how to set up the DaemonSet and Honeycomb
// agent.
local conf = {
  namespace:: "kube-system",
  agent:: {
    containerTag:: "head",
    containerName:: "honeycomb-agent",
  },
  rbac:: {
    accountName:: "honeycomb-serviceaccount",
  },
  configMap:: {
    data:: |||
      apiHost: https://api.honeycomb.io
      watchers:
        - dataset: kubernetestest
          parser: nginx
          namespace: "default"
          labelSelector: "app=nginx"
      verbosity: debug
|||,
  },
  secret:: {
    key:: error "A Honeycomb write key is required in `conf.secret.key`",
  },
};

// Generate a `DaemonSet` builder, configure to have access to the
// `stdout` of Pods.
local daemonSet =
  local daemonSetName = "honeycomb-agent-v1.1";
  honeycomb.app.daemonSetBuilder.new(daemonSetName, conf) +
  honeycomb.app.daemonSetBuilder.configureForPodLogs(conf);

// Emit all top-level objects (e.g., RBAC configurations, configMaps,
// etc.) in a `v1.List`.
k.core.v1.list.new(daemonSet.toArray())
