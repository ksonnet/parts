// @apiVersion 0.1
// @name io.ksonnet.pkg.elasticsearch-kibana
// @description Elasticsearch and kibana stack for logging. Elasticsearch
//   indexes the logs, and kibana provides a queryable, interactive UI.

local k = import 'k.libsonnet';
local efk = import 'incubator/efk/efk.libsonnet';

k.core.v1.list.new([
  efk.parts.kibana.deployment,
  efk.parts.kibana.svc,
  efk.parts.elasticsearch.serviceAccount,
  efk.parts.elasticsearch.clusterRole,
  efk.parts.elasticsearch.clusterRoleBinding,
  efk.parts.elasticsearch.statefulSet,
  efk.parts.elasticsearch.svc,
])
