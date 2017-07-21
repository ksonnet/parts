local k = import "ksonnet.beta.2/k.libsonnet";

// Destructuring imports for base.
local container = k.core.v1.replicationController.mixin.spec.template.spec.containersType;
local containerPort = container.portsType;
local env = container.envType;
local rc = k.core.v1.replicationController;
local service = k.core.v1.service;
local servicePort = service.mixin.spec.portsType;
local volume = k.core.v1.replicationController.mixin.spec.template.spec.volumesType;
local volumeMount = container.volumeMountsType;

// Destructuring RBAC imports.
local svcAccount = k.core.v1.serviceAccount;
local clRoleBinding = k.rbac.v1beta1.clusterRoleBinding;
local clRole = k.rbac.v1beta1.clusterRole;
local subject = clRoleBinding.subjectsType;
local rule = clRole.rulesType;

{
  app:: {
    new(config)::
      local dbPortName = "db";
      local rbacObjs = $.parts.rbac(config.rbac.accountName, config.namespace);
      rbacObjs + {
        toArray()::
          local objs = [self.service, self.controller];
          if "toArray" in super
          then super.toArray() + objs
          else objs,
        service:: $.parts.service(dbPortName, config),
        controller:: $.parts.controller(dbPortName, config),
      },
  },

  parts:: {
    local boilerplate = {
      appName:: "elasticsearch-logging",

      storageName:: "es-persistent-storage",

      controller:: {
        selector:: {
          "k8s-app": boilerplate.appName,
          "version": "v1",
        },

        labels:: self.selector + {
          "addonmanager.kubernetes.io/mode": "Reconcile",
          "kubernetes.io/cluster-service": "true",
        },

        templateLabels:: self.selector + {
          "kubernetes.io/cluster-service": "true",
        },
      },

      service:: {
        labels:: {
          "addonmanager.kubernetes.io/mode": "Reconcile",
          "k8s-app": boilerplate.appName,
          "kubernetes.io/cluster-service": "true",
          "kubernetes.io/name": "Elasticsearch"
        },

        selector:: {"k8s-app": boilerplate.appName},
      },
    },

    container(dbPortName, config)::
      local dbPort =
        containerPort.newNamed(dbPortName, 9200) +
        containerPort.protocol("TCP");
      local transportPort =
        containerPort.newNamed("transport", 9300) +
        containerPort.protocol("TCP");
      local dataMount = volumeMount.new(boilerplate.storageName, "/data");
      local resources =
        container.mixin.resources.limits({cpu: "1000m"}) +
        container.mixin.resources.requests({cpu: "100m"});
      container.new(
        boilerplate.appName,
        "gcr.io/google_containers/elasticsearch:%s" % config.container.tag) +
      container.env(env.fromFieldPath("NAMESPACE", "metadata.namespace")) +
      container.ports([dbPort, transportPort]) +
      container.volumeMounts(dataMount) +
      resources,

    controller(dbPortName, config)::
      local dataVol = volume.fromEmptyDir(boilerplate.storageName, {});
      rc.new() +
      rc.mixin.metadata.name("elasticsearch-logging-v1") +
      rc.mixin.metadata.namespace(config.namespace) +
      rc.mixin.metadata.labels(boilerplate.controller.labels) +
      rc.mixin.spec.replicas(2) +
      rc.mixin.spec.selector(boilerplate.controller.selector) +
      rc.mixin.spec.template.metadata.labels(boilerplate.controller.templateLabels) +
      rc.mixin.spec.template.spec.containers($.parts.container(dbPortName, config)) +
      rc.mixin.spec.template.spec.volumes(dataVol) +
      rc.mixin.spec.template.spec.serviceAccountName(config.rbac.accountName),

    service(dbPortName, config)::
      local port =
        servicePort.new(9200, dbPortName) +
        servicePort.protocol("TCP");
      service.new("elasticsearch-logging", boilerplate.service.selector, [port]) +
      service.mixin.metadata.namespace(config.namespace) +
      service.mixin.metadata.labels(boilerplate.service.labels) +
      service.mixin.spec.type("LoadBalancer"),

    // Creates all top-level objects and mixins we need to add RBAC
    // support to support the ElasticSearch logging infrastructure.
    rbac(name, namespace)::
      local metadata = svcAccount.mixin.metadata.name(name) +
        svcAccount.mixin.metadata.namespace(namespace);

      local hcServiceAccount = svcAccount.new() +
        metadata;

      local hcClusterRole =
        clRole.new() +
        metadata +
        clRole.rules(
          rule.new() +
          rule.apiGroups("*") +
          rule.resources(["namespaces", "services", "endpoints"]) +
          rule.verbs(["get"])
        );

      local hcClusterRoleBinding =
        clRoleBinding.new() +
        metadata +
        clRoleBinding.mixin.roleRef.apiGroup("rbac.authorization.k8s.io") +
        clRoleBinding.mixin.roleRef.name(name) +
        clRoleBinding.mixin.roleRef.mixinInstance({kind: "ClusterRole"}) +
        clRoleBinding.subjects(
          subject.new() +
          subject.name(name) +
          subject.namespace(namespace)
          {kind: "ServiceAccount"}
        );

      // Return.
      {} + {
        toArray()::
          local objs = [self.account, self.clusterRole, self.roleBinding];
          if "toArray" in super
          then super.toArray() + objs
          else objs,
        account:: hcServiceAccount,
        clusterRole:: hcClusterRole,
        roleBinding:: hcClusterRoleBinding,
      },
  },
}