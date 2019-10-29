#!/bin/bash
# This script will need root access

APPDIR=/opt/app # change application path as per your standards
VARLOG=/var/log/mongodb-mms-automation
VARLIB=/var/lib/mongodb-mms-automation
MONGO_USER=xyz  #here username is harcoded, you might want to live with "mongo" user which comes by default .. but ..
# another way to get Username can be - 1> accepting and handling it as argument to script; ex : ./mongo-db-pre-requisities.sh <user>
# 2> get username from /etc/passwd or from AD, if you have common username across multiple servers..there can multiple other ways to this part

echo " Step-1 : ------ Pre-requisite RPM packages installation ------- "

yum install -q -y kernel cyrus-sasl cyrus-sasl-gssapi cyrus-sasl-plain krb5-libs libcurl libpcap net-snmp net-snmp-agent-libs openldap openssl lm_sensors-libs rpm-libs tcp_wrappers-libs glibc nano

echo " Step-2 : ------ Start and Enable sslauthd ------- "

# RHEL7 command = systemctl ; used here
systemctl start saslauthd
systemctl enable saslauthd

echo " Step-3 : ------ Update required kernel-parameters ------- "

sysctl -w net.ipv4.tcp_keepalive_time=300
sysctl -w kernel.pid_max=64000

#above commands are sufficient in normal cases, but we can take below additional steps to make sure changes persist

touch /etc/sysctl.d/net.ipv4.tcp_keepalive_time.conf
chmod o+r /etc/sysctl.d/net.ipv4.tcp_keepalive_time.conf
echo "net.ipv4.tcp_keepalive_time = 300" >> /etc/sysctl.d/net.ipv4.tcp_keepalive_time.conf
echo "net.ipv4.tcp_keepalive_time = 300" >> /etc/sysctl.conf

touch /etc/sysctl.d/kernel.pid_max.conf
chmod o+r /etc/sysctl.d/kernel.pid_max.conf
echo "kernel.pid_max = 64000" >> /etc/sysctl.d/kernel.pid_max.conf
echo "kernel.pid_max = 64000" >> /etc/sysctl.conf

sysctl -p

echo " Step-4 : ------ Update kernel command line parameters ------- "

# RHEL7 command = grubby ; used here
grubby --grub2 --args="numa-off" --update-kernel=$(grubby --default-kernel)
grubby --grub2 --args="transparent_hugepage=never" --update-kernel=$(grubby --default-kernel)

#below grubby command is to verify above changes
grubby --info=$( grubby --default-kernel ) | grep args=

echo " Step-5 : ------ Disable Transparent Hugepages ------- "

cp disable-transparent_hugepages /etc/init.d/disable-transparent_hugepages
chown root:root /etc/init.d/disable-transparent_hugepages

echo " Step-6 : ------ Configure limits for mongo-db user ------- "

cat << EOT > /etc/security/limits.d/95-$MONGO_USER.conf
$MONGO_USER soft fsize unlimited # (file size)
$MONGO_USER hard fsize unlimited # (file size)
$MONGO_USER soft cpu unlimited # (cpu time)
$MONGO_USER hard cpu unlimited # (cpu time)
$MONGO_USER soft as unlimited # (virtual memory size)
$MONGO_USER hard as unlimited # (virtual memory size)
$MONGO_USER soft nofile 64000 # (open files)
$MONGO_USER hard nofile 64000 # (open files)
$MONGO_USER soft nproc 64000 # (processes/threads)
$MONGO_USER hard nproc 64000 # (processes/threads)
EOT

chmod 644 /etc/security/limits.d/95-$MONGO_USER.conf
chown root:root /etc/security/limits.d/95-$MONGO_USER.conf

# Some setups might require to configure PAM settings as below :
# echo 'session required pam_limits.so' >> /etc/pam.d/su
# echo 'session required pam_limits.so' >> /etc/pam.d/login

echo " Step-7 : ------ Disk I/O scheduler and udev rules settings ------- "
echo ACTION=="add|change", KERNEL=="sd*[!0-9]|sr*", ATTR{queue/rotational}=="0", ATTR{queue/scheduler}="noop", ATTR{bdi/read_ahead_kb}="0" >> /etc/udev/rules.d/99-$MONGO_USER.rules

echo " Step-8 : ------ Creating directories and setting SELinux properties ------- "

mkdir -p $APPDIR/mongodb/log $APPDIR/mongodb-pid $VARLIB $VARLOG
# May be you will need following additions based on your enviroment = mkdir -p /mongod/{data,log,dump} $APPDIR/{mongodb-pid,data}
chown $MONGO_USER:grp $APPDIR $APPDIR/mongodb $APPDIR/mongodb/log $APPDIR/mongodb-pid $VARLIB $VARLOG
#In addition of ownership changes, you may also choose to use "chmod" based on your umask and other requirements

semanage fcontext -a -t mongod_log_t $APPDIR/mongodb/log.*
chcon -Rv -u system_u -t mongod_log_t $APPDIR/mongodb/log
restorecon -R -v $APPDIR/mongodb/log

semanage fcontext -a -t mongod_var_run_t $APPDIR/mongodb-pid.*
chcon -Rv -u system_u -t mongod_var_run_t $APPDIR/mongodb-pid
restorecon -R -v $APPDIR/mongodb-pid

# to check context and ownership
ls -lZ $APPDIR/mongodb-pid $APPDIR/mongodb/log
# to check ownership of directories
ls -ld $VARLIB $VARLOG

echo " Step-9 : ---- File-system creation ---- guidelines "
# here you can add your file-system creation code guidelines or can have a separate script for same
# sample steps given below
# 1 > Take backup of existing file-system to avoid mishaps
# 2 > Make sure you have required free space or free disks for file-system
# 3 > Create required LV's and format it as mkfs.xfs
# 4 > Update /etc/fstab entries with new file-system and make sure it has correct ownership and permissions
# 5 > Mount and start using whole setup for mongoDB == mongod / mongodb-mms-automation-agent
