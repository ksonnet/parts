local k = import 'ksonnet.beta.2/k.libsonnet';
local nginx = import '../nginx.libsonnet';

local namespace = "dev-alex";
local appName = "nginx-app";
// sample configuration for php-fpm
// Note: must escape file path with extra \
local sbConfig = "server {
  listen 0.0.0.0:80;
  root /app;
  location / {
    index index.html index.php;
  }
  location ~ \\.php$ {
    fastcgi_pass phpfpm-server:9000;
    fastcgi_index index.php;
    include fastcgi.conf;
  }
}";

k.core.v1.list.new([
  nginx.parts.deployment.withServerBlock(namespace, appName),
  nginx.parts.service(namespace, appName),
  nginx.parts.serverBlockConfigMap(namespace, appName, sbConfig),
])
