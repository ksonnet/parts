# Honeycomb Mixin

> The [Honeycomb Kubernetes agent][2] is a monitoring tool for pods
> and their containerized applications (e.g. nginx). It continuously
> observes, parses, and sends their log files to the Honeycomb API,
> where the data is rendered in a dashboard for real-time
> observability.

* [Overview][21]
* [Getting Started][22]
  * [Prerequisites][23]
  * [Install][24]
  * [Credentials][25]
  * [Example A: The Honeycomb agent as `Deployment` sidecar][19]
  * [Example B: The Honeycomb agent as standalone `DaemonSet`][26]
  * [Checking your application][27]
* [Configuration and Customization][18]
  * [Value Configuration][28]
  * [Feature Customization][29]

## Overview

This directory contains the following components, which allow you to easily add [Honeycomb][1] to your Kubernetes applications:

1. `honeycomb-agent.libsonnet`: The core logic for Honeycomb lives in this JSON-compatible [ksonnet][12] library. Using its mixin components, you can quickly set up and customize your Honeycomb integration. See [Configuration and Customization][18] for more details.

1. `examples` directory: This contains a few examples of how to apply the Honeycomb mixins, including:

    * **Running the Honeycomb agent as a `DaemonSet`**: Using the `DaemonSet` builder, you can add the Honeycomb agent to each
     node in your cluster, and configure it to parse the `stdout` logs of any `Pod` running on the same node. (See [source][16].)
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

    * **Running the Honeycomb agent as a "side-car" container**: You can add the Honeycomb agent to a normal JSON `Deployment` object, and configure it to parse the logs at a specified path. (See
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
  described in the [official docs][10].

### Install

Clone or fork this repo:

```shell
git clone git@github.com:ksonnet/mixins.git
```

### Credentials

Before building and running your ksonnet configs, you will need your
Honeycomb writekey. This writekey identifies your account to the
agent.

You can find the writekey on your [account page][11]. Each of the
examples below refers to the write key as `$HONEYCOMB_WRITE_KEY`.

### Example A: The Honeycomb agent as `Deployment` sidecar

This sample application includes the following Kubernetes objects:

* A `Deployment` (*`nginx-deployment.jsonnet`*) that runs:
  * nginx logging to `stdout`
  * a Honeycomb agent, embedded as a sidecar and configured to look for nginx's `stdout` with *file paths*
* A `Service` to expose nginx (*`nginx-service.json`*)

#### Build

The nginx `Service` object definition is already valid JSON. To build the `Deployment` object from ksonnet to JSON:

1. **Add your Honeycomb writekey to the example, so that it can talk
   to the Honeycomb server.** In
   [`examples/sidecar-raw-deployment-object/nginx-deployment.jsonnet`][15],
   change `conf.secret.key` to hold the value of
   `$HONEYCOMB_WRITE_KEY`. (It is currently set to raise an error
   during the build).

1. **Compile the `Deployment` object.** In the
   `./examples/sidecar-raw-deployment-object/`
   directory, run the following command, where `$KSONNET_LIB_PATH`
   points to the root of your `ksonnet` repo, and
   `$MIXINS_LIB_PATH` points to the root of the `mixins` repo:

    ```shell
    jsonnet nginx-deployment.jsonnet -J $KSONNET_LIB_PATH $MIXINS_LIB_PATH nginx-deployment.json
    ```

#### Run

1. **Start the `Deployment` on your cluster.** In
   `./examples/sidecar-raw-deployment-object/`, run:

    ```shell
    kubectl create -f nginx-deployment.json
    ```

    Now both nginx and Honeycomb pods are running.

1. **Start the nginx `Service` on your cluster.** In
   `./examples/sidecar-raw-deployment-object/`, run:

    ```shell
    kubectl create -f nginx-service.json
    ```

    Now your nginx service is externally available via a LoadBalancer.

### Example B: The Honeycomb agent as standalone `DaemonSet`


This sample application includes the following Kubernetes objects:
* A `Deployment` that runs nginx logging to `stdout` (*`nginx-app.jsonnet`*)
* A `Service` to expose nginx (*`nginx-app.jsonnet`*)
* A `DaemonSet` running the Honeycomb agent on every node in the cluster. The agent is configured to look for nginx's `stdout` using *Pod labels* (*`honeycomb-daemonset.jsonnet`*)


#### Build

All of the above are defined in ksonnet files that need to be compiled to valid JSON configs:

1. **Add your Honeycomb writekey to the example, so that it can talk
   to the Honeycomb server.** In
   [`incubator/honeycomb-agent/examples/using-daemonset-builder/honeycomb-daemonset.jsonnet`][13],
   change `conf.secret.key` to hold the value of
   `$HONEYCOMB_WRITE_KEY`. (It is currently set to raise an error
   during the build).

1. **Compile the Honeycomb agent `DaemonSet`.** In the
   `./examples/using-daemonset-builder/`
   directory, run the following command, where `$KSONNET_LIB_PATH`
   points to the root of your `ksonnet` repo, and
   `$MIXINS_LIB_PATH` points to the root of the `mixins` repo:

    ```shell
    jsonnet honeycomb-daemonset.jsonnet -J $KSONNET_LIB_PATH -J $MIXINS_LIB_PATH honeycomb-daemonset.json
    ```

1. **Compile the nginx app (`Deployment` and `Service`) to JSON.** In the
   `./examples/using-daemonset-builder/`
   directory, run:

    ```shell
    jsonnet nginx-app.jsonnet -J $KSONNET_LIB_PATH > nginx-app.json
    ```

#### Run

1. **Start the Honeycomb agent on your cluster.** In
   `./examples/using-daemonset-builder/`, run:

    ```shell
    kubectl create -f honeycomb-daemonset.json
    ```

1. **Start the nginx app on your cluster.** In
   `./examples/using-daemonset-builder/`, run:

    ```shell
    kubectl create -f nginx-app.json
    ```

### Checking your application

Regardless of which example you run, you should verify that your application is doing what you expect once it is submitted to your cluster.

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

    The output should show the applied label selectors (e.g. `app=nginx`)
    and the files that the agent is watching.

## Configuration and Customization

There are two levels of setup that you can achieve with the Honeycomb mixin library:

1. **Value Configuration**: Regardless of how you combine the Honeycomb primitives, you first need to configure values that are specific to your cluster (e.g. your Honeycomb writekey).

1. **Feature Customization**: For basic functionality, you can stick to using the pre-defined, application-level primitives and their mixins. If your needs are not met by the existing primitives, you can extend the Honeycomb library by composing and building your own custom primitives.


### Value Configuration

The application-level mixins from `honeycomb-agent.libsonnet` take in a JSON `config` object, which specifies cluster-specific configuration values.

You can see an example of this below (taken from [`nginx-deployment.jsonnet`][15] in [Example A][19]:

```
local config = {
  namespace:: "kube-system",
  agent:: {
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
```

This `config` object follows a specific schema, detailed as follows:

Name | Description | Example
--- | --- | ---
`secret.key` | The Honeycomb write key obtained from your [account page][11]. This allows the Honeycomb agent to send processed logs to the API (and your dashboard). | `$HONEYCOMB_WRITE_KEY` (from previous sections)
`configMap.data` | YAML data that configures Honeycomb parser behavior, with settings like label selectors.  | See [Honeycomb documentation][20] for details on available configurations.
`rbac.accountname` | The name of the ServiceAccount that allows the Honeycomb agent to read pod and node API info. | "honeycomb-serviceaccount"
`agent.containerName` | The name of the agent container when we mix it into a deployment. It should be chosen so that it doesn't collide with any other container names in your app. | "honeycomb-agent"
`agent.containerTag` | The tag that specifies which Honeycomb image to use for your agent container. (e.g. with the example tag here, your Honeycomb agent would be built from image `honeycombio/honeycomb-kubernetes-agent:bd16721`). | "bd16721"
`namespace` | The namespace that all Honeycomb pods are created under. | "kube-system"

### Feature Customization

`honeycomb-agent.libsonnet` exposes many of the primitives you will
need to customize how your application uses the Honeycomb agent. You can combine these or add additional ones depending on your use case.

The file is well-documented, and is broken down into three main
namespaces, which roughly correspond to different layers of abstraction:

* **`app::`**: Contains the main application-level primitives
  (_e.g._, `daemonSetBuilder`) that are most relevant to people simply
  using the library.

* **`parts::`**: Contains the various parts necessary to build the
  application-level primitives like `daemonSetBuilder`).

* **`mixin::`**: Contains small utility mixins used to customize
  existing Kubernetes API objects (e.g.,
  `deployment.addHostMountedPodLogs`).

You can use these namespaces to build your own primitives, such as the example below (taken from the implementation of `app::DeploymentBuilder::configureForPodLogs`):

```
local rbacObjs = $.parts.rbac(config.rbac.accountName, config.namespace);
rbacObjs + {
  deployment+::
    $.mixin.deployment.addHostMountedPodLogs(
      varlogVolName,
      podLogsVolName,
      $.util.containerNameInSet(config.agent.containerName)) +
    ds.mixin.spec.template.spec.serviceAccountName(config.rbac.accountName)
},
```

This example combines the RBAC parts with log volume mounting and a `ServiceObject` definition.

For more examples of composing mixins with the Jsonnnet `+` operator, look in the `app::` namespace.

[1]: https://honeycomb.io
[2]: https://github.com/honeycombio/honeycomb-kubernetes-agent/tree/master
[3]: http://jsonnet.org/
[4]: https://github.com/ksonnet/ksonnet-lib#install
[5]: https://github.com/ksonnet/ksonnet-lib/tree/master
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
[18]: #configuration-and-customization
[19]: #example-a-the-honeycomb-agent-as-deployment-sidecar
[20]: https://github.com/honeycombio/honeycomb-kubernetes-agent/blob/master/README.md
[21]: #overview
[22]: #getting-started
[23]: #prerequisites
[24]: #install
[25]: #credentials
[26]: #example-b-the-honeycomb-agent-as-standalone-daemonset
[27]: #checking-your-application
[28]: #value-configuration
[29]: #feature-customization
