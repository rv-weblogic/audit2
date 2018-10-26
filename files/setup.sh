#!/bin/bash

set -x

# Get from the repo the hosts
awk 'NF > 0' ./WLS-automation/hosts > ~/host1

# Go to the main path
cd ~/

awk '!/audit_admin|audit_as01|audit_as02|children/{print }' <(cat host1) > host2
awk '!_[$1]++' host2 > host1
sed -i -e 's/ansible_host=//g' host1

# This script works only for the first occurrence for now
pattern=`awk 'NR==1{ print $1 }' host1`
if [ ! -f ~/.ssh/known_hosts ]; then
	touch ~/.ssh/known_hosts
	chmod 0644 ~/.ssh/known_hosts
fi
if grep $pattern ~/.ssh/known_hosts; then
   echo ***First host already exist***
else
   # This will add hosts/ip on /etc/hosts
   awk '{ print  $2 " " $1 }' host1  | sudo tee --append /etc/hosts

   rpm -qa sshpass > epelx
   if [[ ! -s epelx ]]; then
      sudo yum install sshpass -y
   fi
   
   if [ ! -f ~/.ssh/id_rsa ]; then
     ssh-keygen -q -f ~/.ssh/id_rsa -N ""
   fi
   
   pass=$1
   awk -F' ' '{ print  $1 }' host1 > sshcopy
   dos2unix sshcopy sshcopy
   awk NF sshcopy > host2
   awk -v password="$pass" '{print "sshpass -p " password " ssh-copy-id -o StrictHostKeyChecking=no " $1}' host2 > sshcopy
   chmod u+x sshcopy
   ./sshcopy
   
   rm -f epelx host1 host2 host3 sshcopy

fi
