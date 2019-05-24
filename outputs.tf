#--------root/outputs.tf--------
output "BIGIP Admin URL" {
  value = "${module.bigip.public_dns}"
}

output "BIGIP Mgmt IP" {
  value = "${module.bigip.public_ip}"
}

output "BIGIP Admin Password" {
  value = "${module.bigip.password}"
}
