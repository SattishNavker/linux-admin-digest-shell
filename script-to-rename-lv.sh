#!/bin/bash

#
# Here you can change variables as per your requirements.
# This script can also be made interactive but it makes no much difference.
# Script should be executed as root user
#

USERX=`cat /etc/passwd | grep xyz | awk -F: '{ print $1 }'` #or hardcode fixed username
GROUPX=`cat /etc/group | grep xyz | awk -F: '{ print $1 }'` #or hardcode fixed groupname
OLDFS="/dev/vg/oldlv1"  #replace it with your exact names
NEWFS="/dev/vg/newlv1"  #replace it with your exact names
OLDMOUNT="/xyz"  #replace it with your FS
NEWMOUNT="/abc"  #or /xyz #replace it with your FS
#if you want to USE the same old-Mount then keep Mount-name same as that of the OLD-MOUNT, ex: here it is /xyz

echo " Pre-checks Step-1 -- mount-point / User / Group "
 if [ -d $NEWMOUNT ]; then
   echo "Mount Directory present"
 else
   mkdir $NEWMOUNT
 fi

 if grep $USERX /etc/passwd; then
   echo "USER entry exists"
 else
   echo "USER is absent -- exit"
   exit
 fi

 if grep $GROUPX /etc/group; then
   echo "GROUP entry exists"
 else
   echo "GROUP is absent -- exit"
   exit
 fi

 if lvs | grep $OLDFS ; then
   echo "LV entry exists"
 else
   echo "LV is absent -- exit"
   exit
 fi

echo " Step - 1 : Unmount target file-system to be renamed, be safe "

umount $OLDMOUNT

echo " Step - 2 : Take backup of /etc/fstab - recommended"

cp /etc/fstab /etc/fstab-bkp-$(date "+%m_%d_%Y")

echo " Step - 3 : Rename old LV to a new name using 'lvrename' command"

lvrename $OLDFS $NEWFS  # it wont destroy data inside LV  , just renames it

echo " Step - 4 : Delete entry of old file-system which is renamed"

sed -i "/`echo $OLDFS | awk -F / '{ print $4 }'`/d" /etc/fstab

echo " Step - 5 : Add new entry in fstab for new-name of file-system"

#cat /etc/fstab | grep $NEWFS
if grep $NEWFS /etc/fstab; then
  echo "FSTAB entry exists"
else
  echo "$NEWFS $NEWMOUNT  ext4  defaults 0 0" >> /etc/fstab  #FS-type and other option can be changed as per your requirements
  echo "Added FSTAB entry"
fi

echo " Step - 6 : Mount renamed file-system again to start using it"

##chown $USER:$GROUP $NEW-MOUNT ## chown can be applied as well
mount -a # mount -a will mount all FS mentioned in /etc/fstab, if you dont want it then use "mount" command

echo " Step - 7 : Change ownership of mount"

chown $USERX:$GROUPX $NEWMOUNT # some of us might want to chown mounts, depending on your enviroments

echo " Step - 8 : Verification of changes"

df -h $NEWMOUNT;echo;ls -ld `$NEWMOUNT`;echo;cat /etc/fstab | grep $NEWMOUNT
