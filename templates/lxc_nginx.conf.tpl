worker_processes  auto;
worker_rlimit_nofile  100000;

events {
    worker_connections  1024;
    multi_accept on;
}

stream {
    include /etc/nginx/stream.conf.d/*.stream.conf;
}