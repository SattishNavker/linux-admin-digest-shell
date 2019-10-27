#!/usr/bin/ksh

#
# Cluster on PRD side (site-1 2-node) and cluster on DR side (site-2 2-node) == here to roleswap need additional TERMINATE and RECREATE scripts
# Cloning is within same site node-1 (PRD-DB) cloned to node-2 (Batch-DBs-3) -- 3 times a day (Let service be running on any PRD/DR sites)
#
# MAPPINGS file == 4 columns == batch-dg; prd-dg; shared-batch-disk; batch-disk-label
# CLONE file == 2 columns == shared-prd-disk; shared-batch-disk
#

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
DEVICE_FILE="/opt/scripts/clones/MAPPINGS/$LOCALHOSTNAME.XX03"
CLONE_FILE="/opt/scripts/clones/CLONEFILES/YY01_to_XX03"
LOCALIP=`$NSLOOKUP $LOCALHOSTNAME|grep -v '#53'|grep'Address'|cut -d ":" -f2|sed 's/ //'`
NETWORK=`echo $LOCALIP|cut -d'.' -f1,2`

if_error ()
{
  if [[ $? -ne 0 ]]; then
      print "$1"
      exit $?
  fi
}
OFFLINE_CLUSTER ()
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
   $SE_UTILITIES/symclone -sid $1 -symforce -f $CLONE_FILE terminate -nop
   #$SE_UTILITIES/symclone -sid $1 -f $CLONE_FILE -force recreate -precopy -nop
   $SE_UTILITIES/symclone -sid $1 -f $CLONE_FILE activate -nop
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
  for DEVICE in `/bin/cat $DEVICE_FILE|awk '{print $3}'`
  do
        echo "CLearing Import Tag for $DEVICE"
        $VXDISK clearimport $DEVICE
  done
}
REMOVE_VERITAS_TAG ()
{
   for DEVICE in `awk '{print $3 ":" $3}' $DEVICE_FILE`
   do
        echo "Removing Veritas tag for `echo $DEVICE|awk -F":" '{print $1 \" \" $2}'`"
        $VXDISK rmtag `echo $DEVICE|awk -F":" '{print $1 " " $2}'`
   done
}
SET_VERITAS_TAG ()
{
   for DEVICE in `awk '{print $3 ":" $3}' $DEVICE_FILE`
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
  echo "Deport the Diskgroup"
  $VXDG deport RS-XX03datadg
  if_error "Error: Problem in deport RS-XX03datadg operation"
  $VXDG deport RS-XX03logdg
  if_error "Error: Problem in deport RS-XX03logdg operation"
  echo "End Deport the Diskgroup"
}
PERFORM_SRDF_SPLIT ()
{
  echo "SRDF Split...."
  $SE_UTILITIES/symrdf -g XXXXXXXX03_VH split -nop
  #$SE_UTILITIES/symrdf -g XXXXXXXX03_VH split -force -nop
  #$SE_UTILITIES/symrdf -g XXXXXXXX03_VH split -rdfg 25 -force -symforce -nop
  echo "End of SRDF split"
}
PERFORM_SRDF_ESTABLISH ()
{
  echo "SRDF Establish...."
  $SE_UTILITIES/symrdf -g XXXXXXXX03_VH establish -nop
  echo "End of SRDF Establish"
}

if [[ "$LOCALHOSTNAME" = "xxdb01" && $NETWORK ="x.y" || "$LOCALHOSTNAME" = "xxdb02" && $NETWORK = "x." ]]; then LOCATION="VH":SID="0001xxxxxxxx";fi
if [[ "$LOCALHOSTNAME" = "yydb11" && $NETWORK ="x.y" ]]; then LOCATION="NL";SID="0001yyyyyyyy";fi

case $LOCATION in

VH)  # or NL) vice versa based on scenario
    PROD_NODE=`$HAGRP -state YYYYYY03 | egrep -i 'ONLINE|PARTIAL'|awk '{print $3}'|cut -d':' -f2`
    if [[ "PROD_NODE" = "xxdb01" || "PROD_NODE" = "xxdb02" ]]; then PROD_LOCATION="VH";fi
    if [[ "PROD_NODE" = "yydb11" ]]; then PROD_LOCATION="NL";fi

    case $PROD_LOCATION in
      
      VH)
          CLUSTER_NAME="xyz"
          echo "PROD NODE $PROD_NODE, NETWORK $NETWORK, LOCATION $LOCATION, NODE $NODE"
          if [[ `$SE_UTILITIES/symdg list|grep XXXXXXXX03_VH|awk '{print $2}'` = "RDF1" ]];
            then
              OFFLINE_CLUSTER $CLUSTER_NAME
              $HAGRP -freeze YYYYYY03   ### here YY stands for batch-DB (SRDF/Veritas DG's)
              echo "PROD LOCATION :: $PROD_LOCATION"
              #DEPORT_DISKGROUPS
              PERFORM_SRDF_SPLIT
              PERFORM_CLONE $SID
              VERITAS_CONTROL
              CLEAR_IMPORT_BIT
              REMOVE_VERITAS_TAG
              SET_VERITAS_TAG
              IMPORT_UPDATEID
              DEPORT_DISKGROUPS
              PERFORM_SRDF_ESTABLISH
              $HAGRP -unfreeze YYYYYY03
              OFFLINE_CLUSTER
              echo "Online the YYYYYY03 Cluster now on $NODE"
              $HAGRP -online YYYYYY03 -sys xxdb02  ## or use $NODE for -sys arg
            else
              if_error "Error: NOT a Supported configuration"
          fi
        ;;
    esac
    ;;
esac
