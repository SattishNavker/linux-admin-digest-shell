#!/usr/bin/ksh
LOCATION=""
LOCALHOSTNAME=`hostname`
NSLOOKUP="/usr/bin/nslookup"
VXDCTL="/usr/sbin/vxdctl"
VXDISK="/usr/sbin/vxdisk"
VXPRINT="/usr/sbin/vxprint"
VXDG="/usr/sbin/vxdg"
VXEDIT="/usr/sbin/vxedit"
#PROD_NODE=$LOCALHOSTNAME
SSH="/usr/bin/ssh"
HAGRP="/opt/VRTS/bin/hagrp"
SE_UTILITIES="/usr/symcli/bin/"
YEST_DEVICE_FILE="/opt/scripts/clones/MAPPINGS/$LOCALHOSTNAME.XX03"
YEST_DEVICE_FILE="/opt/scripts/clones/CLONEFILES/YY01_to_XX03"
LOCALIP=`$NSLOOKUP $LOCALHOSTNAME|grep -v '#53'|grep'Address'|cut -d ":" -f2|sed 's/ //'`
NETWORK=`echo $LOCALIP|cut -d'.' -f1,2`

if_error ()
{
  if [[ $? -ne 0 ]]; then
      print "$1"
      exit $?
  fi
}
OFFLINE_YESTCLUSTER ()
{
  echo "Offline the ServiceGroup XX03 on $1"
  #OFFLINE_CLUS=`$HAGRP -state XX03|egrep 'ONLINE|PARTIAL'|cut -d":" -f1|awk '{print $NF}'`
  OFFLINE_CLUS=$1
  if [[ ! -z $OFFLINE_CLUS ]]; then $HAGRP -offline -force XX03 -any -clus $OFFLINE_CLUS; fi
  until [ -z $OFFLINE_CLUS ]
  do
     OFFLINE_CLUS=`$HAGRP -state XX03|egrep 'ONLINE|PARTIAL'|cut -d":" -f1|awk '{print $NF}'`
  done
  $HAGRP -clear XX03
}
PERFORM_CLONE ()
{
   echo "Perform Clone Operations now"
   $SE_UTILITIES/symclone -sid $1 -symforce -f $YEST_CLONE_FILE terminate -nop
   $SE_UTILITIES/symclone -sid $1 -f $YEST_CLONE_FILE -force recreate -precopy -nop
   $SE_UTILITIES/symclone -sid $1 -f $YEST_CLONE_FILE activate -nop
   if_error " Error: Problem in Clone Operation"
   sleep 30
   echo "End Perform Clone Operations now"
}
VERITAS_CONTROL ()
{
  echo "Enable the Clones under Veritas Control"
  $VXDCTL enable
  echo "End Enable the Clones under Veritas Control"
}
CLEAR_IMPORT_BIT ()
{
  for DEVICE in `/bin/cat $YEST_DEVICE_FILE|awk '{print $3}'`
  do
        echo "CLearing Import Tag for $DEVICE"
        $VXDISK clearimport $DEVICE
  done
}
REMOVE_VERITAS_TAG ()
{
   for DEVICE in 'awk '{print $3 ":" $3}' $YEST_DEVICE_FILE
   do
        echo "Removing Veritas tag for `echo $DEVICE|awk -F":" '{print $1 \" \" $2}'`"
        $VXDISK rmtag `echo $DEVICE|awk -F":" '{print $1 " " $2}'`
   done
}
SET_VERITAS_TAG ()
{
   for DEVICE in 'awk '{print $3 ":" $3}' $YEST_DEVICE_FILE
   do
        echo "Setting Veritas tag for `echo $DEVICE|awk -F":" '{print $1 \" \" $2}'`"
        $VXDISK settag `echo $DEVICE|awk -F":" '{print $1 " " $2}'`
        if_error "Error: Problem in settag Operation"
   done
}
IMPORT_UPDATEID ()
{
   echo ">>Import the DiskGroup and Update the Clone ID and Update access"

   $VXDG -n RS-XX03datadg -o useclonedev=on -o tag=XX03datadg -o updateid import RS-YY01datadg
   if_error ">>>Error : Problem in Import RS-XX03datadg operation"
   for volume in `$VXPRINT -htg RS-XX03datadg|grep "^v"|awk '{print $2}'`
   do
        $VXEDIT -g RS-XX03datadg set user=sybase group=sybase $volume
   done
   if_error ">>>Error : Problem in vxedit RS-XX03datadg Operation"

   $VXDG -n RS-XX03logdg -o useclonedev=on -o tag=XX03logdg -o updateid import RS-YY01logdg
   if_error ">Error : Problem in Import RS-XX03logdg operation"
   for volume in `$VXPRINT -htg RS-XX03logdg|grep "^v"|awk '{print $2}'`
   do
        $VXEDIT -g RS-XX03logdg set user=sybase group=sybase $volume
   done
   if_error ">Error : Problem in vxedit RS-XX03logdg Operation"

   echo ">>End Import the DiskGroup and Update the Clone ID and Update Access"
}
DEPORT_DISKGROUPS ()
{
}
PERFORM_SRDF_SPLIT ()
{
}
PERFORM_SRDF_ESTABLISH ()
{
}

if [[ "$LOCALHOSTNAME" = "xxdb01" && $NETWORK ="x.y" || "$LOCALHOSTNAME" = "xxdb02" && $NETWORK = "x." ]]; then LOCATION="VH":SID="0001xxxxxxxx";fi
if [[ "$LOCALHOSTNAME" = "yydb11" && $NETWORK ="x.y" ]]; then LOCATION="NL";SID="0001yyyyyyyy";fi
case $LOCATION in
VH)
