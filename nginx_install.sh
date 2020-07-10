#!/bin/bash

# delete old nginx
sudo apt remove -y nginx

# download and unzip nginx 1.18.0, PCRE 8.42, zlib 1.2.11, OpenSSL 1.1.0h
wget https://nginx.org/download/nginx-1.18.0.tar.gz && tar zxvf nginx-1.18.0.tar.gz
wget https://www.zlib.net/zlib-1.2.11.tar.gz && tar xzvf zlib-1.2.11.tar.gz
wget https://www.openssl.org/source/openssl-1.1.0h.tar.gz && tar xzvf openssl-1.1.0h.tar.gz
rm -rf *.tar.gz

# download nginx-rtmp
cd ~ && git clone https://github.com/arut/nginx-rtmp-module.git

# install build tools and dependencies
sudo apt install -y build-essential git tree nginx
sudo add-apt-repository -y ppa:maxmind/ppa
sudo apt update && sudo apt upgrade -y
sudo apt install -y perl libperl-dev libgd3 libgd-dev libgeoip1 libgeoip-dev geoip-bin libxml2 libxml2-dev libxslt1.1 libxslt1-dev

# configure installation
cd ~/nginx-1.18.0
./configure --prefix=/etc/nginx \
--sbin-path=/usr/sbin/nginx \
--modules-path=/usr/lib/nginx/modules \
--conf-path=/etc/nginx/nginx.conf \
--error-log-path=/var/log/nginx/error.log \
--pid-path=/var/run/nginx.pid \
--lock-path=/var/run/nginx.lock \
--add-module=../nginx-rtmp-module \
--user=nginx \
--group=nginx \
--build=Ubuntu \
--builddir=nginx-1.18.0 \
--with-select_module \
--with-poll_module \
--with-threads \
--with-file-aio \
--with-http_ssl_module \
--with-http_v2_module \
--with-http_realip_module \
--with-http_addition_module \
--with-http_xslt_module=dynamic \
--with-http_image_filter_module=dynamic \
--with-http_geoip_module=dynamic \
--with-http_sub_module \
--with-http_dav_module \
--with-http_flv_module \
--with-http_mp4_module \
--with-http_gunzip_module \
--with-http_gzip_static_module \
--with-http_auth_request_module \
--with-http_random_index_module \
--with-http_secure_link_module \
--with-http_degradation_module \
--with-http_slice_module \
--with-http_stub_status_module \
--with-http_perl_module=dynamic \
--with-perl_modules_path=/usr/share/perl/5.26.1 \
--with-perl=/usr/bin/perl \
--http-log-path=/var/log/nginx/access.log \
--http-client-body-temp-path=/var/cache/nginx/client_temp \
--http-proxy-temp-path=/var/cache/nginx/proxy_temp \
--http-fastcgi-temp-path=/var/cache/nginx/fastcgi_temp\
--http-uwsgi-temp-path=/var/cache/nginx/uwsgi_temp \
--http-scgi-temp-path=/var/cache/nginx/scgi_temp \
--with-mail=dynamic \
--with-mail_ssl_module \
--with-stream=dynamic \
--with-stream_ssl_module \
--with-stream_realip_module \
--with-stream_geoip_module=dynamic \
--with-stream_ssl_preread_module \
--with-compat \
--with-pcre=../pcre-8.42 \
--with-pcre-jit \
--with-zlib=../zlib-1.2.11 \
--with-openssl=../openssl-1.1.0h \
--with-openssl-opt=no-nextprotoneg \
--with-debug
--with-cc-opt="-Wimplicit-fallthrough=0 -Werror=implicit-fallthrough="

# build 
make -j4
sudo make install

# configure after build
cd ~
sudo ln -s /usr/lib/nginx/modules /etc/nginx/modules
sudo adduser --system --home /nonexistent --shell /bin/false --no-create-home --disabled-login --disabled-password --gecos "nginx user" --group nginx
sudo mkdir -p /var/cache/nginx/client_temp /var/cache/nginx/fastcgi_temp /var/cache/nginx/proxy_temp /var/cache/nginx/scgi_temp /var/cache/nginx/uwsgi_temp
sudo chmod 700 /var/cache/nginx/*
sudo chown nginx:root /var/cache/nginx/*
sudo chown -R www-data:www-data /var/lib/nginx
sudo cat > /etc/systemd/system/nginx.service <<END
[Unit]
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
WantedBy=multi-user.target
END
sudo systemctl enable nginx.service
sudo systemctl start nginx.service

# php 7.4 install
sudo apt -y install software-properties-common && sudo add-apt-repository -y ppa:ondrej/php && sudo apt-get update
sudo apt -y install php7.4 php7.4-cli php7.4-common php7.4-json php7.4-opcache php7.4-mysql php7.4-mbstring php7.4-zip php7.4-fpm
sudo cat >> /etc/php/7.4/fpm/php.ini <<END
cgi.fix_pathinfo=0
END
sudo systemctl restart php7.4-fpm

# Configure nginx to work with php
touch /etc/nginx/sites-available/default
sudo mv /etc/nginx/nginx.conf /etc/nginx/nginx.conf.autobak
sudo cat > /etc/nginx/nginx.conf <<END
user www-data;
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
	sendfile on;
	tcp_nopush on;
	tcp_nodelay on;
	keepalive_timeout 65;
	types_hash_max_size 2048;
	include /etc/nginx/mime.types;
	default_type application/octet-stream;
	ssl_protocols TLSv1 TLSv1.1 TLSv1.2; # Dropping SSLv3, ref: POODLE
	ssl_prefer_server_ciphers on;
	access_log /var/log/nginx/access.log;
	error_log /var/log/nginx/error.log;
	gzip on;
	gzip_disable "msie6";
	include /etc/nginx/conf.d/*.conf;
	include /etc/nginx/sites-enabled/*;

}
END
sudo mkdir /etc/nginx/sites-available/
sudo touch /etc/nginx/sites-available/default
sudo mv /etc/nginx/sites-available/default /etc/nginx/sites-available/default.autobak
sudo cat > /etc/nginx/sites-available/default <<END
server {
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
		fastcgi_pass unix:/run/php/php7.4-fpm.sock;
	}

	location ~ /\.ht {
		deny all;
	}
}
END
sudo mkdir /etc/nginx/sites-enabled/
sudo ln -s /etc/nginx/sites-available/default /etc/nginx/sites-enabled/
sudo service nginx restart

