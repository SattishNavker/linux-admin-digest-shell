#!/bin/bash

#
# exit codes:
# 100 = user must be root
# 101 = repo file already present
# 102 = Nothing found eligible
# 103 = not able to create repofile
# 104 = not able to chmod repofile
# 105 = package not found
# 106 = installation failed
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

if rpm -q --quite dependent-pkg   # here "dependent-pkg" is just a place holder
then
  CAP=$(grep -h --include={xyz.repo,abc*.repo} baseurl /etc/yum.repos.d/*.repo | cut -d ' ' -f3 | cut -d '/' -f3 | uniq | head -1)
  case $CAP in
    "server1.domain") BASEURL=http:/path/to/repo-1 && ANT_BASEURL=http://path/to/repo-2;;
    "server2.domain") BASEURL=http:/path/to/repo-1;;
    "server1.domain") BASEURL=http:/path/to/repo-1 && ANT_BASEURL=http://path/to/repo-2 && YET_ANT_BASEURL=http://path/to/repo-3;;
    *) echo "Nothing found eligible" && exit 102;;
  esac
else
  GLS="$(grep -h --include={xyz.repo,abc*.repo} baseurl /etc/yum.repos.d/*.repo | cut -d ' ' -f3 | cut -d '/' -f3 | uniq | head -1)"
  if [ -z "$GLS" ]
  then
    echo "Nothing found eligible"
    exit 102
  fi
  BASEURL="http://path/to/dir"
fi

echo "Using REPO: $REPOFILE with URL: $BASEURL"

/bin/touch $REPOFILE || exit 103 #Creates new files
/bin/chmod 644 $REPOFILE || exit 104
/usr/bin/tee $REPOFILE << EOM # input is provided Here
[custom-made]
name=custom-made
baseurl=$BASEURL
        $ANT_BASEURL
        $YET_ANT_BASEURL
enabled=1
gpgcheck=0
EOM

RPM_AVAILABLE=$(yum --disablerepo=* --enablerepo=custom-made -q search my-xyz-tools | grep my-xyz-tools | cut -d '.' -f1 | grep -v "=")
if [[ "$RPM_AVAILABLE" != "$RPM_NAME" ]]
then
  echo "Package not available"
  rm -f $REPOFILE
  exit 105
else
  echo "Package available"
fi

echo "installing my imp package"
yum --disablerepo=* --enablerepo=custom-made install -y my-xyz-tool || INSTALLFAIL=true # Installation of pkg from newly set repo
if [[ "$INSTALLFAIL" = "true" ]]
  then
    echo "Installation failed"
    rm -f $REPOFILE
    exit 106
  else
    exit 0
fi
