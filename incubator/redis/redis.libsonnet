local k = import 'ksonnet.beta.2/k.libsonnet';
local deployment = k.extensions.v1beta1.deployment;
local container = deployment.mixin.spec.template.spec.containersType;
local storageClass = k.storage.v1beta1.storageClass;
local service = k.core.v1.service;
local networkPolicy = k.extensions.v1beta1.networkPolicy;
local networkSpec = networkPolicy.mixin.spec;

{
  parts:: {
    networkPolicy:: {
      local defaults = {
        name: "redis-app",
        inboundPort: {
          ports: [{port:6379}]
        },
      },

      allowExternal(namespace,allowInbound,metricEnabled=false)::
        base(namespace, metricEnabled) +
        networkSpec.ingress(defaults.inboundPort),

      denyExternal(namespace,allowInbound,metricEnabled=false)::
        local ingressRule = defaults.inboundPort + {
          from: [
            {
              podSelector: {
                matchLabels: {
                  [defaults.name + "-client"]: "true"
                }
              }
            },
          ],
        };
        base(namespace, metricEnabled)+
        networkSpec.ingress(ingressRule),

      local base(namespace, metricEnabled) = {
        kind: "NetworkPolicy",
        apiVersion: "networking.k8s.io/v1",
        metadata: {
          name: defaults.name,
          namespace: namespace,
          labels: {
            app: defaults.name,
          },
        },
        spec: {
          podSelector: {
            matchLabels: {
              app: defaults.name,
            }
          },
          [if metricEnabled then "ingress"]: [
            {
              # Allow prometheus scrapes for metrics
              ports: [
                {port: 9121},
              ]
            }
          ],
        },
      },
    },

    secret(namespace, redisPassword)::
      local defaults = {
        name: "redis-app",
        usePassword: true,
      };

      {
        apiVersion: "v1",
        kind: "Secret",
        metadata: {
          name: defaults.name,
          namespace: namespace,
          labels: {
            app: defaults.name,
          },
        },
        type: "Opaque",
        data: {
          "redis-password": std.base64(redisPassword),
        },
      },

    svc:: {
      local defaults = {
        name: "redis-app"
      },

      metricEnabled(namespace)::
        local annotations = {
          "prometheus.io/scrape": "true",
          "prometheus.io/port": "9121"
        };
        svcBase(namespace) +
          service.mixin.metadata.annotations(annotations),

      local svcBase(namespace)= {
        apiVersion: "v1",
        kind: "Service",
        metadata: {
          name: defaults.name,
          namespace: namespace,
          labels: {
            app: defaults.name,
          },
        },
        spec: {
          ports: [
            {
              name: "redis",
              port: 6379,
              targetPort: "redis",
            }
          ],
          selector: {
            app: defaults.name
          },
        }
      },
    },

    pvc:: {
      local defaults = {
        name: "redis-app",
        accessMode: "ReadWriteOnce",
        size: '8Gi'
      },

      pvcBase(namespace, storageClassName = "-"):: {
        kind: "PersistentVolumeClaim",
        apiVersion: "v1",
        metadata: {
          name: defaults.name,
          namespace: namespace,
          labels: {
            app: defaults.name,
          }
        },
        spec: {
          accessModes: [
            defaults.accessMode,
          ],
          storageClassName: storageClassName,
          resources: {
            requests: {
              storage: defaults.size,
            },
          },
        },
      },
    },

    deployment:: {
      local defaults = {
        name:: "redis-app",
        image:: "bitnami/redis:3.2.9-r2",
        imagePullPolicy:: "IfNotPresent",
        resources:: {
          "requests": {
            "memory": "256Mi",
            "cpu": "100m"
          },
        },
        dataMount:: {
          name: "redis-data",
          mountPath: "/bitnami/redis",
        },
        metrics:: {
          image: "oliver006/redis_exporter",
          imageTag: "v0.11",
          imagePullPolicy: "IfNotPresent",
        },
      },

      nonPersistent(namespace, secretName, metricEnabled=false)::
        local volume = {
          name: "redis-data",
          emptyDir: {}
        };
        base(namespace, secretName, metricEnabled) +
        deployment.mixin.spec.template.spec.volumes(volume) +
        deployment.mapContainersWithName(
          [defaults.name],
          function(c) c + container.volumeMounts(defaults.dataMount)
        ),

      persistent(namespace, secretName, metricEnabled=false, claimName=defaults.name)::
        local volume = {
          name: "redis-data",
          persistentVolumeClaim: {
            claimName: claimName
          }
        };
        base(namespace, secretName, metricEnabled) +
        deployment.mixin.spec.template.spec.volumes(volume) +
        deployment.mapContainersWithName(
          [defaults.name],
          function(c) c + container.volumeMounts(defaults.dataMount)
        ),

      local base(namespace, secretName, metricsEnabled) =
        local metricsContainer =
          if !metricsEnabled then []
          else [{
            name: "metrics",
            image: defaults.metrics.image + ':' + defaults.metrics.imageTag,
            imagePullPolicy: defaults.metrics.imagePullPolicy,
            env: [
              {
                name: "REDIS_ALIAS",
                value: defaults.name,
              }
            ] + if secretName == null then []
            else [
              {
                name: "REDIS_PASSWORD",
                valueFrom: {
                  secretKeyRef: {
                    name: defaults.name,
                    key: "redis-password",
                  }
                },
              },
            ],
            ports: [
              {
                name: "metrics",
                containerPort: 9121,
              }
            ],
          }];
      {
        apiVersion: "extensions/v1beta1",
        kind: "Deployment",
        metadata: {
          name: defaults.name,
          namespace: namespace,
          labels: {
            app: defaults.name,
          },
        },
        spec: {
          template: {
            metadata: {
              labels: {
                app: defaults.name,
              }
            },
            spec: {
              containers: [
                {
                  name: defaults.name,
                  image: defaults.image,
                  imagePullPolicy: defaults.imagePullPolicy,
                  env: [
                    if secretName != null then
                    {
                      name: "REDIS_PASSWORD",
                      valueFrom: {
                        secretKeyRef: {
                          name: secretName,
                          key: "redis-password",
                        },
                      }
                    }
                    else{
                      name: "ALLOW_EMPTY_PASSWORD",
                      value: "yes",
                    },
                  ],
                  ports: [
                    {
                      name: "redis",
                      containerPort: 6379,
                    },
                  ],
                  livenessProbe: {
                    exec: {
                      command: [
                        "redis-cli",
                        "ping",
                      ],
                    },
                    initialDelaySeconds: 30,
                    timeoutSeconds: 5,
                  },
                  readinessProbe: {
                    exec: {
                      command: [
                        "redis-cli",
                        "ping",
                      ],
                    },
                    initialDelaySeconds: 5,
                    timeoutSeconds: 1,
                  },
                  resources: defaults.resources,
                },
              ] + metricsContainer,
            },
          },
        },
      },
    },
  },
}
