#!/bin/bash

uid=""
gid=""
withPostgres="false"
password=""
dockerNet=""

while [[ $# > 1 ]]
do
    key="$1"
    shift

    case $key in
    --uid)
        uid=$1
        shift
        ;;
    --gid)
        gid=$1
        shift
        ;;
    --password)
        password=$1
        shift
        ;;
    --with-postgres)
        withPostgres=$1
        shift
        ;;
    --docker-net)
        dockerNet=$1
        shift
        ;;    
    esac
done

[ -z "$uid" ] || usermod -o --uid=$uid jenkins
[ -z "$gid" ] || usermod --gid=$gid jenkins
[ -z "$password" ] || echo "jenkins:$password" | chpasswd
[ -z "$dockerNet" ] || docker network connect "$dockerNet" $HOSTNAME
[ "$withPostgres" = "false" ] || /etc/init.d/postgresql start

chown -R jenkins:jenkins /home/jenkins
/usr/sbin/sshd -D
