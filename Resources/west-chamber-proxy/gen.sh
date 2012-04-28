ip=${1-74.125.71.0}
locallog=${ip}.nmap16s.log
remotelog=${ip}.nmap16s.remote.log

sudo nmap -sT -p80 "$ip"/24 --host-timeout 16s --log-errors > $locallog
ssh liruqi@asuwish.cc "sudo nmap -sT -p80 $ip/24 --host-timeout 16s --log-errors" > $remotelog

ip_prefix=${ip:0:8}
cat $locallog | grep "$ip_prefix" | awk -v ip_prefix="$ip_prefix" '{
    if (index($5, ip_prefix) > 0) print $5;
    else print substr($6, 2, length($6)-2);
}' > ${ip}.availiplist.log

cat $remotelog | grep "$ip_prefix" | awk -v ip_prefix="$ip_prefix" '{
    if (index($4, ip_prefix) > 0) print substr($4, 1, length($4)-1);
    else print substr($5, 2, length($5)-3);
}' > ${ip}.alliplist.log

diff ${ip}.availiplist.log ${ip}.alliplist.log | grep "^>" | awk '{print $2}'
