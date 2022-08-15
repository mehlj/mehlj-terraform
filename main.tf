module "k8snode0" {
  source = "./modules/cluster_node/"
  
  vm_name            = "k8snode0"
  vm_domain          = "lab.io"
  vm_template        = "CentOS8_Template"
  vm_datastore       = "datastore1"
  vm_folder          = "/"
  vm_num_cpus        = 2
  vm_num_memory      = 4096
  vm_ip              = "192.168.1.210"
}

module "k8snode1" {
  source = "./modules/cluster_node/"
  
  vm_name            = "k8snode1"
  vm_domain          = "lab.io"
  vm_template        = "CentOS8_Template"
  vm_datastore       = "datastore1"
  vm_folder          = "/"
  vm_num_cpus        = 2
  vm_num_memory      = 4096
  vm_ip              = "192.168.1.211"
}

module "k8snode2" {
  source = "./modules/cluster_node/"
  
  vm_name            = "k8snode2"
  vm_domain          = "lab.io"
  vm_template        = "CentOS8_Template"
  vm_datastore       = "datastore1"
  vm_folder          = "/"
  vm_num_cpus        = 2
  vm_num_memory      = 4096
  vm_ip              = "192.168.1.212"

  # optional variables
  bootstrap_cluster  = true
}