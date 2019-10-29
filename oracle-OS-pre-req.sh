#!/bin/bash

yum --quite install -y bind-utils compat-libcap1 gcc gcc-c++ glibc glibc-devel ksh libgcc libstdc++ libstdc++-devel libaio libaio-devel make nfs-utils perl-Data-Dumper perl-Enc psmisc systat libXi libXtst xorg-x11-xauth rsync unzip wget
yum --quite install -y compat-libstdc++-33.x86_64 compat-libcap1.x86_64 gcc-c++.x86_64 glibc-devel.i686 glibc-devel.x86_64 libstdc++-devel.x86_64 libstdc++-devel.i686 libaio.i686 libaio-devel.i686 libaio-devel.x86_64 perl-ENV.noarch libXi.x86_64 xorg-x11-xauth.x86_64
