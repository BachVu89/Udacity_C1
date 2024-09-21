variable "resource_group_location" {
  default     = "eastus"
  description = "Location of the resource group."
}

variable "packer_resource_group" {
  description = "Name of the resource group where the packer image is"
  default     =  "Azuredevops"
  type        = string
}

variable "username" {
  description = "The login of the virtual machines."
  default     = "bachvh"
  type        = string
}

variable "password" {
  description = "The password of the virtual machines."
  default     = "password@123A!"
  type        = string
}

variable "vm_count" {
  description = "The number of VM created"
  default     = 2
  type        = number
}