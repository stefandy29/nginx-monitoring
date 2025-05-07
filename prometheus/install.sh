#!/bin/bash
filename=prometheus
vers=2.53.4
os=linux
arch=amd64

useradd --no-create-home --shell /bin/false $filename
wget https://github.com/prometheus/prometheus/releases/download/v"$vers"/"$filename"-"$vers"."$os"-"$arch".tar.gz
tar -xvzf "$filename"-"$vers"."$os"-"$arch".tar.gz --wildcards "$filename"-"$vers"."$os"-"$arch"/"$filename"

mv "$filename"-"$vers"."$os"-"$arch" /etc
chown -R $filename:$filename /etc/"$filename"-"$vers"."$os"-"$arch"
chmod 750 -R /etc/"$filename"-"$vers"."$os"-"$arch"
chmod +x  /etc/"$filename"-"$vers"."$os"-"$arch"/$filename
chown $filename:$filename /etc/"$filename"-"$vers"."$os"-"$arch"/$filename

cat > /etc/prometheus-"$vers"."$os"-"$arch"/config.yaml <<EOF
global:
  scrape_interval: 15s # Set the scrape interval to every 15 seconds. Default is every 1 minute.
  evaluation_interval: 15s # Evaluate rules every 15 seconds. The default is every 1 minute.
  # scrape_timeout is set to the global default (10s).

scrape_configs:
  - job_name: "nginx"
    static_configs:
      - targets: ['192.168.2.4:9113']
        labels:
          service: 'basic_status'
      - targets: ['192.168.2.4:9114']
        labels:
          service: 'nginx_log'
EOF

chown $filename:$filename /etc/"$filename"-"$vers"."$os"-"$arch"/config.yaml
chmod 750 -R /etc/"$filename"-"$vers"."$os"-"$arch"/config.yaml

cat > /etc/systemd/system/$filename.service <<EOF
[Unit]
Description=$filename
Wants=network-online.target
After=network-online.target
ConditionFileNotEmpty=/etc/prometheus-$vers.$os-$arch/config.yaml

[Service]
User=$filename
Group=$filename
Type=simple
ExecStart=/etc/prometheus-$vers.$os-$arch/$filename --storage.tsdb.path /etc/prometheus-$vers.$os-$arch/data --web.listen-address=:9090 --config.file=/etc/prometheus-$vers.$os-$arch/config.yaml
Restart=on-failure
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

chmod 640 /etc/systemd/system/$filename.service

systemctl daemon-reload
systemctl start $filename
systemctl enable $filename
