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





# ---optional variables---

# use only if you have a MAC address already approved for the network
# otherwise, a random MAC is generated (default and preferred)
variable "vm_static_mac" {
  description = "Determines whether or not the VM uses a static, pre-defined MAC address, or a random one."
  type        = bool
  default     = false
}

variable "vm_mac_address" {
  description = "The static MAC address of the VM."
  type        = string
  default     = null
}

variable "needs_custom_disk_space" {
  description = "Determines whether or not to extend disk space. If false - defaults to template disk size."
  type        = bool
  default     = false
}

variable "vm_disk_space" {
  description = "Size of the VM disk in GB. Used in tandem with 'needs_custom_disk_space'."
  type        = number
  default     = null
}

variable "bootstrap_cluster" {
  description = "Determines whether or not the Kubernetes cluster is bootstrapped."
  type        = bool
  default     = false
}