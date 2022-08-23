#!/bin/bash

buatVariabelCode() {
  msg -bar "Pertanyaan"
  while [[ ${link} = "" ]]; do
    read -p "$(msg -ama "Domain/IP untuk code-server:") " link
    tput cuu1 && tput dl1
  done
  msg -ama "Domain/IP code server: $link"
  while [[ ${linkportNginx} = "" ]]; do
    read -p "$(msg -ama "Port untuk akses vs code:") " linkportNginx
    tput cuu1 && tput dl1
  done
  msg -ama "Port code server: $linkportNginx"
  while [[ ${passwordLogin} = "" ]]; do
    read -p "$(msg -ama "Password Login untuk akses vs code:") " passwordLogin
    tput cuu1 && tput dl1
  done
  pCode="1905"
  msg -ama "Port untuk code server: $passwordLogin"
}

cek_versi() {
  if [ "${EDGE-}" ]; then
    version="$(curl -fsSL https://api.github.com/repos/coder/code-server/releases | awk 'match($0,/.*"html_url": "(.*\/releases\/tag\/.*)".*/)' | head -n 1 | awk -F '"' '{print $4}')"
  else
    version="$(curl -fsSLI -o /dev/null -w "%{url_effective}" https://github.com/coder/code-server/releases/latest)"
  fi
  version="${version#https://github.com/coder/code-server/releases/tag/}"
  version="${version#v}"
  echo "$version"
}
cek_versi

arch() {
  uname_m=$(uname -m)
  case $uname_m in
  aarch64) echo arm64 ;;
  x86_64) echo amd64 ;;
  *) echo "$uname_m" ;;
  esac
}

os() {
  uname="$(uname)"
  case $uname in
  Linux) echo linux ;;
  Darwin) echo macos ;;
  FreeBSD) echo freebsd ;;
  *) echo "$uname" ;;
  esac
}

LinkValid() {
  archt=arch
  url=https://github.com/coder/code-server/releases/download/v$version/code-server_"$version"_$archt.deb
}

installCodeServer() {
  if [[ $(os) != 'linux' ]]; then
    msg -ama "Maaf os yang harus digunakan yaitu linux!"
    exit 1
  fi

  msg -bar "Tahap kedua"
  msg -ama "Download code server versi $version"
  wget https://github.com/coder/code-server/releases/download/v$version/code-server_"$version"_amd64.deb &>/dev/null
  msg -ama "Menginstall Code Server..."
  sudo dpkg -i code*.deb &>/dev/null
  while [[ ${yesHttps} != @(s|S|y|Y|n|N|t|T) ]]; do
    read -p "$(msg -ama "Apakah anda ingin menginstall Mode HTTPS (Y/T):") " yesHttps
    tput cuu1 && tput dl1
  done
  porthttp=$linkportNginx
  if [[ yesHttps = @(s|S|y|Y) ]]; then
    porthttp=80
  fi

  sudo echo """[Unit]
Description=code-server
After=nginx.service

[Service]
Type=simple
Environment=PASSWORD=$passwordLogin
ExecStart=/usr/bin/code-server --bind-addr 127.0.0.1:$pCode --user-data-dir /home --auth password
Restart=always

[Install]
WantedBy=multi-user.target
    """ >/lib/systemd/system/code-server.service
  msg -ama "Memulai code server..."
  systemctl start code-server &>/dev/null

  if [[ $(dpkg --get-selections | grep -w "apache2" | head -1) ]]; then
    msg -ama "Sedang menghentikan apache2..."
    service apache2 stop
  fi

  msg -ama "Menghidupkan code server secara otomatis..."
  systemctl enable code-server &>/dev/null

  msg -ama "Menyeting nginx untuk code server..."
  echo """server {
listen $porthttp;

server_name $link;

location / {
    proxy_pass http://localhost:$pCode/;
    proxy_set_header Upgrade \$http_upgrade;
    proxy_set_header Connection upgrade;
    proxy_set_header Accept-Encoding gzip;
    }
}
    """ >/etc/nginx/sites-available/code-server.conf
  rm /etc/nginx/sites-available/default /etc/nginx/sites-enabled/default &>/dev/null
  ln -s /etc/nginx/sites-available/code-server.conf /etc/nginx/sites-enabled/code-server.conf &>/dev/null
  nginx -t &>/dev/null
  msg -ama "Merestart nginx"
  systemctl restart nginx &>/dev/null
  rm code* &>/dev/null

  if [[ $yesHttps = @(s|S|y|Y) ]]; then
    httpsCode
  else
    msg -ama "Setup code server selesai"
    msg -ama "Silahkan buka localhost:$linkportNginx"
  fi
}

httpsCode() {
  msg -bar "Tahap Terakhir"
  msg -ne "Untuk menginstall ssl"
  msg -ne "Harus mempunyai domain!" && read enter
  tput cuu1 && tput dl1
  read -e -p "$(msg -ama "Domain untuk code-server:") " -i $link
  while [[ ${link} = "" ]]; do
    read -p "$(msg -ama "IP untuk code-server:") " link
    tput cuu1 && tput dl1
  done
  msg -ama "====== Menginstall Certbot ======"
  sudo apt install python3-certbot-nginx -y &>/dev/null

  msg -ama "Setelah ini akan menjadikan https"
  msg -ne "Enter untuk melanjutkan" && read enter
  tput cuu1 && tput dl1

  ######## install ssl untuk code server #####################
  sudo certbot --non-interactive --redirect --nginx -d $link --agree-tos -m admin@$link

  msg -ama "Sedang mengatur SSL - 2020 - Grade A+"
  echo """# This file contains important security parameters. If you modify this file
# manually, Certbot will be unable to automatically provide future security
# updates. Instead, Certbot will print and log an error message with a path to
# the up-to-date file that you will need to refer to when manually updating
# this file.
ssl_protocols TLSv1.2 TLSv1.3;# Requires nginx >= 1.13.0 else use TLSv1.2
ssl_prefer_server_ciphers on;
ssl_ciphers EECDH+AESGCM:EDH+AESGCM;
ssl_ecdh_curve secp384r1; # Requires nginx >= 1.1.0
ssl_session_timeout  10m;
ssl_stapling on; # Requires nginx >= 1.3.7
ssl_stapling_verify on; # Requires nginx => 1.3.7
resolver_timeout 5s;
ssl_session_cache shared:le_nginx_SSL:1m;
ssl_session_cache shared:SSL:10m;
ssl_session_tickets off;
resolver 1.1.1.1 1.0.0.1 valid=300s;

add_header Strict-Transport-Security \"max-age=31536000; includeSubDomains\" always;
add_header X-Frame-Options SAMEORIGIN;
add_header X-Content-Type-Options nosniff;
add_header X-Frame-Options DENY;
add_header X-XSS-Protection \"1; mode=block\";
    """ >/etc/letsencrypt/options-ssl-nginx.conf

  msg -ama "Mengatur port https di nginx"
  echo """server {
  listen $linkportNginx ssl http2;

  server_name $link;

  location / {
    proxy_pass http://localhost:$pCode/;
    proxy_set_header Upgrade \$http_upgrade;
    proxy_set_header Connection upgrade;
    proxy_set_header Accept-Encoding gzip;
  }

  ssl_certificate /etc/letsencrypt/live/$link/fullchain.pem; # managed by Certbot
  ssl_certificate_key /etc/letsencrypt/live/$link/privkey.pem; # managed by Certbot
  ssl_trusted_certificate /etc/letsencrypt/live/$link/chain.pem; # managed by Certbot
  include /etc/letsencrypt/options-ssl-nginx.conf; # managed by Certbot
  ssl_dhparam /etc/letsencrypt/ssl-dhparams.pem; # managed by Certbot
    }""" >/etc/nginx/sites-available/code-server.conf
  msg -ama "Mengatur SSL Selesai!"
  msg -ama "Sedang merestart Nginx"
  service nginx restart
  msg -ama "Merestart Selesai!"

  [[ $(dpkg --get-selections | grep -w "ufw" | head -1) ]] || (ufw allow $linkportNginx &>/dev/null)
}

buatVariabelCode
installCodeServer
