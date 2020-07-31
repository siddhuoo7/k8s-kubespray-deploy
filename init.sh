#!/bin/bash
#ssh-keygen -t rsa
ssh-keygen -t rsa -N '' -f ~/.ssh/id_rsa <<< y
echo "root@$2"
yum install sshpass -y
cat ~/.ssh/id_rsa.pub |sshpass -p $1 ssh   root@$2 "mkdir -p ~/.ssh && cat >> ~/.ssh/authorized_keys && chmod 600 ~/.ssh/authorized_keys"
cat ~/.ssh/id_rsa.pub |sshpass -p $1 ssh   root@$3 "mkdir -p ~/.ssh && cat >> ~/.ssh/authorized_keys && chmod 600 ~/.ssh/authorized_keys"
cat ~/.ssh/id_rsa.pub |sshpass -p $1 ssh   root@$4 "mkdir -p ~/.ssh && cat >> ~/.ssh/authorized_keys && chmod 600 ~/.ssh/authorized_keys"
cat ~/.ssh/id_rsa.pub |sshpass -p $1 ssh   root@$5 "mkdir -p ~/.ssh && cat >> ~/.ssh/authorized_keys && chmod 600 ~/.ssh/authorized_keys"

sed -i "s|masterNode|$2|g" inventory/hosts.yaml
sed -i "s|nodeOne|$3|g" inventory/hosts.yaml
sed -i "s|nodeTwo|$4|g" inventory/hosts.yaml
sed -i "s|nodeThree|$5|g" inventory/hosts.yaml