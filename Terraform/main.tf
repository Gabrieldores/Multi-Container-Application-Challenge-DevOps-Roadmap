terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# ─── Variáveis ────────────────────────────────────────────────────────────────

variable "aws_access_key" {
  description = "AWS Access Key ID"
  type        = string
  sensitive   = true
}

variable "aws_secret_key" {
  description = "AWS Secret Access Key"
  type        = string
  sensitive   = true
}

variable "region" {
  description = "Região AWS"
  type        = string
  default     = "us-east-1"
}

variable "instance_type" {
  description = "Tipo da instância EC2"
  type        = string
  default     = "t3.micro" # Free tier elegível
}

variable "ssh_public_key_path" {
  description = "Caminho para sua chave SSH pública"
  type        = string
  default     = "~/.ssh/id_rsa.pub"
}

variable "ssh_private_key_path" {
  description = "Caminho para sua chave SSH privada"
  type        = string
  default     = "~/.ssh/id_rsa"
}

variable "docker_image" {
  description = "Imagem Docker da API (ex: seu-usuario/todo-api)"
  type        = string
}

variable "image_tag" {
  description = "Tag da imagem Docker"
  type        = string
  default     = "latest"
}

# ─── Provider ─────────────────────────────────────────────────────────────────

provider "aws" {
  region     = var.region
  access_key = var.aws_access_key
  secret_key = var.aws_secret_key
}

# ─── Data Sources ─────────────────────────────────────────────────────────────

# Ubuntu 22.04 LTS mais recente
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical (oficial Ubuntu)

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# ─── Rede (VPC + Subnet + Internet Gateway) ───────────────────────────────────

resource "aws_vpc" "todo_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name    = "todo-app-vpc"
    Project = "todo-app"
  }
}

resource "aws_subnet" "todo_subnet" {
  vpc_id                  = aws_vpc.todo_vpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "${var.region}a"
  map_public_ip_on_launch = true

  tags = {
    Name    = "todo-app-subnet"
    Project = "todo-app"
  }
}

resource "aws_internet_gateway" "todo_igw" {
  vpc_id = aws_vpc.todo_vpc.id

  tags = {
    Name    = "todo-app-igw"
    Project = "todo-app"
  }
}

resource "aws_route_table" "todo_rt" {
  vpc_id = aws_vpc.todo_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.todo_igw.id
  }

  tags = {
    Name    = "todo-app-rt"
    Project = "todo-app"
  }
}

resource "aws_route_table_association" "todo_rta" {
  subnet_id      = aws_subnet.todo_subnet.id
  route_table_id = aws_route_table.todo_rt.id
}

# ─── Security Group ───────────────────────────────────────────────────────────

resource "aws_security_group" "todo_sg" {
  name        = "todo-app-sg"
  description = "Security Group para a aplicacao Todo"
  vpc_id      = aws_vpc.todo_vpc.id

  # SSH
  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # HTTP via Nginx
  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # API direta (opcional, remova se quiser apenas via Nginx)
  ingress {
    description = "API Node.js"
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Todo tráfego de saída liberado
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name    = "todo-app-sg"
    Project = "todo-app"
  }
}

# ─── Key Pair SSH ─────────────────────────────────────────────────────────────

resource "aws_key_pair" "todo_key" {
  key_name   = "todo-app-key"
  public_key = file(var.ssh_public_key_path)

  tags = {
    Project = "todo-app"
  }
}

# ─── Instância EC2 ────────────────────────────────────────────────────────────

resource "aws_instance" "todo_server" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.instance_type
  key_name               = aws_key_pair.todo_key.key_name
  subnet_id              = aws_subnet.todo_subnet.id
  vpc_security_group_ids = [aws_security_group.todo_sg.id]

  root_block_device {
    volume_size = 20    # GB
    volume_type = "gp3"
    encrypted   = true
  }

  # Script de inicialização — instala Docker automaticamente no boot
  user_data = <<-EOF
    #!/bin/bash
    set -e

    # Atualizar sistema
    apt-get update -y
    apt-get upgrade -y

    # Instalar dependências
    apt-get install -y apt-transport-https ca-certificates curl gnupg lsb-release

    # Adicionar repositório Docker
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null

    # Instalar Docker
    apt-get update -y
    apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin

    # Iniciar Docker
    systemctl start docker
    systemctl enable docker

    # Criar diretório da aplicação
    mkdir -p /opt/todo-app/nginx

    # Sinalizar que o user_data finalizou
    touch /tmp/user_data_done
  EOF

  tags = {
    Name    = "todo-app-server"
    Project = "todo-app"
    Env     = "production"
  }
}

# ─── IP Elástico (IP fixo que não muda ao reiniciar) ─────────────────────────

resource "aws_eip" "todo_eip" {
  instance = aws_instance.todo_server.id
  domain   = "vpc"

  tags = {
    Name    = "todo-app-eip"
    Project = "todo-app"
  }

  depends_on = [aws_internet_gateway.todo_igw]
}

# ─── Deploy da aplicação via SSH ──────────────────────────────────────────────

resource "null_resource" "deploy_app" {
  depends_on = [aws_eip.todo_eip]

  triggers = {
    image_tag    = var.image_tag
    docker_image = var.docker_image
    instance_id  = aws_instance.todo_server.id
  }

  connection {
    type        = "ssh"
    host        = aws_eip.todo_eip.public_ip
    user        = "ubuntu"
    private_key = file(var.ssh_private_key_path)
    timeout     = "10m"
  }

  # Esperar o user_data terminar antes de continuar
  provisioner "remote-exec" {
    inline = [
      "echo 'Aguardando inicialização da instância...'",
      "while [ ! -f /tmp/user_data_done ]; do sleep 5; echo 'Aguardando...'; done",
      "echo 'Instância pronta!'"
    ]
  }

  # Enviar docker-compose de produção
  provisioner "file" {
    source      = "${path.module}/../docker-compose.prod.yml"
    destination = "/opt/todo-app/docker-compose.yml"
  }

  # Enviar configuração do Nginx
  provisioner "file" {
    source      = "${path.module}/../nginx/nginx.conf"
    destination = "/opt/todo-app/nginx/nginx.conf"
  }

  # Subir a aplicação
  provisioner "remote-exec" {
    inline = [
      "cd /opt/todo-app",
      "docker pull ${var.docker_image}:${var.image_tag}",
      "DOCKER_IMAGE=${var.docker_image} IMAGE_TAG=${var.image_tag} docker compose up -d --force-recreate",
      "docker image prune -f",
      "docker compose ps"
    ]
  }
}

# ─── Outputs ──────────────────────────────────────────────────────────────────

output "server_ip" {
  value       = aws_eip.todo_eip.public_ip
  description = "IP público fixo do servidor"
}

output "app_url" {
  value       = "http://${aws_eip.todo_eip.public_ip}"
  description = "URL da aplicação via Nginx"
}

output "api_url" {
  value       = "http://${aws_eip.todo_eip.public_ip}:3000"
  description = "URL direta da API"
}

output "ssh_command" {
  value       = "ssh ubuntu@${aws_eip.todo_eip.public_ip} -i ${var.ssh_private_key_path}"
  description = "Comando SSH para acessar o servidor"
}
