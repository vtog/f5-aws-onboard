F5 AWS Onboard Lab
==================

The purpose of this repo is to give a set of scripts that deploy F5,
standalone, HA, one or two AZ's.

EC2 instances:

- F5 25M BEST BIG-IP (PAYG)

Several assumptions are made:

- An active AWS Account, with proper IAM configuration.
- Linux CLI (For my testing I used Debian)

  #. ~/.aws/credentials & config (properly configured)
  #. ~/.ssh/id_rsa & id_rsa.pub
  #. git, awscli, terraform, and ansible installed

- Familiarity with

  #. Terraform
  #. Ansible
  #. AWS CLI
  #. Big-IP

The following steps build the AWS EC2 instance:

.. code-block:: bash

   git clone https://github.com/vtog/aws-container-lab.git
   cd aws-container-lab
   terraform apply

After completion you can lookup the bigip1 mgmt url and passwd:

.. code-block:: bash

   terraform refresh
   terraform output

To completly remove the AWS instances and supporting objects, change directory
to the root of this cloned repo and run the following command:

.. code-block:: bash

   terraform destroy
