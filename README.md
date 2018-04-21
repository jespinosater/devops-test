# DevOps Technical test

### Overview

This repository contains a collection of Terraform and bash scripts that create an environment on AWS.

This environment consists of three identical t2.micro instances with the free-tier Ubuntu image deployed on them. 

After the instances are created, the process will install [NetData](https://my-netdata.io/) in two of them, setting them up in Master-Slave mode, and it will install [Docker](https://www.docker.com/) and deploy [Graphite](https://graphiteapp.org/) and [Grafana](https://grafana.com/) images in it. Then, the NetData master will be configured to output its data to Graphite and Grafana can be configured to show the data stored in Graphite.

## Installation process

### Pre-requisites

The installation process requires Terraform running on the machine that is going to be executing these scripts. A guide on how to install it can be found on its [homepage](https://www.terraform.io/).

At the time of writting this, `terraform version` shows the following:

```
Terraform v0.11.7
+ provider.aws v1.14.1
+ provider.local v1.1.0
+ provider.null v1.0.0
```

You will also need an AWS access and secret key. For a guide on how to get them, follow this [link](https://docs.aws.amazon.com/general/latest/gr/managing-aws-access-keys.html).

Once you have Terraform and AWS keys, continue to the next step.

### Deployment

First, clone the repository:

```
git clone https://github.com/jespinosater/devops-test.git`
```

After it finishes, `cd` into it and create a file named `terraform.tfvars` with the following contents:

```
access_key = "Your AWS access key"
secret_key = "You AWS secret key"
allowed_ip = "Range of IPs allowed to connect to SSH"
```

The `allowed_ip` variable is passed later to the terraform scritps to set up SSH in a way that it only allows incoming connections from the range specified in it. In case you want to specify only one address and not a range, end your public IP address with `/32`:

`allowed_ip = "your_ip/32"`

Once you finish editing the file, run `terraform init`. This will download the required modules for it to run and provision the environment.

After the command completes, use `terraform plan` to show the estimated output of the execution. If you follow the command with `terraform apply` it will try to provision the environment and deploy the applications to AWS.

If there are no error, the script will finish showing the three public IP addresses of the servers. They will also be mapped to terraform outputs, so they can be used programatically in the console, as in `ssh user@$(terraform output public_ip_1)` to begin an SSH connection to the NetData master server.

### Environment destruction

To destroy the provisioned environment just run `terraform destroy`. This will delete everything created in AWS and also delete de local SSH keys created to access the machines.

### Implementation details

The overview of the complete process is the following:

1. Generate an SSH key pair without password, store its private key in `ssh/test_key` and store its public key in `ssh/test_key.pub`. This is defined in `ssh-create.tf`.

2. Generate the network (VPC, subnets, internet gateway and route table). The network and subnets sizes are defined in `variables.tf` file. By default, the VPC is in the range `172.31.0.0/16`, the public subnet is `172.31.0.0/24` and the private subnet is `172.31.1.0/24` (not in use in the final version of the provisioning).

3. Define the security groups that will be assigned to the instances. There are 3 of them:
    
    * **Local**: Allows all traffic between hosts in that belong to this security group.
    
    * **SSH Access**: Allows the IP or range of IP's defined in `allowed_ip` variable inside `terraform.tfvars` file to connect to port 22.

    * **Outbound access**: Allow the assigned instances to initiate outbound connections needed to update or install software.

4. Create the instances. This step creates three instances, by default Ubuntu base images in t2.micro instances in eu-west-1 region. This can be changed in `variables.tf` file. These instances have the public key generated in step one added to them to allow SSH to work without passwords. Each machine gets a public IP assigned to them.

5. For the Master and Slave instances, NetData is installed using the script available in their website. A copy of the script can be found on  `resources/` to copy it through SSH and execute it in both machines. After the installation, the settings required to configure the Master-Slave mode and for the Master to send its data to Graphite are modified and the NetData services restarted for the configuration to take effect.

6. In the third instance Docker is installed as a startup script. The script can be found on `resources/docker-install.sh`. The script will create the `docker` group, assign the user `ubuntu` to it and run the required software installations and repository changes to install Docker.

7. After Docker is installed, the containers [Graphite](https://hub.docker.com/r/graphiteapp/docker-graphite-statsd/) and [Grafana](https://hub.docker.com/r/grafana/grafana/) are installed. The port mappings can be checked in `docker.tf` file.


## Result checking

To avoid exposing the applications to the open internet, we will use SSH-Agent and SSH port forwarding to connect to each of the machines and open the running applications.

In the same directory that we run `terraform apply`, type the following commands to execute SSH-Agent and load the private key onto it:

```
eval $(ssh-agent)

ssh-add ssh/test_key
```

After this, it's possible to connect to each one of the instances with the following commands since we exported each public IP into a terraform output variable:

```
ssh ubuntu@$(terraform output public_ip_1)
ssh ubuntu@$(terraform output public_ip_2)
ssh ubuntu@$(terraform output public_ip_3)
```

To use the port forwarding feature of SSH, we will use the commands aboe as this instead:

```
ssh -nNT -L 19998:127.0.0.1:19999 ubuntu@$(terraform output public_ip_1)
```

The flag `-L`, makes SSH redirect port `19998` in `127.0.0.1` to destiny host's port `19999` (that's the one where netdata is running). The flags `-nNT` execute the command associating the standard input to `/dev/null`, setting up only the tunnel and not wait for commands and to not allocate a tty in the remote system.

Now, you can navigate to http://127.0.0.1:19998 in your local browser to see the NetData dashboard.

In the upper-left cornet, pressing `my-netdata`, you can select the slave machine to show its data.

Next, close the tunnel pressing `Ctrl + C` in the terminal window and run:

```
ssh -nNT -L 8080:127.0.0.1:80 ubuntu@$(terraform output public_ip_3)
```

to check the Graphite dashboard. Now, open http://127.0.0.1:8080 to see the Graphite dashboard.

In the left pannel, inside `Metrics > netdata`, the statistics sent by the NetData master can be seen.

Now, to check the grafana dashboard and build custom panels, close the current tunnel with `Ctrl + C` again and run:

```
ssh -nNT -L 3000:127.0.0.1:3000 ubuntu@$(terraform output public_ip_3)
```

and open http://127.0.0.1:3000 to see the Grafana login screen.

The default user and password is `admin`. After this, Grafana will ask to configure a datasource. Enter the following details:

* **Name**: Graphite
* **Type**: Graphite
* **URL**: http://localhost:80
* **Access**: Proxy
* **Auth checks**: Leave all unchecked
* **Whitelisted cookies**: Leave empty
* **Version**: 1.1.x

And press `Save & Test`. The green checkmark and `Data source is working` should show. After this, it's possible to create a new dashboard that has access to the metrics stored in Graphite.
