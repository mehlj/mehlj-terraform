provider "vsphere" {
  vsphere_server       = var.vsphere_server
  user                 = var.vsphere_user
  password             = jsondecode(data.aws_secretsmanager_secret_version.current.secret_string)["vsphere"]
  allow_unverified_ssl = true
}

provider "aws" {
  region = "us-east-1"
}



# var: CentOS8_Template
# var: datastore1

















resource "vsphere_virtual_machine" "k8snode1" {
  name             = "k8snode1"
  resource_pool_id = data.vsphere_compute_cluster.cluster.resource_pool_id
  datastore_id     = data.vsphere_datastore.datastore.id

  num_cpus               = 2
  memory                 = 4096
  cpu_hot_add_enabled    = true
  cpu_hot_remove_enabled = true
  memory_hot_add_enabled = true
  guest_id               = data.vsphere_virtual_machine.template.guest_id

  scsi_type = data.vsphere_virtual_machine.template.scsi_type

  network_interface {
    network_id   = data.vsphere_network.mgmt_lan.id
    adapter_type = data.vsphere_virtual_machine.template.network_interface_types[0]
  }

  disk {
    label            = "disk0"
    size             = data.vsphere_virtual_machine.template.disks.0.size
    eagerly_scrub    = data.vsphere_virtual_machine.template.disks.0.eagerly_scrub
    thin_provisioned = data.vsphere_virtual_machine.template.disks.0.thin_provisioned
  }

  clone {
    template_uuid = data.vsphere_virtual_machine.template.id

    customize {
      linux_options {
        host_name = "k8snode1"
        domain    = "lab.io"
      }

      network_interface {
        ipv4_address = "192.168.1.211"
        ipv4_netmask = 24
      }

      ipv4_gateway    = "192.168.1.1"
      dns_server_list = ["192.168.1.1", "8.8.8.8", ]
    }
  }
  connection {
    type     = "ssh"
    user     = "root"
    password = jsondecode(data.aws_secretsmanager_secret_version.current.secret_string)["ssh"]
    host     = self.clone[0].customize[0].network_interface[0].ipv4_address
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
}

resource "vsphere_virtual_machine" "k8snode2" {
  name             = "k8snode2"
  resource_pool_id = data.vsphere_compute_cluster.cluster.resource_pool_id
  datastore_id     = data.vsphere_datastore.datastore.id

  num_cpus               = 2
  memory                 = 4096
  cpu_hot_add_enabled    = true
  cpu_hot_remove_enabled = true
  memory_hot_add_enabled = true
  guest_id               = data.vsphere_virtual_machine.template.guest_id

  scsi_type = data.vsphere_virtual_machine.template.scsi_type

  network_interface {
    network_id   = data.vsphere_network.mgmt_lan.id
    adapter_type = data.vsphere_virtual_machine.template.network_interface_types[0]
  }

  disk {
    label            = "disk0"
    size             = data.vsphere_virtual_machine.template.disks.0.size
    eagerly_scrub    = data.vsphere_virtual_machine.template.disks.0.eagerly_scrub
    thin_provisioned = data.vsphere_virtual_machine.template.disks.0.thin_provisioned
  }

  clone {
    template_uuid = data.vsphere_virtual_machine.template.id

    customize {
      linux_options {
        host_name = "k8snode2"
        domain    = "lab.io"
      }

      network_interface {
        ipv4_address = "192.168.1.212"
        ipv4_netmask = 24
      }

      ipv4_gateway    = "192.168.1.1"
      dns_server_list = ["192.168.1.1", "8.8.8.8", ]
    }
  }
  connection {
    type     = "ssh"
    user     = "root"
    password = jsondecode(data.aws_secretsmanager_secret_version.current.secret_string)["ssh"]
    host     = self.clone[0].customize[0].network_interface[0].ipv4_address
  }

  provisioner "file" {
    content     = jsondecode(data.aws_secretsmanager_secret_version.current.secret_string)["vault"]
    destination = "/root/.vault_pass.txt"
  }

  provisioner "remote-exec" {
    inline = ["yum install epel-release -y",
      "yum install git ansible -y",
      "git clone https://github.com/mehlj/mehlj-ansible.git",
      "git clone https://github.com/mehlj/kubespray.git",
      "ansible-playbook mehlj-ansible/playbooks/ssh.yml",
    "ansible-playbook mehlj-ansible/playbooks/kubernetes.yml --vault-password-file /root/.vault_pass.txt"]
  }

  # Bootstrap kubernetes cluster with kubespray
  provisioner "local-exec" {
    command = "sleep 60; ./bootstrap.sh -n mehlj-cluster -f /tmp/.vault_pass.txt"
  }
}
