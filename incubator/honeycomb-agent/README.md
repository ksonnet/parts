# Honeycomb Mixin

> The [Honeycomb Kubernetes agent][2] is a monitoring tool for pods
> and their containerized applications (e.g. nginx). It continuously
> observes, parses, and sends their log files to the Honeycomb API,
> where the data is rendered in a dashboard for real-time
> observability.

## Overview

`honeycomb-agent.libsonnet` is a JSON-compatible [ksonnet][12] library
that makes it easy to add [Honeycomb][1] to your Kubernetes
applications. The `examples` directory contains a few examples of how
to use it, including:

1. Using the `DaemonSet` builder to add the Honeycomb agent to each
   node in the cluster, and configuring it to parse the `stdout` logs
   of any `Pod` running on the same node. (See [source][16].)
    ```c++
    local daemonSet =
      local daemonSetName = "honeycomb-agent-v1.1";
      // Create simple `DaemonSet`, with required `ConfigMap` and
      // `Secret` objects that are required to deploy the Honeycomb
      // agent on each node in the cluster.
      honeycomb.app.daemonSetBuilder.new(daemonSetName, conf) +
      // Generate RBAC rules and volumes required to access pod logs,
      // and mount these volumes in the Honeycomb agent container.
      honeycomb.app.daemonSetBuilder.configureForPodLogs(conf);
    ```
1. Adding the Honeycomb agent to a normal JSON `Deployment` object as
   a side-car, so that it can parse the logs at some path. (See
   [source][17].)
    ```c++
    {
       "apiVersion": "extensions/v1beta1",
       "kind": "Deployment",
       [... object details omitted ...],
    } +
      // Add nginx logging to the deployment, so that the nginx and
      // Honeycomb agent container can both access the logs.
      deployment.mixin.spec.template.spec.volumes(nginxLogVolume) +
      // Mount container on both the nginx container and the
      // Honeycomb agent container.
      deployment.mapContainersWithName(
        ["nginx", "honeycomb-agent"],
        function(nginxContainer)
          nginxContainer + container.volumeMounts(nginxLogMount))
    ```

## Getting Started

### Prerequisites

* **[BUILD]** *You should have [Jsonnet][3] installed (minimum version
  0.9.4).* See [installation instructions][4] if this is not the case.
* **[BUILD]** *You should have cloned or forked the [ksonnet
  library][5].* If not:
  ```shell
  git clone git@github.com:ksonnet/ksonnet-lib.git
  git co honeycomb
  ```
* **[RUN]** *You should have access to an up-and-running Kubernetes
  cluster.* If you do not have a cluster, follow the [AWS Quickstart
  Kubernetes Tutorial][6] to set one up with a single command.
* **[RUN]** *You should have `kubectl` installed.* If not, follow the
  instructions for [installing via Homebrew (MacOS)][7] or [building
  the binary (Linux)][8].
* **[RUN]** *You should have a Honeycomb account*. [The trial
  version][9] lasts 30 days.
* It may be helpful to have some familiarity with ksonnet syntax, as
  described in the [official README][10].

### Install

Clone or fork this repo:

```shell
git clone git@github.com:ksonnet/mixins.git
```

### Building the examples

Before building your JSON config, you will need to find your Honeycomb
writekey, in order to identify your account to the agent. You can find
the writekey on your [account page][11]. Then base64 encode the
writekey so that you can use it in a Kubernetes secret:

```shell
$HONEYCOMB_WRITE_KEY | base64
```

You will use this key to populate a secret field in each of the
examples below.

### Building and running the Honeycomb agent as part of a `Deployment`

This application runs nginx in a `Deployment` (along with a
corresponding `Service`), logging to `stdout`. This example uses
mixins to embed the Honeycomb agent in the nginx `Deployment` object
as a sidecar, ane is configured to look for the nginx `Deployment`'s
`stdout` using Pod labels.

1. **Add your Honeycomb writekey to the example, so that it can talk
   to the Honeycomb server.** In
   [`incubator/honeycomb-agent/examples/sidecar-raw-deployment-object/nginx-deployment.jsonnet`][15],
   change `conf.secret.key` to hold the Honeycomb writekey you
   acquired above (it is currently set to raise an `error` if you
   don't set it).
1. **Compile the `Deployment` object containing the Honeycomb agent
   nginx, to JSON.** In the
   `incubator/honeycomb-agent/examples/using-deployment-builder/`
   directory, run the following command, where `KSONNET_LIB_PATH`
   points to the root directory of your ksonnet repo, and
   `MIXINS_LIB_PATH` points to the root of the mixins repo:
    ```shell
    jsonnet nginx-deployment.jsonnet -J $KSONNET_LIB_PATH $MIXINS_LIB_PATH nginx-deployment.json
    ```

#### Running

1. **Start the `Deployment` with nginx and the Honeycomb agent sidecar
   on your cluster.** In
   `incubator/honeycomb-agent/examples/using-deployment-builder/`, run:
    ```shell
    kubectl create -f nginx-deployment.json
    ```
1. **Start the nginx service on your cluster.** In
   `incubator/honeycomb-agent/examples/using-deployment-builder/`, run:
    ```shell
    kubectl create -f nginx-service.json
    ```

### Building and running the standalone Honeycomb agent `DaemonSet`

This application runs nginx in a `Deployment` (along with a
corresponding `Service`), logging to `stdout`. The Honeycomb agent
runs as a `DaemonSet` (so that it runs on every node in the cluster)
that is configured to look for the nginx `Deployment`'s `stdout` using
Pod labels.

1. **Add your Honeycomb writekey to the example, so that it can talk
   to the Honeycomb server.** In
   [`incubator/honeycomb-agent/examples/using-daemonset-builder/honeycomb-daemonset.jsonnet`][13],
   change `conf.secret.key` to hold the Honeycomb writekey you
   acquired above (it is currently set to raise an `error` if you
   don't set it).
1. **Compile the Honeycomb agent `DaemonSet` file to JSON.** In the
   `incubator/honeycomb-agent/examples/using-daemonset-builder/`
   directory, run the following command, where `KSONNET_LIB_PATH`
   points to the root directory of your ksonnet repo, and
   `MIXINS_LIB_PATH` points to the root of the mixins repo:
    ```shell
    jsonnet honeycomb-daemonset.jsonnet -J $KSONNET_LIB_PATH -J $MIXINS_LIB_PATH honeycomb-daemonset.json
    ```
1. **Compile the nginx app to JSON.** In the
   `incubator/honeycomb-agent/examples/using-daemonset-builder/`
   directory, run:
    ```shell
    jsonnet nginx-app.jsonnet -J $KSONNET_LIB_PATH > nginx-app.json
    ```

#### Running

1. **Start the Honeycomb agent on your cluster.** In
   `incubator/honeycomb-agent/examples/using-daemonset-builder/`, run:
    ```shell
    kubectl create -f honeycomb-daemonset.json
    ```
1. **Start the nginx app on your cluster.** In
   `incubator/honeycomb-agent/examples/using-daemonset-builder/`, run:
    ```shell
    kubectl create -f nginx-app.json
    ```

### Checking your application

Once your application is submitted to the cluster, you should verify
that it is doing what you expect.

1. **Check that the Pods are running.** Run:
    ```shell
    kubectl get pods -l k8s-app=honeycomb-agent --namespace=kube-system
    ```

    You should see something like the following output:

    ```shell
    NAME                                READY     STATUS    RESTARTS   AGE
    honeycomb-agent-v1.1-<PLACEHOLDER>   1/1       Running   0          1h
    honeycomb-agent-v1.1-<PLACEHOLDER>   1/1       Running   0          1h
    ```
1. **Check the output is being logged.** Run:
    ```shell
    kubectl logs honeycomb-agent-v1.1-<PLACEHOLDER> --namespace=kube-system
    ```

    The output should show the applied label selectors (e.g. `app=mysql`)
    and the files that the agent is watching.

## Configuration

### Meta-configs

`honeycomb-agent.libsonnet` uses an object with a specific schema to
decide how to configure itself. The schema is as follows:

Name | Default Value | Description | Important to Change?
--- | --- | --- | ---
secret.key | raises `error` | The base-64-encoding of your Honeycomb write key. | **Yes.** This must be populated or the Honeycomb agent won't be able to send processed logs to the API for your dashboard.
configMap.data | YAML config (see code) | The YAML data that configures Honeycomb settings like parser label selectors. See [Honeycomb documentation](https://github.com/honeycombio/honeycomb-kubernetes-agent/blob/master/README.md) for details on available configurations.  | Yes (if you want to change parser behavior)
rbac.accountname | "honeycomb-serviceaccount" | The name of the ServiceAccount that allows the Honeycomb agent to read pods and node API info. | No
agent.containerName | "honeycomb-agent" | The name of the agent container when we mix it into a deployment. It should be chosen so that it doesn't collide with any other container names in your app. | No
namespace | "kube-system" | The namespace that all Honeycomb pods are created under | No

## Customization

`honeycomb-agent.libsonent` exposes many of the primitives you will
need to customize how your application uses the Honeycomb agent.

The file is well-documented, and is broken down into three main
namespaces:

* `app::`, which contains the main application-level primitives
  (_e.g._, `daemonSetBuilder`) that are most relevant to people simply
  using the library.
* `parts::`, which contains the various parts necessary to build the
  application-level primitives like `daemonSetBuilder`).
* `mixin::`, which contains small utility mixins used to customize
  existing Kubernetes API objects (e.g.,
  `deployment.addHostMountedPodLogs`).

To see some examples of how to use these namespaces to build your own
mixins, look in the `app::` namespace.

[1]: https://honeycomb.io
[2]: https://github.com/honeycombio/honeycomb-kubernetes-agent/tree/master
[3]: http://jsonnet.org/
[4]: https://github.com/ksonnet/ksonnet-lib#install
[5]: https://github.com/ksonnet/ksonnet-lib
[6]: http://docs.heptio.com/content/tutorials/aws-cloudformation-k8s.html
[7]: https://kubernetes.io/docs/tasks/tools/install-kubectl/#install-with-homebrew-on-macos
[8]: https://kubernetes.io/docs/tasks/tools/install-kubectl/#tabset-1
[9]: https://ui.honeycomb.io/signup
[10]: http://ksonnet.heptio.com/docs/core-packages/ksonnet-lib.html#write-your-config-files-with-ksonnet
[11]: https://ui.honeycomb.io/account
[12]: http://ksonnet.heptio.com
[13]: https://github.com/ksonnet/mixins/blob/honeycomb/incubator/honeycomb-agent/examples/using-daemonset-builder/honeycomb-daemonset.jsonnet
[14]: https://github.com/ksonnet/mixins/blob/honeycomb/incubator/honeycomb-agent/examples/using-daemonset-builder/honeycomb-deployment.jsonnet
[15]: https://github.com/ksonnet/mixins/blob/honeycomb/incubator/honeycomb-agent/examples/sidecar-raw-deployment-object/nginx-deployment.jsonnet
[16]: https://github.com/ksonnet/mixins/tree/honeycomb/incubator/honeycomb-agent/examples/using-daemonset-builder
[17]: https://github.com/ksonnet/mixins/tree/honeycomb/incubator/honeycomb-agent/examples/sidecar-raw-deployment-object
