#!/bin/bash

# NOTE - the ansible vault password file must contain the correct password to decrypt the Traefik private key file

# example usage:
# ./bootstrap.sh -n mehlj-cluster -f ~/.vault_pass.txt

while [[ "$#" -gt 0 ]]; do
    case $1 in
        -n|--kubespray-cluster-name) kubespray_cluster_name="$2"; shift ;;
        -f|--vault-password-file) vault_password_file="$2"; shift ;;
        *) echo "Unknown parameter passed: $1"; exit 1 ;;
    esac
    shift
done

# Bootstrap cluster with kubespray
ansible-playbook -i kubespray/inventory/$kubespray_cluster_name/hosts.yml kubespray/cluster.yml -b 

# Enable SELinux
ansible all -i kubespray/inventory/$kubespray_cluster_name/hosts.yml -m selinux -a "policy=targeted state=enforcing" -b

# Change kubelet.env SELinux context to resolve inital issue
ansible all -i kubespray/inventory/$kubespray_cluster_name/hosts.yml -m shell -a "semanage fcontext -a -t etc_t -f f /etc/kubernetes/kubelet.env; restorecon /etc/kubernetes/kubelet.env" -b

# Reboot all nodes and wait for them to come back up
ansible all -i kubespray/inventory/$kubespray_cluster_name/hosts.yml -m reboot -b 

# Allow non-credentialed use of kubectl (only on control plane hosts)
ansible kube_control_plane -i kubespray/inventory/$kubespray_cluster_name/hosts.yml -m file -a "path=/home/mehlj/.kube/ owner=mehlj group=mehlj state=directory" -u mehlj
ansible kube_control_plane -i kubespray/inventory/$kubespray_cluster_name/hosts.yml -m copy -a "src=/etc/kubernetes/admin.conf dest=/home/mehlj/.kube/config owner=mehlj group=mehlj remote_src=yes mode=0600" -u mehlj -b

# Deploy traefik and example hello-world applications
ansible-playbook ansible/playbooks/traefik.yml -b --vault-password-file $vault_password_file
