#!/bin/bash

#
# Here you can change variables as per your requirements.
# This script can also be made interactive but it makes no much difference.
#

$USER=`cat /etc/passwd | grep xyz | awk -F: '{ print $1 }'` #or hardcode fixed username
$GROUP=`cat /etc/group | grep xyz | awk -F: '{ print $1 }'` #or hardcode fixed groupname
$OLD-FS=/dev/vg/old-lv1  #replace it with your VG and LV names
$NEW-FS=/dev/vg/new-lv1  #replace it with your VG and LV names
$OLD-MOUNT=/xyz  #replace it with your FS
$NEW-MOUNT=/abc  #or /xyz #replace it with your FS
#if you want to USE the same old-Mount then keep Mount-name same as that of the OLD-MOUNT, ex: here it is /xyz

echo " Step - 1 : Unmount target file-system to be renamed, be safe "

umount $OLD-MOUNT

echo " Step - 2 : Take backup of /etc/fstab - recommended"

cp /etc/fstab /etc/fstab-bkp-`date+"%m_%d_%Y"`

echo " Step - 3 : Rename old LV to a new name using 'lvrename' command"

lvrename $OLD-FS $NEW-FS

echo " Step - 4 : Delete entry of old file-system which is renamed"

sed -i '$OLD-FS/d' /etc/fstab

echo " Step - 5 : Add new entry in fstab for new-name of file-system"

echo "$NEW-FS $NEW-MOUNT  ext4  defaults 0 0" >> /etc/fstab  #FS-type and other option can be changed as per your requirements

echo " Step - 6 : Mount renamed file-system again to start using it"

##chown $USER:$GROUP $NEW-MOUNT ## chown can be applied as well
mount -a # mount -a will mount all FS mentioned in /etc/fstab, if you dont want it then use "mount" command

echo " Step - 7 : Change ownership of mount"

chown $USER:$GROUP $NEW-MOUNT # some of us might want to chown mounts, depending on your enviroments

echo " Step - 7 : Verification of changes"

df -h $NEW-MOUNT;echo;ls -ld $NEW-MOUNT;echo;cat /etc/fstab | grep $NEW-MOUNT
