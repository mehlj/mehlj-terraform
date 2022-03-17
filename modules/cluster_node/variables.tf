variable "vm_name" {
    description = "Name of the VM. Must be unique. Ex: k8snode0"
    type        = string
}

variable "vm_domain" {
    description = "Domain of the VM. Ex: lab.io"
    type        = string
}

variable "vm_template" {
    description = "Name of the vSphere template to clone from. Ex: CentOS-8-Gold"
    type        = string
}

variable "vm_datastore" {
    description = "Name of the datastore to be used. Ex: datastore1"
    type        = string
}

variable "vm_folder" {
    description = "vSphere folder to place the VM. Ex: /Production/"
    type        = string
}

variable "vm_datastore" {
    description = "Name of the datastore to be used. Ex: datastore1"
    type        = string
}

variable "vm_num_cpus" {
    description = "Number of CPU cores for the VM. Ex: 1"
    type        = number
}

variable "vm_num_memory" {
    description = "RAM for VM, in MB. Ex: 32769 for 32GB"
    type        = number
}

variable "vm_ip" {
    description = "IP address of the VM."
    type        = string
}