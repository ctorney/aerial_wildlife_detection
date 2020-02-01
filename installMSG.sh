

# define RabbitMQ access credentials. NOTE: replace defaults with your own values
username=aide
password=password

# install RabbitMQ server
sudo apt-get update && sudo apt-get install -y rabbitmq-server

# start RabbitMQ server
sudo systemctl enable rabbitmq-server.service
sudo service rabbitmq-server start

# add the user we defined above
sudo rabbitmqctl add_user $username $password

# add new virtual host
sudo rabbitmqctl add_vhost aide_vhost

# set permissions
sudo rabbitmqctl set_permissions -p aide_vhost $username ".*" ".*" ".*"

# restart
sudo service rabbitmq-server stop       # may take a minute; if the command hangs: sudo pkill -KILL -u rabbitmq
sudo service rabbitmq-server start


sudo apt-get update && sudo apt-get install redis-server

# make sure Redis stores its messages in an accessible folder (we're using /var/lib/redis/aide.rdb here)
sudo sed -i "s/^\s*dir\s*.*/dir \/var\/lib\/redis/g" /etc/redis/redis.conf
sudo sed -i "s/^\s*dbfilename\s*.*/dbfilename aide.rdb/g" /etc/redis/redis.conf

# also tell systemd
sudo mkdir -p /etc/systemd/system/redis.service.d
echo -e "[Service]\nReadWriteDirectories=-/var/lib/redis" | sudo tee -a /etc/systemd/system/redis.service.d/override.conf > /dev/null

sudo mkdir -p /var/lib/redis
sudo chown -R redis:redis /var/lib/redis

# disable persistence. In general, we don't need Redis to save snapshots as it is only used as a result
# (and therefore message) backend.
sudo sed -i "s/^\s*save/# save /g" /etc/redis/redis.conf


# restart
sudo systemctl daemon-reload
sudo systemctl enable redis-server.service
sudo systemctl restart redis-server.service


if ! sudo grep -q ^net.ipv4.tcp_keepalive_* /etc/sysctl.conf ; then
    echo "net.ipv4.tcp_keepalive_time = 60" | sudo tee -a "/etc/sysctl.conf" > /dev/null
    echo "net.ipv4.tcp_keepalive_intvl = 60" | sudo tee -a "/etc/sysctl.conf" > /dev/null
    echo "net.ipv4.tcp_keepalive_probes = 20" | sudo tee -a "/etc/sysctl.conf" > /dev/null
else
    sudo sed -i "s/^\s*net.ipv4.tcp_keepalive_time.*/net.ipv4.tcp_keepalive_time = 60 /g" /etc/sysctl.conf
    sudo sed -i "s/^\s*net.ipv4.tcp_keepalive_intvl.*/net.ipv4.tcp_keepalive_intvl = 60 /g" /etc/sysctl.conf
    sudo sed -i "s/^\s*net.ipv4.tcp_keepalive_probes.*/net.ipv4.tcp_keepalive_probes = 20 /g" /etc/sysctl.conf
fi
sudo sysctl -p
