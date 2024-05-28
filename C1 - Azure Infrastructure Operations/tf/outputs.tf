output "resource_group_name" {
  value = data.azurerm_resource_group.rg.name
}

output "public_ip_address_1" {
  value = azurerm_linux_virtual_machine.my_linux_virtual_machine[0].public_ip_address
}

output "public_ip_address_2" {
  value = azurerm_linux_virtual_machine.my_linux_virtual_machine[1].public_ip_address
}

output "tls_private_key" {
  value     = tls_private_key.my_ssh.private_key_pem
  sensitive = true
}
