#!/usr/bin/ksh

#
# Three such scripts - one per batch DB ( and Three more for another site == TOT 6 scripts with minute differences )
#

LOCATION=""
LOCALHOSTNAME=`hostname`
NSLOOKUP="/usr/bin/nslookup"
SE_UTILITIES="/usr/symcli/bin"
LOCALIP=`$NSLOOKUP $LOCALHOSTNAME | grep -v '#53' | grep 'Address' | cut -d ":" -f2 | sed 's/ //'`
NETWORK=`echo $LOCALIP | cut -d'.' -f1,2`
CLONE_FILE="/path/to/clonefile/YY01_to_XX03"
if [[ "LOCALHOSTNAME" = "xxxdb01" && $NETWORK = "x.y" || "$LOCALHOSTNAME" = "xxxdb02" && $NETWORK = "x.y" ]]; then LOCATION="VH";SID="00010001xxxxxxxx";fi
if [[ "LOCALHOSTNAME" = "xxxdb11" && $NETWORK = "x.y" || "$LOCALHOSTNAME" = "xxxdb12" && $NETWORK = "x.y" ]]; then LOCATION="NL";SID="00010001xxxxxxxx";fi
$SE_UTILITIES/symclone -sid $SID -f $CLONE_FILE terminate -nop
$SE_UTILITIES/symclone -sid $SID -f $CLONE_FILE query
