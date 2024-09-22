#! /bin/sh
ip tuntap add dev tun0 mode tun user admin

ip a add 10.0.0.1/24 dev tun0
ip a add fe21::4324:4323:eeda:2/127 dev tun0
ip link set dev tun0 up
ip r a 88.88.88.248 via 43.22.100.1
systemctl start ss-client
systemctl start tun2socks
ip r a default via 10.0.0.2 metric 10

bash -x ./0ipset.sh start

bash -x ./update.sh
