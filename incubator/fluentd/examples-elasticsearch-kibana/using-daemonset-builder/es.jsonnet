local k = import "ksonnet.beta.2/k.libsonnet";

local es = import "../es.libsonnet";

// Configuration. Specifies how to set up the ElasticSearch app.
local config = {
  namespace:: "elasticsearch",
  rbac:: {
    accountName:: "elasticsearch-serviceaccount",
  },
  container:: {
    tag:: "v2.4.1-2",
  },
};

// TODO: Move the rbac out here, too.
k.core.v1.list.new(
  es.app.new(config).toArray() +
  [
    {
      "kind": "Namespace",
      "apiVersion": "v1",
      "metadata": {
        "name": config.namespace,
        "labels": {
          "name": config.namespace
        }
      }
    }
  ])
