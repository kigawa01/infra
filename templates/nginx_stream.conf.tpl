proxy_protocol off;

upstream mc {
    server base.kigawa.net:25565;
}

server {
    listen       0.0.0.0:25565;
    proxy_pass   mc;
}

upstream k8s {
    server base.kigawa.net:6443;
}

server {
    listen       0.0.0.0:6443;
    proxy_pass   k8s;
}

error_log /var/log/nginx/stream.log info;