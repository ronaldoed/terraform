provider "aws" {
}

data "aws_vpc" "default" {
}
data "aws_availability_zones" "default" {
}

data "aws_subnet_ids" "default" {
  vpc_id = "${aws_vpc.default.id}"
}

data "aws_subnet" "default" {
  count = "${length(data.aws_subnet_ids.default.ids)}"
  id = "${data.aws_subnet_ids.default.ids[count.index]}"
}

resource "aws_ecr_repository" "default" {
    name = "wp_ecr" 
    provisioner "local-exec" {
        command = "sed -i '/repository/c \\\t\\\"repository\\\": \\\"${aws_ecr_repository.default.repository_url}\\\",' wp_supervisor/wp_docker_packer_vars.json;url=\"${aws_ecr_repository.default.repository_url}\";na=\"${aws_ecr_repository.default.name}\";loginserver=\"$${url%$na}\";sed -i \"/login_server/c \\\t\\\"login_server\\\": \\\"$loginserver\\\"\" wp_supervisor/wp_docker_packer_vars.json"
    }
    provisioner "local-exec" {
        command = "sed -i '/repository/c \\\t\\\"repository\\\": \\\"${aws_ecr_repository.default.repository_url}\\\",' wp_systemd/wp_docker_packer_vars.json;url=\"${aws_ecr_repository.default.repository_url}\";na=\"${aws_ecr_repository.default.name}\";loginserver=\"$${url%$na}\";sed -i \"/login_server/c \\\t\\\"login_server\\\": \\\"$loginserver\\\"\" wp_systemd/wp_docker_packer_vars.json"
    }
}

resource "aws_ecr_repository_policy" "default" {
    repository = "${aws_ecr_repository.default.name}"
    policy = <<EOF
    {
        "Version": "2008-10-17",
        "Statement": [
            {
                "Sid": "wp_ecr_policy",
                "Effect": "Allow",
                "Principal": "*",
                "Action": [
                    "ecr:GetDownloadUrlForLayer",
                    "ecr:BatchGetImage",
                    "ecr:BatchCheckLayerAvailability",
                    "ecr:PutImage",
                    "ecr:InitiateLayerUpload",
                    "ecr:UploadLayerPart",
                    "ecr:CompleteLayerUpload",
                    "ecr:DescribeRepositories",
                    "ecr:GetRepositoryPolicy",
                    "ecr:ListImages",
                    "ecr:DeleteRepository",
                    "ecr:BatchDeleteImage",
                    "ecr:SetRepositoryPolicy",
                    "ecr:DeleteRepositoryPolicy"
                ]
            }
        ]
    }
    EOF
}

resource "aws_vpc" "default" {
    cidr_block = "172.31.0.0/16"
}

resource "aws_security_group" "db_security_group" {
    name = "db security group"
    description = "only allow db traffic 3306"
    vpc_id = "${aws_vpc.default.id}"
  
    ingress {
        from_port = 3306
        to_port = 3306 
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
  
    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }
}

resource "aws_security_group" "ecs_alb_sg" {
    name = "ecs alb security group"
    description = "only allow http traffic 80"
    vpc_id = "${aws_vpc.default.id}"
  
    ingress {
        from_port = 80 
        to_port = 80
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
  
    ingress {
        from_port = 443 
        to_port = 443
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }
}

resource "aws_subnet" "default_subnet_1" {
    assign_ipv6_address_on_creation = false
    availability_zone = "${data.aws_availability_zones.default.names[0]}"
    cidr_block = "${cidrsubnet(data.aws_vpc.default.cidr_block, 4, 0)}"
    map_public_ip_on_launch = true
    vpc_id = "${aws_vpc.default.id}"
}

resource "aws_subnet" "default_subnet_2" {
    assign_ipv6_address_on_creation = false
    availability_zone = "${data.aws_availability_zones.default.names[2]}"
    cidr_block = "${cidrsubnet(data.aws_vpc.default.cidr_block, 4, 1)}"
    map_public_ip_on_launch = true
    vpc_id = "${aws_vpc.default.id}"
}

resource "aws_subnet" "default_subnet_3" {
    assign_ipv6_address_on_creation = false
    availability_zone = "${data.aws_availability_zones.default.names[3]}"
    cidr_block = "${cidrsubnet(data.aws_vpc.default.cidr_block, 4, 2)}"
    map_public_ip_on_launch = true
    vpc_id = "${aws_vpc.default.id}"
}

resource "aws_subnet" "default_subnet_4" {
    assign_ipv6_address_on_creation = false
    availability_zone = "${data.aws_availability_zones.default.names[4]}"
    cidr_block = "${cidrsubnet(data.aws_vpc.default.cidr_block, 4, 3)}"
    map_public_ip_on_launch = true
    vpc_id = "${aws_vpc.default.id}"
}

resource "aws_db_instance" "default" {
    depends_on = ["aws_security_group.db_security_group"]
    identifier = "${var.identifier}"
    allocated_storage = "${var.allocated_storage}"
    engine = "${var.engine}"
    engine_version = "${var.engine_version}"
    instance_class = "${var.instance_class}"
    name = "${var.db_name}"
    username = "${var.db_username}"
    password = "${var.db_password}"
    multi_az = true
    skip_final_snapshot = true
    vpc_security_group_ids = ["${aws_security_group.db_security_group.id}"]
    db_subnet_group_name = "${aws_db_subnet_group.default.id}"
    provisioner "local-exec" {
        command = "sed -i \"s/wp_dbhost: .*/wp_dbhost: \\\"${aws_db_instance.default.address}\\\"/g\" wp_supervisor/wp_docker_packer_vars.yml"
    }
    provisioner "local-exec" {
        command = "sed -i \"s/wp_dbhost: .*/wp_dbhost: \\\"${aws_db_instance.default.address}\\\"/g\" wp_systemd/wp_docker_packer_vars.yml"
    }
}

resource "aws_db_subnet_group" "default" {
    name = "db subnet group"
    description = "db subnet group for rds instance"
    subnet_ids = ["${aws_subnet.default_subnet_2.id}", "${aws_subnet.default_subnet_4.id}"]
}

resource "aws_iam_role" "ec2_instance_role" {
    name = "ec2-instance-role"
    assume_role_policy = <<EOF
{
    "Version": "2008-10-17",
    "Statement": [
        {
            "Sid": "",
            "Effect": "Allow",
            "Principal": {
                "Service": "ec2.amazonaws.com"
            },
            "Action": "sts:AssumeRole"
        }
    ]
}
EOF
}

resource "aws_iam_role_policy" "ec2_instance_policy" {
    name = "ec2-instance-policy"
    role = "${aws_iam_role.ec2_instance_role.id}"
    policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "ecs:CreateCluster",
                "ecs:DeregisterContainerInstance",
                "ecs:DiscoverPollEndpoint",
                "ecs:Poll",
                "ecs:RegisterContainerInstance",
                "ecs:StartTelemetrySession",
                "ecs:Submit*",
                "ecr:GetAuthorizationToken",
                "ecr:BatchCheckLayerAvailability",
                "ecr:GetDownloadUrlForLayer",
                "ecr:BatchGetImage",
                "logs:CreateLogStream",
                "logs:PutLogEvents"
            ],
            "Resource": "*"
        }
    ]
}
EOF
}

resource "aws_iam_role" "ecs_service_role" {
    name = "ecs-service-role"
    assume_role_policy = <<EOF
{
    "Version": "2008-10-17",
    "Statement": [
        {
            "Sid": "",
            "Effect": "Allow",
            "Principal": {
                "Service": "ecs.amazonaws.com"
            },
            "Action": "sts:AssumeRole"
        }
    ]
}
EOF
}

resource "aws_iam_role_policy" "ecs_service_policy" {
    name = "ecs-service-policy"
    role = "${aws_iam_role.ecs_service_role.id}"
    policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "ec2:AuthorizeSecurityGroupIngress",
                "ec2:Describe*",
                "elasticloadbalancing:DeregisterInstancesFromLoadBalancer",
                "elasticloadbalancing:DeregisterTargets",
                "elasticloadbalancing:Describe*",
                "elasticloadbalancing:RegisterInstancesWithLoadBalancer",
                "elasticloadbalancing:RegisterTargets"
            ],
            "Resource": "*"
        }
    ]
}
EOF
}

resource "aws_iam_role" "ecs_asg_role" {
    name = "ecs-asg-role"
    assume_role_policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": {
                "Service": "application-autoscaling.amazonaws.com"
            },
            "Action": "sts:AssumeRole"
        }
    ]
}
EOF
}

resource "aws_iam_role_policy" "ecs_asg_policy" {
    name = "ecs-asg-policy"
    role = "${aws_iam_role.ecs_asg_role.id}"
    policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "ecs:DescribeServices",
                "ecs:UpdateService"
            ],
            "Resource": [
                "*"
            ]
        }
    ]
}
EOF
}

resource "aws_alb_target_group" "ecs_alb_tg" {
    name = "ecs-alb-target"
    port = 80
    protocol = "HTTP"
    vpc_id = "${aws_vpc.default.id}"
    health_check {
        path = "/wp-admin/install.php"
        unhealthy_threshold = "5"
        interval = "10"
    }
}

resource "aws_alb" "ecs_alb" {
    name = "ecs-alb"
    subnets = ["${aws_subnet.default_subnet_1.id}", "${aws_subnet.default_subnet_2.id}", "${aws_subnet.default_subnet_3.id}"]
    security_groups = ["${aws_security_group.ecs_alb_sg.id}"]
}

resource "aws_alb_listener" "ecs_alb_listener" {
    load_balancer_arn = "${aws_alb.ecs_alb.id}"
    port = "80"
    protocol = "HTTP"
  
    default_action {
        target_group_arn = "${aws_alb_target_group.ecs_alb_tg.id}"
        type = "forward"
    }
}

resource "aws_ecs_cluster" "default" {
    name = "wp-ecs-cluster"
}

resource "aws_ecs_task_definition" "default" {
    family = "wp-ecs-task"
    container_definitions = <<EOF
[{
    "name": "mywpresupervisord",
    "image": "${aws_ecr_repository.default.repository_url}:mywpresupervisord",
    "cpu": 20,
    "memory": 256,
    "essential": true,
    "portMappings": [
    {
        "containerPort": 80,
        "hostPort": 80
    }
    ]
}]
EOF
}

resource "aws_ecs_service" "default" {
    name = "wp-ecs-service"
    cluster = "${aws_ecs_cluster.default.id}"
    task_definition = "${aws_ecs_task_definition.default.arn}"
    desired_count = 2
    iam_role = "${aws_iam_role.ecs_service_role.name}"
    depends_on = [
        "aws_ecs_task_definition.default",
        "aws_iam_role_policy.ecs_service_policy",
        "aws_alb_listener.ecs_alb_listener",
    ]
    load_balancer {
        target_group_arn = "${aws_alb_target_group.ecs_alb_tg.id}"
        container_name = "mywpresupervisord"
        container_port = 80
    }
}
data "aws_ami" "ecs_ami" {
    most_recent = true
  
    filter {
        name   = "name"
        values = ["*ecs-optimized*"]
    }
  
    filter {
        name   = "architecture"
        values = ["x86_64"]
    }
  
    filter {
        name   = "virtualization-type"
        values = ["hvm"]
    }

    filter {
        name   = "description"
        values = ["*ECS HVM GP2*"]
    }
  
    #owners = ["595879546273"]
}

resource "aws_iam_instance_profile" "ecs_iam_ip" {
    name  = "ecs-iam-ip"
    role = "${aws_iam_role.ec2_instance_role.name}"
}

resource "aws_autoscaling_group" "ecs_asg" {
    name = "ecs-asg"
    vpc_zone_identifier = ["${aws_subnet.default_subnet_1.id}", "${aws_subnet.default_subnet_2.id}", "${aws_subnet.default_subnet_3.id}", "${aws_subnet.default_subnet_4.id}"]
    min_size = "2"
    max_size = "4"
    desired_capacity = "2"
    launch_configuration = "${aws_launch_configuration.ecs_lc.name}"
}

resource "aws_launch_configuration" "ecs_lc" {
    security_groups = ["${aws_security_group.ecs_alb_sg.id}"]
    image_id = "${data.aws_ami.ecs_ami.id}"
    #image_id = "ami-62745007"
    key_name = "gregkey"
    instance_type = "t2.small"
    iam_instance_profile = "${aws_iam_instance_profile.ecs_iam_ip.name}"
    user_data = "#!/bin/bash\necho ECS_CLUSTER=wp-ecs-cluster >> /etc/ecs/ecs.config"
    associate_public_ip_address = true
    lifecycle {
        create_before_destroy = true
    }
}

output "aws_vpc_id" {
    value = "${aws_vpc.default.id}"
}

output "aws_vpc_cidr" {
    value = "${aws_vpc.default.cidr_block}"
}

output "aws_ecr_repo_arn" {
    value = "${aws_ecr_repository.default.arn}"
}

output "aws_ecr_repo_id" {
    value = "${aws_ecr_repository.default.repository_id}"
}

output "aws_ecr_repo_url" {
    value = "${aws_ecr_repository.default.repository_url}"
}

output "aws_alb_dns" {
    value = "${aws_alb.ecs_alb.dns_name}"
}

output "subnets" {
    value = ["${data.aws_subnet.default.count}"]
}

output "subnet_cidr_blocks" {
    value = ["${data.aws_subnet.default.*.cidr_block}"]
}

output "subnet_ids" {
    value = ["${data.aws_subnet.default.*.id}"]
}

output "image ids" {
    value = "${data.aws_ami.ecs_ami.id}"
}
