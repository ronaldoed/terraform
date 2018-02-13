# terraform
If you see this error
Build 'docker' errored: 1 error(s) occurred:
* Post-processor failed: UnrecognizedClientException: The security token included in the request is invalid.
status code: 400, request id: ef6b5149-f36a-11e7-abe6-abc658f96ca8
==> Some builds didn't complete successfully and had errors:
--> docker: 1 error(s) occurred:
* Post-processor failed: UnrecognizedClientException: The security token included in the request is invalid.
status code: 400, request id: ef6b5149-f36a-11e7-abe6-abc658f96ca8

then do below  
unset AWS_ACCESS_KEY_ID  
unset AWS_SECRET_ACCESS_KEY  
unset AWS_DEFAULT_REGION  

You must do this for terraform and etc.  

export AWS_ACCESS_KEY="YOUR_ACCESS_HERE"  
export AWS_SECRET_KEY="YOUR_SECRET_HERE"  
export AWS_DEFAULT_REGION="REGION"  

It's tested successfully on  
Terraform 0.9.5  
Packer 1.0.0  
Docker version 17.03.1-ce, build c6d412e  
Ansible 2.3.0.0  

terraform import aws_vpc.default "YOUR_DEFAULT_VPC"  
terraform import aws_subnet.default_subnet_1 "YOUR_DEFAULT_SUBNET_WITH_cidr_block, 4, 0"  
terraform import aws_subnet.default_subnet_2 "YOUR_DEFAULT_SUBNET_WITH_cidr_block, 4, 1"  
terraform import aws_subnet.default_subnet_3 "YOUR_DEFAULT_SUBNET_WITH_cidr_block, 4, 2"  
terraform import aws_subnet.default_subnet_4 "YOUR_DEFAULT_SUBNET_WITH_cidr_block, 4, 3"  
./runme.sh  
