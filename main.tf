provider "aws" {
  region = "us-east-1"
}

# 1. إنشاء مجموعة أمان لفتح منفذ الويب 80 مع اسم فريد
resource "aws_security_group" "web_sg_v2" {
  name        = "web-server-sg-v2" # تم تغيير الاسم هنا لحل مشكلة التكرار
  description = "Allow HTTP inbound traffic"

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

# 2. إنشاء السيرفر وربطه بمجموعة الأمان الجديدة
resource "aws_instance" "my_advanced_server" {
  ami           = "ami-0c02fb55956c7d316" # تأكد أن هذا الـ AMI متاح في us-east-1
  instance_type = "t2.micro"
  
  # ربط السيرفر بمجموعة الأمان المحدثة
  vpc_security_group_ids = [aws_security_group.web_sg_v2.id]

  # كود الأتمتة: تثبيت خادم ويب عند التشغيل
  user_data = <<-EOF
              #!/bin/bash
              yum update -y
              yum install -y httpd
              systemctl start httpd
              systemctl enable httpd
              echo "<h1>Welcome to my DevSecOps Platform - Deployed by Terraform</h1>" > /var/www/html/index.html
              EOF

  tags = {
    Name = "DevOps-Advanced-Server-V2"
  }
}

# 3. إظهار عنوان السيرفر فور انتهائه
output "server_public_ip" {
  value = aws_instance.my_advanced_server.public_ip
}