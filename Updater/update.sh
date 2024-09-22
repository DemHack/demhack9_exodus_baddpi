#!/bin/sh
file=$(find -type f -name 'ipset[2-4]' -printf '%T+ %p\n' | sort -r | head -n 1 | awk '{print $2}')
while read -r line || [ -n "$line" ]; do
  [ -z "$line" ] && continue
  [ "${line:0:1}" = "#" ] && continue

  cidr=$(echo "$line" | grep -Eo '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}/[0-9]{1,2}')

  if [ -n "$cidr" ]; then
    echo "$cidr" | awk '{system("ip r a "$1" via 10.0.0.2 dev tun0 metric 20")}'
    continue
  fi

  echo "$line" | grep -Eo '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.' | awk '{system("ip r a "$1"0/24 via 10.0.0.2 dev tun0 metric 20")}'
done < $file 

systemctl restart dnsmasq
sleep 10
systemctl restart networking
sleep 10
systemctl restart ss-client tun2socks
sleep 10
systemctl restart systemd-resolved
sleep 60
bash -x ./2unblock.ipset.sh
ipset list
