local k = import "ksonnet.beta.2/k.libsonnet";

// Destructuring imports for base.
local container = k.core.v1.replicationController.mixin.spec.template.spec.containersType;
local ds = k.extensions.v1beta1.daemonSet;
local volume = ds.mixin.spec.template.spec.volumesType;
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

  app:: {
    admin:: {
      rbacForPodLogs(config)::
        $.parts.rbac(config.rbac.accountName, config.namespace),
    },

    daemonSetBuilder:: {
      new(config):: {
        toArray():: [self.daemonSet],
        daemonSet:: $.parts.daemonSet(config.daemonSet.name, config.container.name, config.container.tag, config.namespace)
      },

      configureForPodLogs(
        config,
        varlogVolName="varlog",
        podLogsVolName="varlibdockercontainers",
      )::
        {} + {
          daemonSet+::
            $.mixin.daemonSet.addHostMountedPodLogs(
              varlogVolName,
              podLogsVolName,
              $.util.containerNameInSet(config.container.name)) +
            ds.mixin.spec.template.spec.serviceAccountName(config.rbac.accountName)
        },
    },
  },

  parts:: {
    local boilerplate = {
      dsLabels:: {
        "addonmanager.kubernetes.io/mode": "Reconcile",
        "k8s-app": "fluentd-es",
        "kubernetes.io/cluster-service": "true",
        "version": "v1.22"
      },

      templateLabels:: {
        "k8s-app": "fluentd-es",
        "kubernetes.io/cluster-service": "true",
        "version": "v1.22"
      },

      fluentdSelector:: {
        "beta.kubernetes.io/fluentd-ds-ready": "true"
      },
    },

    container(name, tag)::
      container.new(name, "gcr.io/google_containers/fluentd-elasticsearch:%s" % tag) +
      container.command([
        "/bin/sh",
        "-c",
        "/usr/sbin/td-agent 2>&1 >> /var/log/fluentd.log"
      ]) +
      container.mixin.resources.limits({"memory": "200Mi"}) +
      container.mixin.resources.requests({
        "cpu": "100m",
        "memory": "200Mi"
      }),

    daemonSet(dsName, containerName, conatinerTag, namespace)::
      ds.new() +
      ds.mixin.metadata.name(dsName) +
      ds.mixin.metadata.namespace(namespace) +
      ds.mixin.metadata.labels(boilerplate.dsLabels) +
      ds.mixin.spec.template.metadata.annotations({
        "scheduler.alpha.kubernetes.io/critical-pod": ""
      }) +
      ds.mixin.spec.template.metadata.labels(boilerplate.templateLabels) +
      ds.mixin.spec.template.spec.containers(self.container(containerName, conatinerTag)) +
      ds.mixin.spec.template.spec.terminationGracePeriodSeconds(30) +
      ds.mixin.spec.template.spec.nodeSelector(boilerplate.fluentdSelector),

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
  },

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
  },
}
