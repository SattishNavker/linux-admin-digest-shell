!/bin/sh
#
# Before putting this script in place, run: # mv /sbin/cmd /sbin/cmd.real
#
# then copy this script to /sbin/cmd and make it executable
# you may also need to do a restorecon on it if SELinux is around

parent=$PPID

ps_out=`ps axefo 'pid,user,command' | grep -E "^\s*$parent"`

logger "Command CMD called by: $ps_out"

cmd.real "$@"
