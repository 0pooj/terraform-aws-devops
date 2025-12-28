provider "aws" {
  region = "us-east-1"
}

# 1. تحديث مجموعة الأمان لفتح منافذ ArgoCD (8080 و 443)
resource "aws_security_group" "devops_sg_v4" {
  name        = "devops-platform-sg-v4"
  description = "Security group for GitOps Platform"

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 8080
    to_port     = 8080
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

# 2. إنشاء السيرفر مع تنصيب ArgoCD آلياً
resource "aws_instance" "devops_node" {
  ami           = "ami-0c02fb55956c7d316"
  instance_type = "t3.medium"
  
  vpc_security_group_ids = [aws_security_group.devops_sg_v4.id]

  user_data = <<-EOF
              #!/bin/bash
              # تحديث النظام وتثبيت Docker
              yum update -y
              amazon-linux-extras install docker -y
              systemctl start docker
              systemctl enable docker
              
              # تثبيت K3s (Kubernetes)
              curl -sfL https://get.k3s.io | sh -
              
              # انتظار حتى يصبح ملف الـ Kubeconfig جاهزاً (حوالي دقيقة)
              sleep 60
              export KUBECONFIG=/etc/rancher/k3s/k3s.yaml
              chmod 644 /etc/rancher/k3s/k3s.yaml

              # تنصيب ArgoCD
              kubectl create namespace argocd
              kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproject/argo-cd/stable/manifests/install.yaml
              
              # جعل ArgoCD متاحاً عبر منفذ 8080 (NodePort) لسهولة الوصول
              kubectl patch svc argocd-server -n argocd -p '{"spec": {"type": "NodePort"}}'
              kubectl patch svc argocd-server -n argocd --type='json' -p '[{"op":"replace","path":"/spec/ports/0/nodePort","value":30080}]'
              EOF

  tags = {
    Name = "DevOps-GitOps-ArgoCD"
  }
}

output "argocd_url" {
  value = "http://${aws_instance.devops_node.public_ip}:30080"
}

output "node_ssh_access" {
  value = "ssh ec2-user@${aws_instance.devops_node.public_ip}"
}