#!/bin/bash
filename=nginx-prometheus-exporter
vers=1.4.2
os=linux
arch=amd64
basic_status=http://localhost/nginx_status

useradd --no-create-home --shell /bin/false $filename
wget https://github.com/nginx/nginx-prometheus-exporter/releases/download/v"$vers"/"$filename"_"$vers"_"$os"_"$arch".tar.gz

tar -xvzf "$filename"_"$vers"_"$os"_"$arch".tar.gz --wildcards "$filename"

chmod +x $filename
mv $filename /usr/local/bin

chown $filename:$filename /usr/local/bin/$filename

cat > /etc/systemd/system/$filename.service <<EOF
[Unit]
Description=$filename
Wants=network-online.target
After=network-online.target

[Service]
User=$filename
Group=$filename
Type=simple
ExecStart=/usr/local/bin/$filename --web.listen-address=:9113 --nginx.scrape-uri=$basic_status
Restart=on-failure
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

chmod 640 /etc/systemd/system/$filename.service

systemctl daemon-reload
systemctl start $filename
systemctl enable $filename
