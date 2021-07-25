#!/bin/bash

# NOTE - this script will destroy + recreate your existing terraform in $terraform_dir
# NOTE - make sure to configure kubespray variables + inventory before running this script
# NOTE - make sure you have the mehlj-ansible roles where ansible expects them, or add a custom directory in your ansible.cfg

# example usage:
# ./provision.sh -t /home/mehlj/git/mehlj-terraform/ -k /home/mehlj/git/kubespray/ -n mehlj-cluster

while [[ "$#" -gt 0 ]]; do
    case $1 in
        -t|--terraform-dir) terraform_dir="$2"; shift ;;
        -k|--kubespray-dir) kubespray_dir="$2"; shift ;;
        -n|--kubespray-cluster-name) kubespray_cluster_name="$2"; shift ;;
        *) echo "Unknown parameter passed: $1"; exit 1 ;;
    esac
    shift
done

current_dir=$PWD

# Destroy existing kubernetes nodes
cd $terraform_dir
terraform destroy -auto-approve

# Re-provision kubernetes nodes
terraform apply -auto-approve

# Stage nodes for cluster joining using custom ansible roles
ansible-playbook -i $kubespray_dir/inventory/$kubespray_cluster_name/hosts.yml ansible/kubernetes.yml

# Run kubespray against new kubernetes nodes
cd $kubespray_dir
ansible-playbook -i inventory/$kubespray_cluster_name/hosts.yml cluster.yml -b 

# Enable SELinux
ansible all -i inventory/$kubespray_cluster_name/hosts.yml -m selinux -a "policy=targeted state=enforcing" -b

# Change kubelet.env SELinux context to resolve inital issue
ansible all -i inventory/$kubespray_cluster_name/hosts.yml -m shell -a "semanage fcontext -a -t etc_t -f f /etc/kubernetes/kubelet.env; restorecon /etc/kubernetes/kubelet.env" -b

# Reboot all nodes and wait for them to come back up
ansible all -i inventory/$kubespray_cluster_name/hosts.yml -m reboot -b 

# Allow non-credentialed use of kubectl (only on control plane hosts)
ansible kube_control_plane -i inventory/$kubespray_cluster_name/hosts.yml -m file -a "path=/home/mehlj/.kube/ owner=mehlj group=mehlj state=directory" -u mehlj
ansible kube_control_plane -i inventory/$kubespray_cluster_name/hosts.yml -m copy -a "src=/etc/kubernetes/admin.conf dest=/home/mehlj/.kube/config owner=mehlj group=mehlj remote_src=yes mode=0600" -u mehlj -b

# Deploy traefik and example hello-world applications
cd $current_dir
ansible-playbook ansible/traefik.yml -b -i ansible/main_host.yml
