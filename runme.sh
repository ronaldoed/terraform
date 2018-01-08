#!/bin/bash
if command -v docker 2>/dev/null && command -v ansible 2>/dev/null && command -v terraform 2>/dev/null && command -v packer 2>/dev/null 
then
    if [ -z "$AWS_ACCESS_KEY" ] || [ -z "$AWS_SECRET_KEY" ] || [ -z "$AWS_DEFAULT_REGION" ]
    then
        echo "Need AWS credentials and region env set."
        exit 1
    else
        echo "We are good to go!"
    fi
else
    echo "Please refer to README.MD!"
    exit 1
fi
terraform plan
terraform apply -target aws_ecr_repository.default -target aws_db_subnet_group.default -target aws_db_instance.default
cd wp_supervisor && packer build -var-file wp_docker_packer_vars.json wp_docker_packer.json
cd ..
cd wp_systemd && packer build -var-file wp_docker_packer_vars.json wp_docker_packer.json
cd ..
terraform apply
