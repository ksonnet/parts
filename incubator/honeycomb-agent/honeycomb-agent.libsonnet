local k = import "ksonnet.beta.2/k.libsonnet";

// Destructuring imports for base.
local ds = k.extensions.v1beta1.daemonSet;
local container = k.extensions.v1beta1.daemonSet.mixin.spec.template.spec.containersType;
local configMap = k.core.v1.configMap;
local deployment = k.extensions.v1beta1.deployment;
local envVar = container.envType;
local secret = k.core.v1.secret;
local volume = ds.mixin.spec.template.spec.volumesType;
local keyToPath = volume.mixin.configMap.itemsType;
local volumeMount = container.volumeMountsType;

// Destructuring RBAC imports.
local svcAccount = k.core.v1.serviceAccount;
local clRoleBinding = k.rbac.v1beta1.clusterRoleBinding;
local clRole = k.rbac.v1beta1.clusterRole;
local subject = clRoleBinding.subjectsType;
local rule = clRole.rulesType;

{
  util:: {
    containerNameInSet(items)::
      local itemSet =
        if std.type(items) == "array"
        then std.set(items)
        else std.set([items]);
      function(container) std.length(std.setInter(itemSet, std.set([container.name]))) > 0,
  },

  // A collection of base configurations for deploying Honeycomb to
  // Kubernetes.
  app:: {
    local defaultConfig = {
      volume:: {
        configMapName:: "config",
      },
      configMap:: {
        name:: "honeycomb-agent-config",
      },
      secret:: {
        name:: "honeycomb-writekey",
      },
    },

    // daemonSetBuilder defines a defines a Honeycomb agent DaemonSet,
    // which allows the agent to run every node in the cluster. This
    // DaemonSet must be configured to have access to resources in
    // order to consume application logs. Typically this is done with
    // the `mixin` namespace.
    daemonSetBuilder:: {
      new(daemonSetName, config)::
        local configMapObjs = $.parts.configMap(
          defaultConfig.configMap.name, config.configMap.data, config.namespace);

        local secretObjs = $.parts.secret(
          defaultConfig.secret.name, std.base64(config.secret.key), config.namespace);

        local agentDs = $.parts.daemonSet(
          daemonSetName, config.agent.containerName, config.agent.containerTag, config.namespace) +
          configMapObjs.mixin.daemonSet.addConfigVolume(defaultConfig.volume.configMapName) +
          secretObjs.mixin.daemonSet.addWriteKey();

        // Return.
        {
          // NOTE: The way this is exposed to the user means that
          // there are some limitations to what a mixin can be
          // applied to do. For example, appending a volume mount to
          // every container in the DaemonSet is doable, but changing
          // the name of a volume is harder, because after this
          // object is crated, the name appears in multiple places.
          // This may or may not be important for our use case.

          toArray():: [self.daemonSet, self.configMap, secretObjs.secret],
          daemonSet:: agentDs,
          configMap:: configMapObjs.configMap,
          secret:: secretObjs.secret,
        },

      configureForPodLogs(
        config,
        varlogVolName="varlog",
        podLogsVolName="varlibdockercontainers",
      )::
        local rbacObjs = $.parts.rbac(config.rbac.accountName, config.namespace);
        rbacObjs + {
          daemonSet+::
            $.mixin.daemonSet.addHostMountedPodLogs(
              varlogVolName,
              podLogsVolName,
              $.util.containerNameInSet(config.agent.containerName)) +
            ds.mixin.spec.template.spec.serviceAccountName(config.rbac.accountName)
        },
    },

    deploymentBuilder:: {
      fromDeployment(appDeployment, config)::
        local configMapObjs = $.parts.configMap(
          defaultConfig.configMap.name, config.configMap.data, config.namespace);

        local secretObjs = $.parts.secret(
          defaultConfig.secret.name, std.base64(config.secret.key), config.namespace);

        local agentContainerSelector =
          $.util.containerNameInSet(config.agent.containerName);
        local agentContainer = $.parts.agentContainer(
          config.agent.containerName, config.agent.containerTag);

        // Return.
        {
          // NOTE: The way this is exposed to the user means that
          // there are some limitations to what a mixin can be
          // applied to do. For example, appending a volume mount to
          // every container in the Deployment is doable, but changing
          // the name of a volume is harder, because after this
          // object is crated, the name appears in multiple places.
          // This may or may not be important for our use case.

          toArray():: [self.deployment, self.configMap, secretObjs.secret],
          deployment::
            appDeployment +
            deployment.mixin.spec.template.spec.containers(agentContainer) +
            configMapObjs.mixin.deployment.addConfigVolume(
              defaultConfig.volume.configMapName,
              agentContainerSelector) +
            secretObjs.mixin.daemonSet.addWriteKey(agentContainerSelector),
          configMap:: configMapObjs.configMap,
          secret:: secretObjs.secret,
        },

      configureForPodLogs(
        config,
        varlogVolName="varlog",
        podLogsVolName="varlibdockercontainers",
      )::
        local rbacObjs = $.parts.rbac(config.rbac.accountName, config.namespace);
        rbacObjs + {
          deployment+::
            $.mixin.deployment.addHostMountedPodLogs(
              varlogVolName,
              podLogsVolName,
              $.util.containerNameInSet(config.agent.containerName)) +
            ds.mixin.spec.template.spec.serviceAccountName(config.rbac.accountName)
        },
    },
  },

  // A collection of parts, from which the higher-level abstractions
  // in the `app` namespace are assembled.
  parts:: {
    podLogs(varlogName, podlogsName)::
      local varLogVol = volume.fromHostPath(varlogName, "/var/log");
      local podLogsVol =
        // Pod logs are located on the host at well-known path.
        // Define volumes and mounts for these paths, so the
        // Honeytailer can access them.
        volume.fromHostPath(podlogsName,"/var/lib/docker/containers");
      {
        varLogVolume:: varLogVol,
        varLogMount:: volumeMount.new(varLogVol.name, varLogVol.hostPath.path),
        podLogVolume:: podLogsVol,
        podLogMount::
          // podLogsVol is read-only because the directory is shared
          // with other pods
          volumeMount.new(podLogsVol.name, podLogsVol.hostPath.path, true),
      },

    agentContainer(name, tag)::
      local image = "honeycombio/honeycomb-kubernetes-agent:%s" % tag;
      container.new(name, image) +
      container.mixin.resources.limits({memory: "200Mi"}) +
      container.mixin.resources.requests({memory: "200Mi", cpu: "100m"}) +
      container.env([
        envVar.new("HONEYCOMB_DATASET", "kubernetes"),
        envVar.fromFieldPath("NODE_NAME", "spec.nodeName")
      ]),

    defaultHoneycombLabels:: {
      "k8s-app": "honeycomb-agent",
      "kubernetes.io/cluster-service": "true",
      version: "v1.1",
    },

    // Creates a basic DaemonSet for the Honeycomb agent. Does not
    // contain (e.g.) RBAC support.
    daemonSet(name, containerName, containerTag, namespace)::
      ds.new() +
      // Metadata.
      ds.mixin.metadata.name(name) +
      ds.mixin.metadata.namespace(namespace) +
      ds.mixin.metadata.labels(self.defaultHoneycombLabels) +
      // Update strategy.
      ds.mixin.spec.updateStrategy.type("RollingUpdate") +
      ds.mixin.spec.updateStrategy.rollingUpdate.maxUnavailable(1) +
      // Template.
      ds.mixin.spec.template.metadata.labels(self.defaultHoneycombLabels) +
      ds.mixin.spec.template.spec.containers(
        self.agentContainer(containerName, containerTag)) +
      ds.mixin.spec.template.spec.terminationGracePeriodSeconds(30) +
      ds.mixin.spec.template.spec.tolerations([{"operator": "Exists"}, {"effect": "NoSchedule"}]),

    // Creates all top-level objects and mixins we need to add RBAC
    // support to a Honeycomb agent DaemonSet.
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
          rule.resources(["pods", "nodes"]) +
          rule.verbs(["list", "watch"])
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
      {
        toArray()::
          local objs = [self.account, self.clusterRole, self.roleBinding];
          if "toArray" in super
          then super.toArray() + objs
          else objs,
        account:: hcServiceAccount,
        clusterRole:: hcClusterRole,
        roleBinding:: hcClusterRoleBinding,
      },

    // Creates a configMap from which the Honeycomb agent is
    // configured, as well as mixins that add volume mounts for the
    // ConfigMap to every container in the Honeycomb agent DaemonSet.
    configMap(name, configYaml, namespace)::
      local yamlKey = "config.yaml";
      local cm =
        configMap.new() +
        configMap.mixin.metadata.name(name) +
        configMap.mixin.metadata.namespace(namespace) +
        configMap.data({[yamlKey]: configYaml});

      // Return.
      {
        configMap:: cm,
        mixin:: {
          local configVol(volName) = volume.fromConfigMap(
            volName,
            cm.metadata.name,
            keyToPath.new(yamlKey, yamlKey)),
          local configMount(volName) = volumeMount.new(volName, "/etc/honeycomb"),
          daemonSet:: {
            // configVolumeMixin takes a volume name and produces a
            // mixin that will append the Honeycomb agent `ConfigMap`
            // to a `DaemonSet` (as, e.g., the Honeycomb agent is),
            // and then mount that `ConfigMap` in the subset of
            // containers in the `DaemonSet` specified by the
            // predicate `containerSelector`.
            addConfigVolume(volName, containerSelector=function(c) true)::
              // Add volume to DaemonSet.
              ds.mixin.spec.template.spec.volumes([configVol(volName)]) +

              // Add volume mount to every container in the DaemonSet.
              ds.mapContainers(
                function (c)
                  if containerSelector(c)
                  then c + container.volumeMounts([configMount(volName)])
                  else c),
          },
          deployment:: {
            // configVolumeMixin takes a volume name and produces a
            // mixin that will append the Honeycomb agent `ConfigMap`
            // to a `DaemonSet` (as, e.g., the Honeycomb agent is),
            // and then mount that `ConfigMap` in the subset of
            // containers in the `DaemonSet` specified by the
            // predicate `containerSelector`.
            addConfigVolume(volName, containerSelector=function(c) true)::
              // Add volume to DaemonSet.
              deployment.mixin.spec.template.spec.volumes([configVol(volName)]) +

              // Add volume mount to every container in the DaemonSet.
              deployment.mapContainers(
                function (c)
                  if containerSelector(c)
                  then c + container.volumeMounts([configMount(volName)])
                  else c),
          },
        },
      },

    // Creates the secret holding the Honeycomb write key, as well as
    // mixins required to mount this secret in the Honeycomb agent
    // DaemonSet.
    secret(name, key, namespace)::
      local keyName = "key";
      local secretVal =
        secret.new() +
        secret.mixin.metadata.name(name) +
        secret.mixin.metadata.namespace(namespace) +
        secret.data({[keyName]: key});
      local secretKey = envVar.fromSecretRef("HONEYCOMB_WRITEKEY", name, keyName);
      {
        secret:: secretVal,
        mixin:: {
          daemonSet:: {
            addWriteKey(containerSelector=function(c) true)::
              ds.mapContainers(
                function (c)
                  if containerSelector(c)
                  then c + container.env(secretKey)
                  else c),
          },
          deployment:: {
            addWriteKey(containerSelector=function(c) true)::
              deployment.mapContainers(
                function (c)
                  if containerSelector(c)
                  then c + container.env(secretKey)
                  else c),
          },
        },
      },
  },

  // --------------------------------------------------------------------------

  // A collection of customizations for the Honeycomb agent. For
  // example, mixins that add pod logs into the Honeycomb agent
  // container, so that it can get logs from arbitrary pods.
  mixin:: {
    daemonSet:: {
      // addhostMountedPodLogs takes a two volume names and produces a
      // mixin that will mount the Kubernetes pod logs into a set of
      // containers specified by `containerSelector`.
      addHostMountedPodLogs(
        varlogName, podlogsName, containerSelector=function(c) true
      )::
        local podLogs = $.parts.podLogs(varlogName, podlogsName);

        // Add volume to DaemonSet.
        ds.mixin.spec.template.spec.volumes([
          podLogs.varLogVolume,
          podLogs.podLogVolume,
        ]) +

        // Add volume mount to selected containers in the DaemonSet.
        ds.mapContainers(
          function (c)
            if containerSelector(c)
            then
              c + container.volumeMounts([
                podLogs.varLogMount,
                podLogs.podLogMount,
              ])
            else c),
    },

    deployment:: {
      addHostMountedPodLogs(
        varlogName, podlogsName, containerSelector=function(c) true
      )::
        local podLogs = $.parts.podLogs(varlogName, podlogsName);

        // Add volume to Deployment, and attach mounts to every
        // container for which `containerSelector` is true.
        deployment.mixin.spec.template.spec.volumes([
          podLogs.varLogVolume,
          podLogs.podLogVolume,
        ]) +

        // Add volume mount to selected containers in the Deployment.
        deployment.mapContainers(
          function (c)
            if containerSelector(c)
            then
              c + container.volumeMounts([
                podLogs.varLogMount,
                podLogs.podLogMount,
              ])
            else c),
    },
  },
}
