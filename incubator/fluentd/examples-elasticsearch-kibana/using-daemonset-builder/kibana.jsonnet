local k = import "ksonnet.beta.2/k.libsonnet";

// Destructuring imports for base.
local container = k.extensions.v1beta1.deployment.mixin.spec.template.spec.containersType;
local containerPort = container.portsType;
local deployment = k.extensions.v1beta1.deployment;
local env = container.envType;
local service = k.core.v1.service;
local servicePort = service.mixin.spec.portsType;

local podLabels = {
  "k8s-app": "kibana-logging"
};

local kibanaContainer =
  local ports =
    containerPort.newNamed("ui", 5601) +
    containerPort.protocol("TCP");
  container.new("kibana-logging", "gcr.io/google_containers/kibana:v4.6.1-1") +
  container.env([
    env.new("ELASTICSEARCH_URL", "http://elasticsearch-logging:9200"),
    env.new("KIBANA_BASE_URL", "/api/v1/proxy/namespaces/kube-system/services/kibana-logging")
  ]) +
  container.ports(ports) {
    "resources": {
      "limits": {
        "cpu": "100m"
      },
      "requests": {
        "cpu": "100m"
      }
    }
  };

local kibanaDeployment =
  deployment.new("kibana-logging", 1, kibanaContainer, podLabels) +
  deployment.mixin.metadata.namespace("kube-system") +
  deployment.mixin.metadata.labels({
    "addonmanager.kubernetes.io/mode": "Reconcile",
    "k8s-app": "kibana-logging",
    "kubernetes.io/cluster-service": "true"
  }) +
  deployment.mixin.spec.selector.matchLabels(podLabels);

local serviceLabels = {
  "addonmanager.kubernetes.io/mode": "Reconcile",
  "k8s-app": "kibana-logging",
  "kubernetes.io/cluster-service": "true",
  "kubernetes.io/name": "Kibana"
};

local selector = {
  "k8s-app": "kibana-logging"
};

local port =
  servicePort.new(5601, "ui") +
  servicePort.protocol("TCP");

local kibanaService =
  service.new("kibana-logging", selector, port) +
  service.mixin.metadata.namespace("kube-system") +
  service.mixin.metadata.labels(serviceLabels);

k.core.v1.list.new([kibanaDeployment, kibanaService])
