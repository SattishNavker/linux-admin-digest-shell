#!/bin/bash

#
# Here you can change variables as per your requirements.
# This script can also be made interactive but it makes no much difference.
#
#

$USER=`cat /etc/passwd | grep xyz | awk -F: '{ print $1 }'` #or hardcode fixed username
$GROUP=`cat /etc/group | grep xyz | awk -F: '{ print $1 }'` #or hardcode fixed groupname
$OLDFS=/dev/vg/oldlv1  #replace it with your VG and LV names
$NEWFS=/dev/vg/newlv1  #replace it with your VG and LV names
$OLDMOUNT=/xyz  #replace it with your FS
$NEWMOUNT=/abc  #or /xyz #replace it with your FS
#if you want to USE the same old-Mount then keep Mount-name same as that of the OLD-MOUNT, ex: here it is /xyz

#echo " Pre-checks Step -- mntpoint / lv - vg / user / "
# if [ -d $NEW-MOUNT ]
#   echo "directory present"
# else
#   mkdir $NEW-Mount
# fi

# lvs | grep -i $OLD-LV
# vgs | grep -i VG -- old/new ?
#
# lvs | grep -i $NEW-LV

echo " Step - 1 : Unmount target file-system to be renamed, be safe "

umount $OLDMOUNT

echo " Step - 2 : Take backup of /etc/fstab - recommended"

cp /etc/fstab /etc/fstab-bkp-`date+"%m_%d_%Y"`

echo " Step - 3 : Rename old LV to a new name using 'lvrename' command"

lvrename $OLDFS $NEWFS

echo " Step - 4 : Delete entry of old file-system which is renamed"

sed -i '$OLD-FS/d' /etc/fstab

echo " Step - 5 : Add new entry in fstab for new-name of file-system"

echo "$NEWFS $NEWMOUNT  ext4  defaults 0 0" >> /etc/fstab  #FS-type and other option can be changed as per your requirements

echo " Step - 6 : Mount renamed file-system again to start using it"

##chown $USER:$GROUP $NEW-MOUNT ## chown can be applied as well
mount -a # mount -a will mount all FS mentioned in /etc/fstab, if you dont want it then use "mount" command

echo " Step - 7 : Change ownership of mount"

chown $USER:$GROUP $NEWMOUNT # some of us might want to chown mounts, depending on your enviroments

echo " Step - 8 : Verification of changes"

df -h $NEWMOUNT;echo;ls -ld $NEWMOUNT;echo;cat /etc/fstab | grep $NEWMOUNT
