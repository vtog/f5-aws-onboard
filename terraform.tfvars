aws_profile = "vtog"
aws_region  = "us-west-2"
vpc_cidr    = "10.1.0.0/16"

cidrs = {
  mgmt1     = "10.1.1.0/24"
  mgmt2     = "10.1.2.0/24"
  external1 = "10.1.3.0/24"
  external2 = "10.1.4.0/24"
  internal1 = "10.1.5.0/24"
  internal2 = "10.1.6.0/24"
}

AZ                   = 1 # Number of AZ's, "1" or "2"
key_name             = "bigip-lab-key"
public_key_path      = "~/.ssh/id_rsa.pub"
ubuntu_instance_type = "t3.medium"
ubuntu_count         = 2
bigip_instance_type  = "m5.large"
bigip_count          = 2

# BYOL
#bigip_ami_prod_code = "6h6xg9ndbxsrp5iyuotryhl0q"
#bigip_ami_name_filt = "F5 BIGIP-14.1* BYOL-LTM 2Boot*"

# PAYG
bigip_ami_prod_code  = "3ouya04g99e5euh4vbxtao1jz"
bigip_ami_name_filt  = "F5 BIGIP-15.0* PAYG-Best 25M*"
#bigip_ami_name_filt  = "F5 BIGIP-14.1* PAYG-Best 25M*"
#bigip_ami_name_filt  = "F5 Networks BIGIP-14.0* PAYG - Best 25M*"
#bigip_ami_name_filt  = "F5 Networks BIGIP-13.1* PAYG - Best 25M*"
#bigip_ami_name_filt  = "F5 Networks Licensed Hourly BIGIP-12.1* Best 25M*"

bigip_admin = "admin"
do_rpm      = "f5-declarative-onboarding-1.9.0-1.noarch.rpm"
as3_rpm     = "f5-appsvcs-3.16.0-6.noarch.rpm"
