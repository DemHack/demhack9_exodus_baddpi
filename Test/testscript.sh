#!/bin/sh

file=$(find -type f -name 'ipset[2-4]' -printf '%T+ %p\n' | sort | head -n 1 | awk '{print $2}')

echo "#Start update:" && $(date '+%Y-%m-%d %H:%M:%S') > $file

#after "@" adress of autorative ns-server or subnet (None)
until ADDRS=$(dig +short linux.org @9.9.9.11) && [ -n "$ADDRS" ] > /dev/null 2>&1; do sleep 5; done

while read -r line || [ -n "$line" ]; do

  [ -z "$line" ] && continue
  [ "${line:0:1}" = "#" ] && continue

  cidr=$(echo "$line" | grep -Eo '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}/[0-9]{1,2}')

  if [ -n "$cidr" ]; then
    echo "$cidr" >> $file
    continue
  fi

  range=$(echo "$line" | grep -Eo '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}-[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}')

  if [ -n "$range" ]; then
    echo "$range" >> $file
    continue
  fi

  addr=$(echo "$line" | grep -Eo '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}')

  if [ -n "$addr" ]; then
    echo "$addr" >> $file
    continue
  fi

  resaddr=$(dig +short "$line" @9.9.9.11 | grep -Eo '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}')
  echo -e "#$line\n$resaddr" >> $file

done < /etc/adv-routing/lists/fulllist.txt
