#!/bin/ash


# Remove temporary files
rm /tmp/ethers
rm /tmp/wireless
rm /tmp/firewall
rm /tmp/root
rm /tmp/sysupgrade.conf
rm /tmp/webcommand.sh
rm /tmp/webconfig.sh



# Download the file using wget
wget -P /tmp https://raw.githubusercontent.com/ratulopenwrt/router-command/main/ethers
wget -P /tmp https://raw.githubusercontent.com/ratulopenwrt/router-command/main/firewall
wget -P /tmp https://raw.githubusercontent.com/ratulopenwrt/router-command/main/wireless
wget -P /tmp https://raw.githubusercontent.com/ratulopenwrt/router-command/main/root
wget -P /tmp https://raw.githubusercontent.com/ratulopenwrt/router-command/main/webcommand.sh
wget -P /tmp https://raw.githubusercontent.com/ratulopenwrt/router-command/main/sysupgrade.conf
wget -P /tmp https://raw.githubusercontent.com/ratulopenwrt/router-command/main/webconfig.sh




# Check the exit code of wget
if [ $? -eq 0 ]; then
  
        # Compare the files using diff command
        
         diff -q /tmp/firewall /etc/config/firewall
         if [ $? -eq 0 ]; then
              rm /tmp/firewall
         else
              mv /tmp/firewall /etc/config/firewall
              service firewall restart
         fi
        
        
        
         diff -q /tmp/ethers /etc/ethers
         if [ $? -eq 0 ]; then
              rm /tmp/ethers
         else
              mv /tmp/ethers /etc/ethers
         fi
        
        
        
         diff -q /tmp/root /etc/crontabs/root
         if [ $? -eq 0 ]; then
              rm /tmp/root
         else
              mv /tmp/root /etc/crontabs/root
              service cron restart
         fi
        
        
        
         diff -q /tmp/wireless /etc/config/wireless
         if [ $? -eq 0 ]; then
              rm /tmp/wireless
         else
              mv /tmp/wireless /etc/config/wireless
              /sbin/wifi reconf
              /etc/init.d/wpad reload
              /etc/init.d/wpad restart
         fi
         
         
         
         diff -q /tmp/sysupgrade.conf /etc/sysupgrade.conf
         if [ $? -eq 0 ]; then
              rm /tmp/sysupgrade.conf
         else
              mv /tmp/sysupgrade.conf /etc/sysupgrade.conf
         fi
        
        
        
         diff -q /tmp/webcommand.sh /root/webcommand.sh
         if [ $? -eq 0 ]; then
              rm /tmp/webcommand.sh
         else
              mv /tmp/webcommand.sh /root/webcommand.sh
              chmod +x webcommand.sh
              sh webcommand.sh &
         fi
         
       
       
         diff -q /tmp/webconfig.sh /root/webconfig.sh
         if [ $? -eq 0 ]; then
              rm /tmp/webconfig.sh
         else
              mv /tmp/webconfig.sh /root/webconfig.sh
              chmod +x webconfig.sh
         fi
         
         
         exit 1
         
         
else
   echo "Download failed!"
   exit 1
   
fi   
