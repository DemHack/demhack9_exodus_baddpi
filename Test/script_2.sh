#!/bin/bash

DOMAINS_FILE="testdomains.txt"
OUTPUT_FILE="ping_results.csv"

if [[ ! -f "$DOMAINS_FILE" ]]; then
  echo "Файл $DOMAINS_FILE не найден!"
  exit 1
fi

echo "domain;ping(ms)" > "$OUTPUT_FILE"

while IFS= read -r domain; do
  ping_result=$(ping -c 1 "$domain" | grep 'time=' | awk -F'time=' '{print $2}' | awk '{print $1}')
  
  if [[ -z "$ping_result" ]]; then
    ping_result="N/A"
  fi

  echo "$domain;$ping_result" >> "$OUTPUT_FILE"
done < "$DOMAINS_FILE"

echo "Пингование завершено. Результаты сохранены в $OUTPUT_FILE."
