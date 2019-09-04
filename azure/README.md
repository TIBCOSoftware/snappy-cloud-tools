# SnappyData on Azure
Automated SnappyData deployment on Microsoft Azure Cloud.


# Deploy the template via Azure portal

1. Click on
<a href="https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fsnappydatainc%2Fsnappy-cloud-tools%2Fmaster%2Fazure%2FmainTemplate.json">
<img src="https://camo.githubusercontent.com/9285dd3998997a0835869065bb15e5d500475034/687474703a2f2f617a7572656465706c6f792e6e65742f6465706c6f79627574746f6e2e706e67" data-canonical-src="http://azuredeploy.net/deploybutton.png" style="max-width:100%;">
</a>

2. Fill in details for the Azure Resource Manager (ARM) template.

3. Proceed to purchase.

This will start the deployment of the resources as outlined in the template, which typically takes few minutes.
Once completed, you can check its "Outputs" tab to find the required information about the cluster.

## Parameters in the Deployment Template

- **Artifacts Base Url**: Base URL for artifacts such as nested templates and scripts.

- **Location**: Location for the deployment.

- **Cluster Name**: Cluster name consisting of 2-4 lowercase letter and numbers.

- **DNS Name Prefix**: Globally unique DNS name.

- **Admin Username**: Username for administrator.

- **Authentication Type**: Authentication type for the virtual machines (Password/SSH Public Key).

- **Admin Password**: Password for administrator.

- **SSH Public Key**: SSH public key that will be included on all nodes in the cluster. The OpenSSH public key can be generated with tools like ssh-keygen on Linux or OS X.

- **Locator VM Size**: VM size for Locator.

- **Locator Node Count**: The number of virtual machine instances to provision for the locator nodes.

- **Lead And Data Store VM Size**: VM size for Lead and DataStore.

- **Data Store Node Count**: The number of virtual machine instances to provision for the DataStore nodes.

- **Lead Node Count**: The number of virtual machine instances to provision for the Lead nodes.

- **Launch Zeppelin**: If Apache Zeppelin server is to be launched on Lead instance (yes/no).

- **Allowed IP Address prefix**: The IP address range allowed to access the instances from outside Azure network.

- **Conf for Lead**: Configuration parameters for Lead.

- **Conf for Locator**: Configuration parameters for Locator.

- **Conf for Data Store**: Configuration parameters for DataStore.

- **SnappyData Download URL**: URL of SnappyData distribution to download. Uses the latest release from GitHub, if not specified.


# Inside the files

## mainTemplate.json

The template consists of four main sub-sections:

- **parameters**: Contains parameters with their default values, which the user can edit before deployment.

- **variables**: Variables required in subsequent sub-sections are declared inside this section.

- **resources**: This section defines various resources which will be created during deployment process. (e.g. Virtual Machines, Network Interfaces, Virtual Machine Extensions, Network Security Groups, etc.)

- **outputs**: This section defines output information for quick access to the Snappydata UI Console, URLs for establishing connections via snappy shell and JDBC.

## init.sh

This script launches Snappydata processes depending on the node type (Lead/Locator/DataStore). Also, it launches Apache Zeppelin server if the template parameter `launchZeppelin` is set to `yes`.


# Deploy using Azure CLI

You need to have Azure CLI installed and configured.
Switch to the directory where `mainTemplate.json` and `init.sh` is saved. Then run following commands:

```
$ azure account login

$ azure account set "My Subscription"

$ azure group list

$ azure group create --name snappydata1 --location westus

$ azure group deployment create --resource-group snappydata1 --name mainTemplate --template-file mainTemplate.json
```

