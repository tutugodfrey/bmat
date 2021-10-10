#! /bin/bash

# Require input paremeter for the master password for the database
if [ -z $1 ]; then
  echo Please provide the password for the Master database!
  exit;
fi

aws cloudformation deploy --stack-name bmat-vpc-stack --template-file vpc.yml;

aws cloudformation deploy --stack-name bmat-security-group --template-file security-groups.yml;

aws cloudformation deploy --stack-name bmat-shared-efs --template-file shared-efs.yml;

aws cloudformation deploy --stack-name bmat-nat-gateway --template-file nat-gateway.yml;

aws cloudformation deploy --stack-name bmat-webserver-lb --template-file load-balancer.yml;

aws cloudformation deploy --stack-name bmat-web-server-stack --template-file app-servers.yml;

aws cloudformation deploy --stack-name bmat-sftp-server-stack --template-file sftp-server.yml;

aws cloudformation deploy --stack-name bmat-worker-servers --template-file worker-servers.yml;


export DB_MASTER_PASSWORD=$1

# To create RDS without read replicas
# aws cloudformation  deploy --stack-name bmat-postgres-rds --template-file rds-stack.yml --parameter-overrides DBMasterPassword=${DB_MASTER_PASSWORD} --parameter-overrides CreateReadReplica=false;

aws cloudformation  deploy --stack-name bmat-postgres-rds --template-file rds-stack.yml --parameter-overrides DBMasterPassword=${DB_MASTER_PASSWORD};

# aws cloudformation deploy --stack-name mbat-rds-read-replica --template-file rds-replica-stack.yml;

aws cloudformation deploy --stack-name bmat-sqs-queue --template-file sqs-queue.yml;
