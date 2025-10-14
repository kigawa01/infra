proxy_protocol off;

upstream http {
    server 192.168.1.56:80;
}

server {
    listen       0.0.0.0:80;
    proxy_pass   http;
}

upstream https {
    server 192.168.1.56:443;
}

server {
    listen       0.0.0.0:443;
    proxy_pass   https;
}

upstream mc {
    server 192.168.1.54:25565;
}

server {
    listen       0.0.0.0:25565;
    proxy_pass   mc;
}

upstream dev {
    server 192.168.1.50:7521;
}

server {
    listen       0.0.0.0:7521;
    proxy_pass   dev;
}

upstream softether {
    server 192.168.1.55:5555;
}

server {
    listen       0.0.0.0:5555;
    proxy_pass   softether;
}

upstream haproxy {
    server 192.168.1.104:6443;
}

server {
    listen       0.0.0.0:6443;
    proxy_pass   haproxy;
}

error_log /var/log/nginx/stream.log info;
