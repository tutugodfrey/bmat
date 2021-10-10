# BMAT DevOps Test

Find instructions on how to provision infrastructure with AWS CloudFormation Stacks belows.

The CF Stacks to provision the infrastructures is located in the `./cf-stacks` directory relative to the project root directory.

Below I will provide a brief overview of what each of the stacks does. I like seperating out my stacks to keep them small and manageable.

**Note:** If you are executing the commands following the descriptions below, it is assume that you are in the `./cf-stacks` directory. So ensure you change your working directory to that directory. Most of the commands below assume the default parameters are being used. If you want to change any of the parameters, it can be done by providing the parameter to override like this `--parameter-overrides ParemeterName=ParameterValue`. Multiple of this can be provided for multiple parameters.

The `stack-helper.sh` script will provision all the infrastructure using the default parameters set in the stacks. Off course the script can be modified for an extended use.

#### Provision the VPC stack

The VPC stack will handle provisioning of the VPC, Subnets, Internet Gateway, Internet Gateway associations, Route table and route table to subnet associations etc. Values outputted from this stack will be imported to other stacks to provision infrastructures.

To create the VPC stack execute the command below.

```bash
aws cloudformation deploy --stack-name bmat-vpc-stack --template-file vpc.yml
```

#### Provision Security groups

The Securty Groups stack contains all definitions of security groups used throughout the infrastructure. To add or update a security group, you need to update the stack and ensure the value is exported to be used in other stacks.

To provision the Security group, execute the command below

```bash
aws cloudformation deploy --stack-name bmat-security-group --template-file security-groups.yml
```

#### Provision An shared EFS for the system

Since the system requires a huge storage solution shared across all components of the system, we are provisioning AWS EFS (Elastic File System) which is highly scalable, can expand and shrink based on usage. In this stack, we provision the EFS and mount points in the two publics subnets (covering two Availability Zone our infrastructure is deployed in). EFS can be mounted on EC2 instances to provide shared storage.

To provision the EFS, execute the command below.

```bash
aws cloudformation deploy --stack-name shared-efs --template-file shared-efs.yml
```

#### Provision NAT Gateway

To enable instances in private subnets such as the Workers to reach the internet, we are provisioning NAT Gateway. This will allow instance to make outbount connection to the internet. As infrastructure expands, we might likely have other resources in the private subnets that will also need outbount internet access. The nat instance will take care of that for out. The NAT instance is provision in a public subnet, then a route able in the private subnet will route outbound internet based traffic to the NAT Gateway from there it will be routed to the internet.

To provision the NAT Gateway, execute the command below

```bash
aws cloudformation deploy --stack-name bmat-nat-gateway --template-file nat-gateway.yml
```

#### Provision Load Balancer for the web server

The Load Balancer stack will provision a load balancer that will load balance traffic between web servers.

To provision the Load Balancer, execute the command below

```bash
aws cloudformation deploy --stack-name bmat-webserver-lb --template-file load-balancer.yml
```

#### Provision the Web server stack

This stack will provision the Web server under an autoscaling group. This will ensure that the web servers scale up and down depending on the amount of traffic the servers are receiving.

To provision the Web server, execute the command below.

```bash
aws cloudformation deploy --stack-name web-server-stack --template-file app-servers.yml
```

#### Create the SFTP Server stack

The SFTP stack will provision and EC2 instance to acts as the SFTP server. The Security group for the SFTP server allows connection on port 220 to serve SFTP traffic. The server should be configured to enable SFTP.

To provision the SFTP server, execute the command below.

```bash
aws cloudformation deploy --stack-name sftp-server-stack --template-file sftp-server.yml
```

#### Provision Worker servers in Private Subnet

The Workers are high performance processing of XML, CSV files. To enable scalability, the worker are provision under an autoscaling group.

To provision the Workers, execute the command below.

```bash
aws cloudformation deploy --stack-name bmat-worker-servers --template-file worker-servers.yml
```

#### Provision a PostgreSQL RDS Instance

For database solution with high insert and search performance, we use Amazon RDS with Read Replica, The stack below will create the Master database, and the Read replica stack will provision a read replica for the database solution. To execute the stack, you will need to provide the master password for the database. This can be exported to environment as shown below if you are using the command line.

Export the Master password to environment

```bash
export DB_MASTER_PASSWORD=REPLACE_WITH_VALUE_FOR_MASTER_PASSWORD
```

```bash
aws cloudformation  deploy --stack-name bmat-postgres-rds --template-file rds-stack.yml --parameter-overrides DBMasterPassword=${DB_MASTER_PASSWORD}
```

#### Create a Read Replica for the Database

This will take care of provisioning a Read Replica for the database

```bash
aws cloudformation deploy --stack-name mbat-rds-read-replica --template-file rds-replica-stack.yml
```

#### Create sqs queue

Amazon SQS provides a highly scalable queueing systems that meets the systems requirements. The stack will provision the SQS Queue for our infrastructure need.

To provision the SQS Queue, execute the command below.

```bash
aws cloudformation deploy --stack-name bmat-sqs-queue --template-file sqs-queue.yml
```

**Note** Across all stack there are two parameters that are required, `ProjectName`, and `Environment`. For `ProjectName` the default provided 
is `bmat-test`. For `Environment` the default provided is `Dev` and allowed values are `Dev`, `Test`, `Staging` and `Prod`. These paremeters are
used in resource naming and tagging to distinguish below between different environment and to ensure that the stacks are reusable across 
different environments. During provision, please ensure to select the appropriate paremeter depending on the environment.

Also, please note that it is important that the stacks are created in the order outline in this README because be some stack are depending on the output of other stacks.
