local k = import 'ksonnet.beta.2/k.libsonnet';

{
  parts::{
    local defaults = {
      serviceType: "LoadBalancer"
    },

    svc(, , ={app: })::{
      apiVersion: "v1",
        kind: "Service",
        metadata: {
          : ,
          : ,
          labels: {
            app:
          },
        },
        spec: {
          type: defaults.serviceType,
          ports: [
            {
              : "http",
              port: 80,
              targetPort: "http",
            },
          ],
          :
        },
    },

    secret(, , ):: {
      apiVersion: "v1",
      kind: "Secret",
      metadata: {
        : ,
        : ,
        labels: {
          app:
        },
      },
      type: "Opaque",
      data:
        if  != null then {
          "tomcat-password": std.base64()
        } else error "Please set password"
    },

    pvc(, , =null):: {
      local defaults = {
        persistence: {
          accessMode: "ReadWriteOnce",
          size: "8Gi",
        },
      },

      kind: "PersistentVolumeClaim",
      apiVersion: "v1",
      metadata: {
        : ,
        : ,
        labels: {
          app: ,
        },
        annotations:
          if  != null then {
            "volume.beta.kubernetes.io/storage-class": ,
          } else {
            "volume.alpha.kubernetes.io/storage-class": "default",
          },
      },
      spec: {
        accessModes: [
          defaults.persistence.accessMode
        ],
        resources: {
          requests: {
            storage: defaults.persistence.size,
          },
        },
      },
    },

    deployment:: {
      local defaults = {
        image: "bitnami/tomcat:8.0.46-r0",
        imagePullPolicy: "IfNotPresent",
        tomcatAllowRemoteManagement: 0,
        persistence:{
          accessMode: "ReadWriteOnce",
          size: "8Gi",
        },
        resources:{
          requests: {
            memory: "512Mi",
            cpu: "300m",
            },
        },
      },

      persistent(, , , , )::
        base(, , , ) +
        k.apps.v1beta1.deployment.mixin.spec.template.spec.volumes(
          {
            : "tomcat-data",
            persistentVolumeClaim: {
              : ,
            },
          }),

      nonPersistent(, , , )::
        base(, , , ) +
        k.apps.v1beta1.deployment.mixin.spec.template.spec.volumes(
          {
            : "tomcat-data",
            emptyDir: {}
          }),

      local base(, , , ) = {
        apiVersion: "extensions/v1beta1",
        kind: "Deployment",
        metadata: {
          : ,
          labels: {
            app: ,
          },
        },
        spec: {
          template: {
            metadata: {
              labels: {
                app: ,
              },
            },
            spec: {
              containers: [
                {
                  : ,
                  image: defaults.image,
                  imagePullPolicy: defaults.imagePullPolicy,
                  env: [
                    {
                      : "TOMCAT_USERNAME",
                      value: ,
                    },
                    {
                      : "TOMCAT_PASSWORD",
                      valueFrom: {
                        secretKeyRef: {
                          : ,
                          key: "tomcat-password",
                        },
                      },
                    }
                    {
                      : "TOMCAT_ALLOW_REMOTE_MANAGEMENT",
                      value: defaults.tomcatAllowRemoteManagement,
                    },
                  ],
                  ports: [
                    {
                      : "http",
                      containerPort: 8080,
                    },
                  ],
                  livenessProbe: {
                    httpGet: {
                      path: "/",
                      port: "http",
                    },
                    initialDelaySeconds: 120,
                    timeoutSeconds: 5,
                    failureThreshold: 6,
                  },
                  readinessProbe: {
                    httpGet: {
                      path: "/",
                      port: "http",
                    },
                    initialDelaySeconds: 30,
                    timeoutSeconds: 3,
                    periodSeconds: 51,
                  },
                  resources: defaults.resources,
                  volumeMounts: [
                    {
                      : "tomcat-data",
                      mountPath: "/bitnami/tomcat",
                    },
                  ],
                },
              ],
            },
          },
        },
      }
    },
  },
}