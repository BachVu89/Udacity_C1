variable "resource_group_location" {
  default     = "eastus"
  description = "Location of the resource group."
}

variable "packer_resource_group" {
  description = "Name of the resource group where the packer image is"
  default     =  "vm_ubuntu"
  type        = string
}

variable "username" {
  description = "The login of the virtual machines."
  default     = "ducda177"
  type        = string
}

variable "password" {
  description = "The password of the virtual machines."
  default     = "MyStr00ngP@$$w0rD"
  type        = string
}

variable "vm_count" {
  description = "The number of VM created"
  default     = 2
  type        = number
}
