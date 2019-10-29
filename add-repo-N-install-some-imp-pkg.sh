#!/bin/bash

#
# exit codes
#

PATH=/usr/bin:/bin:/usr/sbin:/sbin
if [[ $(id -u) -ne 0 ]]
then
  echo "User must be root" 1>&2
  exit 100
fi

# change below variables as per your requirements
REPOFILE=/etc/yum.repos.d/custom-made.repo
RPM_NAME=my-xyz-tools
RPM_AVAILABLE=""
REPOID=""
ERRORCATCH=0
BASEURL=""
BASEURLTEST=""
ANT_BASEURL=""
YET_ANT_BASEURL=""

if [ -e $REPOFILE ]
then
  echo "Repo already present"
  exit 101
fi
