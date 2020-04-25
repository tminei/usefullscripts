#!/bin/bash
sudo apt -y install nginx
sudo apt -y update
sudo apt -y remove nginx* 
sudo apt install -y build-essential git tree
mkdir ~/nginx_install
cd ~/nginx_install
wget https://nginx.org/download/nginx-1.16.1.tar.gz && tar zxvf nginx-1.16.1.tar.gz
wget https://ftp.pcre.org/pub/pcre/pcre-8.40.tar.gz && tar xzvf pcre-8.40.tar.gz
wget http://www.zlib.net/zlib-1.2.11.tar.gz && tar xzvf zlib-1.2.11.tar.gz
wget https://www.openssl.org/source/openssl-1.1.0f.tar.gz && tar xzvf openssl-1.1.0f.tar.gz
rm -rf *.tar.gz
cd ~/nginx_install
git clone https://github.com/aileone/nginx-rtmp-module.git
cd ~/
sudo apt install -y perl libperl-dev libgd3 libgd-dev libgeoip1 libgeoip-dev geoip-bin libxml2 libxml2-dev libxslt1.1 libxslt1-dev
cd ~/nginx_install/nginx-1.16.1/

./configure --prefix=/usr/share/nginx \
            --sbin-path=/usr/sbin/nginx \
            --modules-path=/usr/lib/nginx/modules \
            --conf-path=/etc/nginx/nginx.conf \
            --error-log-path=/var/log/nginx/error.log \
            --http-log-path=/var/log/nginx/access.log \
            --pid-path=/run/nginx.pid \
            --lock-path=/var/lock/nginx.lock \
            --user=www-data \
            --group=www-data \
            --build=Ubuntu \
            --add-module=../nginx-rtmp-module \
            --with-http_ssl_module \
            --http-client-body-temp-path=/var/lib/nginx/body \
            --http-fastcgi-temp-path=/var/lib/nginx/fastcgi \
            --http-proxy-temp-path=/var/lib/nginx/proxy \
            --http-scgi-temp-path=/var/lib/nginx/scgi \
            --http-uwsgi-temp-path=/var/lib/nginx/uwsgi \
            --with-openssl=../openssl-1.1.0f \
            --with-openssl-opt=enable-ec_nistp_64_gcc_128 \
            --with-openssl-opt=no-nextprotoneg \
            --with-openssl-opt=no-weak-ssl-ciphers \
            --with-openssl-opt=no-ssl3 \
            --with-pcre=../pcre-8.40 \
            --with-pcre-jit \
            --with-zlib=../zlib-1.2.11 \
            --with-compat \
            --with-file-aio \
            --with-threads \
            --with-http_addition_module \
            --with-http_auth_request_module \
            --with-http_dav_module \
            --with-http_flv_module \
            --with-http_gunzip_module \
            --with-http_gzip_static_module \
            --with-http_mp4_module \
            --with-http_random_index_module \
            --with-http_realip_module \
            --with-http_slice_module \
            --with-http_ssl_module \
            --with-http_sub_module \
            --with-http_stub_status_module \
            --with-http_v2_module \
            --with-http_secure_link_module \
            --with-mail \
            --with-mail_ssl_module \
            --with-stream \
            --with-stream_realip_module \
            --with-stream_ssl_module \
            --with-stream_ssl_preread_module \
            --with-debug
make -j4
sudo make install
cd ~
sudo ln -s /usr/lib/nginx/modules /etc/nginx/modules
sudo nginx -V
sudo adduser --system --home /nonexistent --shell /bin/false --no-create-home --disabled-login --disabled-password --gecos "nginx user" --group nginx
sudo nginx -t

sudo mkdir -p /var/cache/nginx/client_temp /var/cache/nginx/fastcgi_temp /var/cache/nginx/proxy_temp /var/cache/nginx/scgi_temp /var/cache/nginx/uwsgi_temp /var/lib/nginx
sudo chmod 700 /var/cache/nginx/* /var/lib/nginx/
sudo chown nginx:root /var/cache/nginx/*

sudo nginx -t
sudo echo "[Unit]
Description=nginx - high performance web server
Documentation=https://nginx.org/en/docs/
After=network-online.target remote-fs.target nss-lookup.target
Wants=network-online.target
[Service]
Type=forking
PIDFile=/var/run/nginx.pid
ExecStartPre=/usr/sbin/nginx -t -c /etc/nginx/nginx.conf
ExecStart=/usr/sbin/nginx -c /etc/nginx/nginx.conf
ExecReload=/bin/kill -s HUP $MAINPID
ExecStop=/bin/kill -s TERM $MAINPID
[Install]
WantedBy=multi-user.target" > /etc/systemd/system/nginx.service

sudo systemctl enable nginx.service
sudo systemctl start nginx.service
sudo systemctl is-enabled nginx.servicesfd

sudo apt -y install software-properties-common && sudo add-apt-repository -y ppa:ondrej/php && sudo apt-get update
sudo apt -y install php7.1 php7.1-cli php7.1-common php7.1-json php7.1-opcache php7.1-mysql php7.1-mbstring php7.1-mcrypt php7.1-zip php7.1-fpm

sudo echo "cgi.fix_pathinfo=0" >> /etc/php/7.1/fpm/php.ini
sudo systemctl restart php7.1-fpm
touch /etc/nginx/sites-available/default

sudo sh -c "echo 'user www-data;
worker_processes auto;
pid /run/nginx.pid;

rtmp_auto_push on;

rtmp {
    live on;
    server {
        listen 1935;
        application live {
        live on;
        }
        application hls {
            live on;
            hls on;
            hls_fragment 5s;
            hls_path /tmp;
        }
        }
}

events {
	worker_connections 768;
	# multi_accept on;
}

http {

	##
	# Basic Settings
	##

	sendfile on;
	tcp_nopush on;
	tcp_nodelay on;
	keepalive_timeout 65;
	types_hash_max_size 2048;
	# server_tokens off;

	# server_names_hash_bucket_size 64;
	# server_name_in_redirect off;

	include /etc/nginx/mime.types;
	default_type application/octet-stream;

	##
	# SSL Settings
	##

	ssl_protocols TLSv1 TLSv1.1 TLSv1.2; # Dropping SSLv3, ref: POODLE
	ssl_prefer_server_ciphers on;

	##
	# Logging Settings
	##

	access_log /var/log/nginx/access.log;
	error_log /var/log/nginx/error.log;

	##
	# Gzip Settings
	##
        
	gzip on;
	gzip_disable "msie6";

	# gzip_vary on;
	# gzip_proxied any;
	# gzip_comp_level 6;
	# gzip_buffers 16 8k;
	# gzip_http_version 1.1;
	# gzip_types text/plain text/css application/json application/javascript text/xml application/xml application/xml+rss text/javascript;

	##
	# Virtual Host Configs
	##

	include /etc/nginx/conf.d/*.conf;
	include /etc/nginx/sites-enabled/*;

}' > /etc/nginx/nginx.conf"

sudo mkdir /etc/nginx/sites-available/
sudo touch /etc/nginx/sites-available/default
sudo sh -c "echo 'server {
	listen 80;
	root /var/www/html;
	index index.php index.html;

	server_name _;

    location /hls {
        root /mnt/ramdisk;
    }
   
    location / {
		try_files $uri $uri/ =404;
	}

	location ~ \.php$ {
		include snippets/fastcgi-php.conf;
		fastcgi_pass unix:/run/php/php7.1-fpm.sock;
	}

	location ~ /\.ht {
		deny all;
	}
}' > /etc/nginx/sites-available/default"
sudo mkdir /etc/nginx/sites-enabled/
sudo ln -s /etc/nginx/sites-available/default /etc/nginx/sites-enabled/
sudo service nginx restart
sudo rm -rf ~/nginx_install/
