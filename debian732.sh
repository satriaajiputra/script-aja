#!/bin/bash

if [[ $USER != 'root' ]]; then
	echo "Sorry.. Need root access for launch this script."
	exit
fi

# initialisasi var
export DEBIAN_FRONTEND=noninteractive
OS=`uname -m`;
MYIP=$(wget -qO- ipv4.icanhazip.com);
MYIP2="s/xxxxxxxxx/$MYIP/g";
ether=`ifconfig | cut -c 1-8 | sort | uniq -u | grep venet0 | grep -v venet0:`
if [ "$ether" = "" ]; then
        ether=eth0
fi

# go to root
cd

# disable ipv6
echo 1 > /proc/sys/net/ipv6/conf/all/disable_ipv6
sed -i '$ i\echo 1 > /proc/sys/net/ipv6/conf/all/disable_ipv6' /etc/rc.local

# install wget and curl
apt-get update;apt-get -y install wget curl;

sed -i 's/AcceptEnv/#AcceptEnv/g' /etc/ssh/sshd_config
service ssh restart

# remove unused
apt-get -y --purge remove samba*;
apt-get -y --purge remove apache2*;
apt-get -y --purge remove sendmail*;
apt-get -y --purge remove bind9*;
#apt-get -y autoremove;

# update
apt-get update;apt-get -y upgrade;

apt-get -y install bmon iftop htop nmap axel nano iptables traceroute sysv-rc-conf dnsutils bc nethogs vnstat less screen psmisc apt-file whois ptunnel ngrep mtr git zsh snmp snmpd snmp-mibs-downloader unzip unrar rsyslog debsums rkhunter
apt-get -y install build-essential

# disable exim
service exim4 stop
sysv-rc-conf exim4 off

# update apt-file
apt-file update

# setting vnstat
vnstat -u -i $ether
service vnstat restart

# install screenfetch
cd
wget 'https://raw.githubusercontent.com/KittyKatt/screenFetch/master/screenfetch-dev'
mv screenfetch-dev /usr/bin/screenfetch
chmod +x /usr/bin/screenfetch
echo "clear" >> .profile
echo "screenfetch" >> .profile
cd

# setting port ssh
sed -i 's/Port 22/Port 22/g' /etc/ssh/sshd_config
#sed -i '/Port 22/a Port 80' /etc/ssh/sshd_config
sed -i '/Port 22/a Port 143' /etc/ssh/sshd_config
sed -i 's/#Banner/Banner/g' /etc/ssh/sshd_config
service ssh restart

# install dropbear
#apt-get -y update
apt-get -y install dropbear
sed -i 's/NO_START=1/NO_START=0/g' /etc/default/dropbear
sed -i 's/DROPBEAR_PORT=22/DROPBEAR_PORT=443/g' /etc/default/dropbear
sed -i 's/DROPBEAR_EXTRA_ARGS=/DROPBEAR_EXTRA_ARGS="-p 109 -p 110"/g' /etc/default/dropbear
echo "/bin/false" >> /etc/shells
echo "/usr/sbin/nologin" >> /etc/shells
service ssh restart
service dropbear restart

# upgrade dropbear 2014
apt-get install zlib1g-dev
wget http://anekascript.anekavps.us:81/Dropbear/dropbear-2014.66.tar.bz2
bzip2 -cd dropbear-2014.66.tar.bz2  | tar xvf -
cd dropbear-2014.66
./configure
make && make install
mv /usr/sbin/dropbear /usr/sbin/dropbear1
ln /usr/local/sbin/dropbear /usr/sbin/dropbear
service dropbear restart

# install fail2ban
apt-get -y install fail2ban;service fail2ban restart;

# encrypted script
wget -O /usr/bin/user-expire "https://raw.githubusercontent.com/satriaajiputra/debian7os/master/userexpired.sh"
wget -O /usr/bin/user-limit "http://anekascript.anekavps.us:81/Debian7/user-limit.sh"
chmod +x /usr/bin/user-expire
chmod +x /usr/bin/user-limit

echo "00 1 * * * root /usr/bin/user-expire" > /etc/cron.d/user-expire
#echo "@reboot root /usr/bin/user-limit" > /etc/cron.d/user-limit
echo "0 */12 * * * root /sbin/reboot" > /etc/cron.d/reboot
echo "* * * * * root service dropbear restart" > /etc/cron.d/dropbear
#echo "@reboot root /usr/bin/autokill" > /etc/cron.d/autokill
#sed -i '$ i\screen -AmdS check /root/autokill' /etc/rc.local

# finishing
chown -R www-data:www-data /home/vps/public_html
service cron restart
service vnstat restart
service snmpd restart
service ssh restart
service dropbear restart
service fail2ban restart
cd
rm -f /root/.bash_history && history -c
echo "unset HISTFILE" >> /etc/profile

# info
clear
echo "Autoscript Include:" | tee log-install.txt
echo "=======================================================" | tee -a log-install.txt
echo "Service :" | tee -a log-install.txt
echo "---------" | tee -a log-install.txt
echo "OpenSSH  : 22, 143" | tee -a log-install.txt
echo "Dropbear : 443, 110, 109" | tee -a log-install.txt
echo "" | tee -a log-install.txt
echo "Tools :" | tee -a log-install.txt
echo "-------" | tee -a log-install.txt
echo "axel, bmon, htop, iftop, mtr, rkhunter, nethogs: nethogs $ether" | tee -a log-install.txt
echo "" | tee -a log-install.txt
echo "Script :" | tee -a log-install.txt
echo "--------" | tee -a log-install.txt
echo "screenfetch" | tee -a log-install.txt
echo "" | tee -a log-install.txt
echo "Other feature :" | tee -a log-install.txt
echo "------------" | tee -a log-install.txt
echo "Fail2Ban : [on]" | tee -a log-install.txt
echo "IPv6     : [off]" | tee -a log-install.txt
#echo "Autolimit 2 bitvise per IP to all port (port 22, 143, 109, 110, 443, 1194, 7300 TCP/UDP)" | tee -a log-install.txt
echo "Auto Lock User Expire every 00:00 hours" | tee -a log-install.txt
echo "VPS AUTO REBOOT EVERY 12 HOURS" | tee -a log-install.txt
echo "Log --> /root/log-install.txt" | tee -a log-install.txt
echo "Reboot your vps now using command : reboot !" | tee -a log-install.txt
echo "=======================================================" | tee -a log-install.txt
cd ~/
rm -f /root/debian7.sh
rm -f /root/dropbear-2014.66.tar.bz2
rm -rf /root/dropbear-2014.66
