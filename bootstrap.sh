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

# Debug
ls -tlar /tmp/.vault_pass.txt

# Bootstrap cluster with kubespray
ansible-playbook -i kubespray/inventory/$kubespray_cluster_name/hosts.yaml kubespray/cluster.yml -b --private-key /home/runner/.ssh/github_actions

# Enable SELinux
ansible all -i kubespray/inventory/$kubespray_cluster_name/hosts.yaml -m selinux -a "policy=targeted state=enforcing" -b --private-key /home/runner/.ssh/github_actions

# Change kubelet.env SELinux context to resolve inital issue
ansible all -i kubespray/inventory/$kubespray_cluster_name/hosts.yaml -m shell -a "semanage fcontext -a -t etc_t -f f /etc/kubernetes/kubelet.env; restorecon /etc/kubernetes/kubelet.env" -b --private-key /home/runner/.ssh/github_actions

# Reboot all nodes and wait for them to come back up
ansible all -i kubespray/inventory/$kubespray_cluster_name/hosts.yaml -m reboot -b --private-key /home/runner/.ssh/github_actions

# Allow non-credentialed use of kubectl (only on control plane hosts)
ansible kube_control_plane -i kubespray/inventory/$kubespray_cluster_name/hosts.yaml -m file -a "path=/home/mehlj/.kube/ owner=mehlj group=mehlj state=directory" -b --private-key /home/runner/.ssh/github_actions
ansible kube_control_plane -i kubespray/inventory/$kubespray_cluster_name/hosts.yaml -m copy -a "src=/etc/kubernetes/admin.conf dest=/home/mehlj/.kube/config owner=mehlj group=mehlj remote_src=yes mode=0600" -b --private-key /home/runner/.ssh/github_actions

# Deploy traefik and example hello-world applications
ansible-playbook ansible/playbooks/traefik.yml -i kubespray/inventory/$kubespray_cluster_name/hosts.yaml --limit node0 -b --vault-password-file $vault_password_file --private-key /home/runner/.ssh/github_actions
