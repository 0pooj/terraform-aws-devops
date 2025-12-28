provider "aws" {
  region = "us-east-1"
}

# 1. مجموعة أمان تفتح المنافذ الضرورية لـ Docker و Kubernetes البسيط (K3s)
resource "aws_security_group" "devops_sg_v3" {
  name        = "devops-platform-sg-v3"
  description = "Security group for our DevSecOps platform"

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
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

# 2. إنشاء سيرفر بمواصفات تسمح بتشغيل Docker و ArgoCD لاحقاً
resource "aws_instance" "devops_node" {
  ami           = "ami-0c02fb55956c7d316" # Amazon Linux 2
  instance_type = "t3.medium" # مواصفات متوسطة لتشغيل أدواتك
  
  vpc_security_group_ids = [aws_security_group.devops_sg_v3.id]

  user_data = <<-EOF
              #!/bin/bash
              yum update -y
              amazon-linux-extras install docker -y
              systemctl start docker
              systemctl enable docker
              usermod -a -G docker ec2-user
              # تثبيت K3s (نسخة خفيفة من Kubernetes لـ GitOps)
              curl -sfL https://get.k3s.io | sh -
              EOF

  tags = {
    Name = "DevOps-GitOps-Node"
  }
}

output "node_public_ip" {
  value = aws_instance.devops_node.public_ip
}