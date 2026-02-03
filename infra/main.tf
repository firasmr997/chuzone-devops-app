provider "aws" {
  region = "us-west-2"
}

data "aws_ami" "ubuntu" {
  most_recent = true
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
  owners = ["099720109477"] # Canonical
}

resource "aws_vpc" "k8s_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  tags = {
    Name = "chuzone-k8s-vpc"
  }
}

resource "aws_internet_gateway" "k8s_igw" {
  vpc_id = aws_vpc.k8s_vpc.id
  tags = {
    Name = "chuzone-k8s-igw"
  }
}

resource "aws_subnet" "k8s_subnet" {
  vpc_id                  = aws_vpc.k8s_vpc.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "us-west-2a"
  tags = {
    Name = "chuzone-k8s-subnet"
  }
}

resource "aws_route_table" "k8s_rt" {
  vpc_id = aws_vpc.k8s_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.k8s_igw.id
  }

  tags = {
    Name = "chuzone-k8s-rt"
  }
}

resource "aws_route_table_association" "k8s_rta" {
  subnet_id      = aws_subnet.k8s_subnet.id
  route_table_id = aws_route_table.k8s_rt.id
}

resource "aws_security_group" "k8s_sg" {
  name        = "k8s-sg"
  description = "Allow all necessary ports for K8s"
  vpc_id      = aws_vpc.k8s_vpc.id

  # SSH
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # K8s API (6443)
  ingress {
    from_port   = 6443
    to_port     = 6443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Internal Communication (All)
  ingress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"
    self      = true
  }
  
  # NodePort Services Range
  ingress {
    from_port   = 30000
    to_port     = 32767
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Initial HTTP/HTTPS Access (if via LoadBalancer/Ingress directly exposed)
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}



resource "aws_key_pair" "k8s_key" {
  key_name   = "labsuser"
  public_key = file("${path.module}/../labsuser.pub") 
}

resource "aws_instance" "master" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t2.medium"
  subnet_id     = aws_subnet.k8s_subnet.id
  key_name      = aws_key_pair.k8s_key.key_name
  vpc_security_group_ids = [aws_security_group.k8s_sg.id]
  user_data = file("${path.module}/install_k8s.sh")

  root_block_device {
    volume_size = 16
  }

  tags = {
    Name = "k8s-master"
    Role = "master"
  }
}

resource "aws_instance" "worker" {
  count         = 2
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t2.medium"
  subnet_id     = aws_subnet.k8s_subnet.id
  key_name      = aws_key_pair.k8s_key.key_name
  vpc_security_group_ids = [aws_security_group.k8s_sg.id]
  user_data = file("${path.module}/install_k8s.sh")

  root_block_device {
    volume_size = 16
  }

  tags = {
    Name = "k8s-worker-${count.index + 1}"
    Role = "worker"
  }
}
