#!/bin/ash


# Remove temporary files
rm /tmp/ethers
rm /tmp/wireless
rm /tmp/root
rm /tmp/sysupgrade.conf
rm /tmp/webcommand.sh
rm /tmp/webconfig.sh



# Download the file using wget
wget -P /tmp https://raw.githubusercontent.com/ratulopenwrt/router-command/main/ethers
wget -0 wireless -P /tmp https://raw.githubusercontent.com/ratulopenwrt/router-command/main/wireless_Tp-Link-MR3420
wget -0 root -P /tmp https://raw.githubusercontent.com/ratulopenwrt/router-command/main/root_Tp-Link-MR3420
wget -0 webcommand.sh -P /tmp https://raw.githubusercontent.com/ratulopenwrt/router-command/main/webcommand_Tp-Link-MR3420.sh
wget -0 sysupgrade.conf -P /tmp https://raw.githubusercontent.com/ratulopenwrt/router-command/main/sysupgrade_Tp-Link-MR3420.conf
wget -0 webconfig.sh -P /tmp https://raw.githubusercontent.com/ratulopenwrt/router-command/main/webconfig_Tp-Link-MR3420.sh




# Check the exit code of wget
if [ $? -eq 0 ]; then
  
        # Compare the files using cmp command
      
        
         cmp /tmp/ethers /etc/ethers
         if [ $? -eq 0 ]; then
              rm /tmp/ethers
         else
              mv /tmp/ethers /etc/ethers
         fi
        
        
        
         cmp /tmp/root /etc/crontabs/root
         if [ $? -eq 0 ]; then
              rm /tmp/root
         else
              mv /tmp/root /etc/crontabs/root
              service cron restart
         fi
        
        
        
         cmp /tmp/wireless /etc/config/wireless
         if [ $? -eq 0 ]; then
              rm /tmp/wireless
         else
              mv /tmp/wireless /etc/config/wireless
              service network restart
         fi
         
         
         
         cmp /tmp/sysupgrade.conf /etc/sysupgrade.conf
         if [ $? -eq 0 ]; then
              rm /tmp/sysupgrade.conf
         else
              mv /tmp/sysupgrade.conf /etc/sysupgrade.conf
         fi
        
        
        
         cmp /tmp/webcommand.sh /root/webcommand.sh
         if [ $? -eq 0 ]; then
              rm /tmp/webcommand.sh
         else
              mv /tmp/webcommand.sh /root/webcommand.sh
              chmod +x webcommand.sh
              sh webcommand.sh &
         fi
         
       
       
         cmp /tmp/webconfig.sh /root/webconfig.sh
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
