worker_processes  auto;
worker_rlimit_nofile  100000;

events {
    worker_connections  1024;
    multi_accept on;
}

http {
    include       mime.types;
    default_type  application/octet-stream;

    sendfile        on;

    keepalive_timeout  65;
    send_timeout 200;
    proxy_connect_timeout 1000;
    proxy_read_timeout    800;
    proxy_send_timeout    800;

    server {
        client_max_body_size 0;
        listen       80;
        server_name  ${server_name};
        listen       443 ssl;
        ssl_certificate /etc/letsencrypt/live/kigawa.net/fullchain.pem;
        ssl_certificate_key /etc/letsencrypt/live/kigawa.net/privkey.pem;

        location / {
            proxy_http_version 1.1;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Host $http_host;
            proxy_set_header X-Forwarded-Server $host;
            proxy_set_header X-Forwarded-Proto $scheme;
            proxy_set_header Host $host;
            proxy_set_header Upgrade $http_upgrade;
            proxy_set_header Connection $connection_upgrade;

            proxy_pass https://base.kigawa.net/;
        }
    }

    map $http_upgrade $connection_upgrade {
        default upgrade;
        ''      close;
    }
}

stream {
    include /etc/nginx/stream.conf.d/*.stream.conf;
}