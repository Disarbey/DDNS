#!/bin/bash

# Get Current Internet IP
currentIP=$(curl -s http://www.zzsky.cn/code/ip/ip2.asp | grep -oE "([0-9]{1,3}\.){3}([0-9]{1,3})")

# Get Current DNS Records
currentDNSRecord=$(curl -s -G -d 'version=1' -d 'type=xml' -d 'key=' -d 'domain=' https://www.namesilo.com/api/dnsListRecords)

# check if the DNS Record exists
if test -n "$(echo $currentDNSRecord | grep -o 'naonas')"
then
echo [$(date)] DNS Record Exists, Do not need to be added. >> /var/log/DNS_Update.log
else
echo 'DNS Record Not Exists, Adding... ...'
curl -s -G -d 'version=1' -d 'type=xml' -d 'key=' -d 'domain=' -d 'rrtype=A' -d 'rrhost=' -d 'rrvalue='$currentIP'' -d 'rrttl=3603' https://www.namesilo.com/api/dnsAddRecord
echo [$(date)] Adding Successfully, currentIP is $currentIP. >> /var/log/DNS_Update.log
fi

# Check Is IP in the current DNS Records
index_param=2
tmp_DNSrecord=$(echo $currentDNSRecord | awk -F '<resource_record>' '{print $'$index_param'}')
# Check the Record till null
while test -n "$tmp_DNSrecord"
do
if test -n "$(echo $tmp_DNSrecord | grep -o '')";
then
# save the record_id
record_id=$(echo $tmp_DNSrecord | awk -F '<record_id>' '{print $2}' | awk -F '</record_id>' '{print $1}')
# check is the record IP same as the current IP, if not, update the record
if [ $currentIP == $(echo $tmp_DNSrecord | grep -oE "([0-9]{1,3}\.){3}([0-9]{1,3})") ];
then
echo [$(date)] Record IP is same to current IP, do not need to be updated. >> /var/log/DNS_Update.log
else
curl -s -G -d 'version=1' -d 'type=xml' -d 'key=' -d 'domain=' -d 'rrid='$record_id'' -d 'rrhost=' -d 'rrvalue='$currentIP'' -d 'rrttl=3603' https://www.namesilo.com/api/dnsUpdateRecord
echo [$(date)] The current DNS Record is updated to IP $currentIP. >> /var/log/DNS_Update.log
fi
fi
let "index_param += 1"
tmp_DNSrecord=$(echo $currentDNSRecord | awk -F '<resource_record>' '{print $'$index_param'}')
done
