#!/bin/bash

#
# these pre-req are specific elastic-search-7.0
#

URUSER=xyz #by default its "elasticsearch", but can be changed to normal user as well

echo " Step-1 : Set sysctl.conf values "

cp /etc/sysctl.conf /etc/sysctl.conf-bkp.`date +"%m_%d_%Y"`

echo Current value of `sysctl -a | grep vm.max_map_count`
echo Current value of `sysctl -a | grep vm.swappiness`

CURNT_MAX_MAP_CNT=`sysctl -a | grep vm.max_map_count | awk '{ print $3 }'`
CURNT_SWAPPINESS=`sysctl -a | grep vm.swappiness | awk '{ print $3 }'`

if [ $CURNT_MAX_MAP_CNT -lt 262144 ]
then
  sysctl -w vm.max_map_count=262144
  echo "vm.max_map_count = 262144" >> /etc/sysctl.conf;sysctl -p
else
  echo "Current "vm.max_map_count" value $CURNT_MAX_MAP_CNT is greater than 262144"
fi

if [ $CURNT_SWAPPINESS -gt 1 ]
then
  sysctl -w vm.swappiness=262144
  echo "vm.swappiness = 262144" >> /etc/sysctl.conf;sysctl -p
else
  echo "Current "vm.swappiness" value $CURNT_SWAPPINESS is greater than 1"
fi

echo " Step-2 : Set limits.conf values "

cp /etc/security/limits.conf /etc/security/limits.conf-bkp.`date +"%m_%d_%Y"`
cat /etc/security/limits.conf | egrep -i '$URUSER'
echo "$URUSER soft nofile 65536" >> /etc/security/limits.conf
echo "$URUSER hard nofile 65536" >> /etc/security/limits.conf
echo "$URUSER soft nproc 4096" >> /etc/security/limits.conf
echo "$URUSER hard nproc 4096" >> /etc/security/limits.conf

echo " Step-3 : swap off "

cp /etc/fstab /etc/fstab-bkp.`date +"%m_%d_%Y"`
swapoff -a
sed -i '/[^#]/ s/\(^.*lv_swap.*$\)/#disabled-4-elk#\ \1/' /etc/fstab # command to add comment in FSTAB
