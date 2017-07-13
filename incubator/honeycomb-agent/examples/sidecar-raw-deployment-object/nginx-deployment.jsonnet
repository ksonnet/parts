// -------------------------------------------------------------------
// Example of the Honeycomb agent embedded as a sidecar in a raw JSON
// `Deployment` object. We use the deployment builder abstraction to
// define the required `ConfigMap` and `Secret` objects required to
// run the Honeycomb agent.
//
// This example:
//
// 1. Embeds the Honeycomb agent into the pod of a Deployment object
//    that contains nginx.
// 2. Specifies the paths of the logs to consume with
//    `conf.configMap.data`, along with which parsers to use.
// -------------------------------------------------------------------

// NOTE: For these imports you must invoke the Jsonnet CLI with -J
// flags pointing at (1) the ksonnet library root, and (2) the root
// of the mixins repository.
local k = import "ksonnet.beta.2/k.libsonnet";
local honeycomb = import "incubator/honeycomb-agent/honeycomb-agent.libsonnet";

// Destructure imports.
local deployment = k.extensions.v1beta1.deployment;
local volume = deployment.mixin.spec.template.spec.volumesType;
local container = deployment.mixin.spec.template.spec.containersType;
local mount = container.volumeMountsType;

// Configuration. Specifies how to set up the DaemonSet and Honeycomb
// agent.
//
// NOTE: Unlike the `DaemonSet` example, the Honeycomb agent is
// embedded as a sidecar, which means its label selector only
// applies to the pod in the `Deployment` object below.
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
          paths:
          - /var/log/nginx/error.log
          - /var/log/nginx/access.log
      verbosity: debug
|||,
  },
  secret:: {
    key:: error "A Honeycomb write key is required in `conf.secret.key`",
  },
};

// A normal Kubernetes `Deployment` object that contains an nginx
// container.
//
// NOTE: The configuration above uses label selectors that target
// this specific deployment.
local nginxDeployment = {
   "apiVersion": "extensions/v1beta1",
   "kind": "Deployment",
   "metadata": {
      "name": "nginx-deployment",
      "namespace": "kube-system"
   },
   "spec": {
      "replicas": 2,
      "template": {
         "metadata": {
            "labels": {
               "app": "nginx"
            }
         },
         "spec": {
            "containers": [
               {
                  "image": "nginx:1.7.9",
                  "name": "nginx",
                  "ports": [
                     {
                        "containerPort": 80
                     }
                  ],
               }
            ]
         }
      }
   }
};

// Configure a deployment with an nginx container to share logs with
// a Honeycomb sidecar. In particular:
//
// 1. Creates a volume containing the nginx logs, so that the
//    Honeycomb agent can access them.
// 2. Mounts the volume to both the nginx container, and the
//    Honeycomb agent container.
//
// NOTE: It is possible also to add the volume and the mount directly
// to the deployment above using something like the code below, with
// the caveat that you would have to use `mapContainersWithName`
// again to add the mount to the Honeycomb agent container.
//
//   {
//      "apiVersion": "extensions/v1beta1",
//      "kind": "Deployment",
//      [... object details omitted ...],
//   } +
//     deployment.mixin.spec.template.spec.volumes(nginxLogVolume) +
//     deployment.mapContainersWithName(
//       "nginx",
//       function(nginxContainer)
//         nginxContainer + container.volumeMounts(nginxLogMount));
local configureForNginx(nginxLogVolName, nginxContainerName, config) =
  local nginxLogVolume = volume.fromEmptyDir(nginxLogVolName);
  local nginxLogMount = mount.new(nginxLogVolName, "/var/log/nginx");
  deployment.mixin.spec.template.spec.volumes(nginxLogVolume) +
  deployment.mapContainersWithName(
    [config.agent.containerName, nginxContainerName],
    function(appContainer)
      appContainer + container.volumeMounts(nginxLogMount)
    );

// Generate a `Deployment` builder from `nginxDeployment`, add
// Honeycomb agent as a sidecar, configure to have access to the
// `stdout` of Pods.
local appWithHoneycomb =
  honeycomb.app.deploymentBuilder.fromDeployment(nginxDeployment, conf) + {
    deployment+:: configureForNginx("nginx-logs", "nginx", conf),
  };

// Emit all top-level objects (e.g., RBAC configurations, configMaps,
// etc.) in a `v1.List`.
k.core.v1.list.new(appWithHoneycomb.toArray())
