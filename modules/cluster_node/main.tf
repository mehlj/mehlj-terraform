data "aws_secretsmanager_secret" "secrets" {
  arn = "arn:aws:secretsmanager:us-east-1:252267185844:secret:mehlj_lab_creds-j5VElQ"
}

data "aws_secretsmanager_secret_version" "current" {
  secret_id = data.aws_secretsmanager_secret.secrets.id
}

data "vsphere_datacenter" "dc" {
  name = "lab"
}

data "vsphere_compute_cluster" "cluster" {
  name          = "lab_hosts"
  datacenter_id = data.vsphere_datacenter.dc.id
}

data "vsphere_network" "mgmt_lan" {
  name          = "DSwitch-VM Network"
  datacenter_id = data.vsphere_datacenter.dc.id
}

data "vsphere_datastore" "datastore" {
  name          = var.vm_datastore
  datacenter_id = data.vsphere_datacenter.dc.id
}

data "vsphere_virtual_machine" "template" {
  name          = var.vm_template
  datacenter_id = data.vsphere_datacenter.dc.id
}




locals {
  provisioner_command = "sleep 60; ./bootstrap.sh -n mehlj-cluster -f /tmp/.vault_pass.txt"
}


resource "local_file" "ansible_vault" {
  filename        = "/tmp/.vault_pass.txt"
  content         = jsondecode(data.aws_secretsmanager_secret_version.current.secret_string)["vault"]
  file_permission = 0600
}


resource "vsphere_virtual_machine" "cluster_node" {
  name             = var.vm_name
  resource_pool_id = data.vsphere_compute_cluster.cluster.resource_pool_id
  datastore_id     = data.vsphere_datastore.datastore.id
  folder           = var.vm_folder

  num_cpus               = var.vm_num_cpus
  memory                 = var.vm_num_memory
  cpu_hot_add_enabled    = true
  cpu_hot_remove_enabled = true
  memory_hot_add_enabled = true
  guest_id               = data.vsphere_virtual_machine.template.guest_id

  scsi_type = data.vsphere_virtual_machine.template.scsi_type

  network_interface {
    network_id   = data.vsphere_network.mgmt_lan.id
    adapter_type = data.vsphere_virtual_machine.template.network_interface_types[0]
    use_static_mac = var.vm_static_mac
    mac_address    = var.vm_mac_address
  }

  # if var.needs_custom_disk_space is not set to True (default value of False), then the template disk size is used.
  # if var.needs_custom_disk_space is set to True, then a custom disk size is used, determined via the var.vm_disk_space
  disk {
    label            = "disk0"
    size             = var.needs_custom_disk_space ? var.vm_disk_space : data.vsphere_virtual_machine.template.disks.0.size  
    eagerly_scrub    = data.vsphere_virtual_machine.template.disks.0.eagerly_scrub
    thin_provisioned = data.vsphere_virtual_machine.template.disks.0.thin_provisioned
  }

  clone {
    template_uuid = data.vsphere_virtual_machine.template.id

    customize {
      linux_options {
        host_name = lower(var.vm_name)
        domain    = lower(var.vm_domain)
      }

      network_interface {
        ipv4_address = var.vm_ip
        ipv4_netmask = 24
      }

      ipv4_gateway    = "192.168.1.1"
      timeout         = "0"
      dns_server_list = ["192.168.1.1", "8.8.8.8", ]
    }
  }
  connection {
    type     = "ssh"
    user     = "root"
    password = jsondecode(data.aws_secretsmanager_secret_version.current.secret_string)["ssh"]
    host     = var.vm_ip
  }

  provisioner "file" {
    content     = jsondecode(data.aws_secretsmanager_secret_version.current.secret_string)["vault"]
    destination = "/root/.vault_pass.txt"
  }

  provisioner "remote-exec" {
    inline = ["yum install epel-release -y",
      "yum install git ansible -y",
      "git clone https://github.com/mehlj/mehlj-ansible.git",
      "ansible-playbook mehlj-ansible/playbooks/ssh.yml",
    "ansible-playbook mehlj-ansible/playbooks/kubernetes.yml --vault-password-file /root/.vault_pass.txt"]
  }

  # -----Psuedocode:-----
  # if var.bootstrap_cluster = true:
  #   Provision the Kubernetes cluster using the bootstrap.sh script
  # else:
  #   skip the cluster bootstrapping, and only run a benign echo command to keep Terraform happy
  # -----end Psuedocode-----
  # 
  # 
  # This logic allows the cluster to be provisioned only once, to speed up the pipeline execution.
  # The cluster bootstrapping is entirely idempodent, but kubespray takes some time to complete. 
  # The cluster bootstrapping only needs to be run once, so omitting the step when it is not necessary allows the pipeline to be run faster.
  provisioner "local-exec" {
    command = join(" && ", ["echo Bootstrapping cluster..", var.bootstrap_cluster != false ? local.provisioner_command : "echo Not bootstrapping cluster.."])
  }
}