#!/bin/bash

# Edit these
EMAIL="you@example.com"
KEY="1SuperSecretToken"
ZONE="example.com"
DOMAIN="dyndns.example.com"

# Don't edit these
API="https://api.cloudflare.com/client/v4"
CRED=(-H "X-Auth-Email: $EMAIL" -H "X-Auth-Key: $KEY" -H "Content-Type: application/json")
SEARCH="&status=active&page=1&per_page=20&order=status&direction=desc&match=all"

getjson() {
  jqf="$1"
  shift
  res=$(curl --silent "$@")
  if echo "$res" | jq ".success" | grep false > /dev/null; then
    echo "Request not successfull!"
    echo "$res"
    exit 2
  fi
  echo "$res" | jq -c "$jqf" | sed 's|"||g' | sed -r "s|\[\|\]||g"
}

updateDomain() {
  T="$1"
  IP="$2"
  echo "Updating $T records for $DOMAIN to $IP..."
  for domain in $domains; do
    if echo "$domain" | grep ",$T$" > /dev/null; then
      dm=${domain/",$T"/}
      echo "Update $dm"
      getjson ".success" -X PUT "$API/zones/$zoneid/dns_records/$dm" "${CRED[@]}" --data '{"type":"'$T'","name":"'$DOMAIN'","content":"'$IP'","ttl":120,"proxied":false}'
    fi
  done
}

zoneid=$(getjson ".result[0].id" -X GET "$API/zones?name=$ZONE$SEARCH" "${CRED[@]}")
[ -z "$zoneid" ] && echo "Zone not found or not authorized!" && exit 2
echo "Zone detected as $zoneid"
domains=$(getjson ".result[] | [.id, .type]" -X GET "$API/zones/$zoneid/dns_records?name=$DOMAIN$SEARCH" "${CRED[@]}")
[ -z "$zoneid" ] && echo "Domain not found or not authorized!" && exit 2

IP4=$(dig +short myip.opendns.com A    @208.67.222.222)
IP6=$(dig +short myip.opendns.com AAAA @2620:0:ccc::2)

if [ ! -z "$IP4" ]; then
  updateDomain "A" "$IP4"
fi

if [ ! -z "$IP6" ]; then
  updateDomain "AAAA" "$IP6"
fi

