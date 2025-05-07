#!/bin/bash
filename=prometheus-nginxlog-exporter
vers=1.11.0
os=linux
arch=amd64

wget https://github.com/martin-helmich/prometheus-nginxlog-exporter/releases/download/v"$vers"/"$filename"_"$vers"_"$os"_"$arch".tar.gz

tar -xvzf "$filename"_"$vers"_"$os"_"$arch".tar.gz --wildcards "$filename"

chmod +x $filename
mv $filename /usr/local/bin

chown root:root /usr/local/bin/$filename

mkdir -p /etc/$filename
chown -R root:root /etc/$filename
chmod 750 -R /etc/$filename

cat > /etc/$filename/config.yaml <<EOF
listen:
  port: 9114
  address: "0.0.0.0"
  metrics_endpoint: "/metrics"

namespaces:
  - name: nginx
    format: $(printf "%s" '"$remote_addr - $remote_user [$time_local] \"$request\" $status $body_bytes_sent \"$http_referer\" \"$http_user_agent\" \"$http_x_forwarded_for\" $upstream_connect_time $upstream_header_time $upstream_response_time $request_time"')
    source:
      files:
        - /var/log/nginx/access.log
EOF

chown root:root /etc/$filename/config.yaml
chmod 750 -R /etc/$filename

cat > /etc/systemd/system/$filename.service <<EOF
[Unit]
Description=$filename
Wants=network-online.target
After=network-online.target
ConditionFileNotEmpty=/etc/$filename/config.yaml

[Service]
User=root
Group=root
Type=simple
ExecStart=/usr/local/bin/$filename -config-file=/etc/$filename/config.yaml
Restart=on-failure
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

chmod 640 /etc/systemd/system/$filename.service

systemctl daemon-reload
systemctl start $filename
systemctl enable $filename
