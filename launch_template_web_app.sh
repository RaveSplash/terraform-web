#!/bin/bash
set -x  # Enable debug mode
exec > >(tee -a /var/log/ec2-setup.log) 2>&1  # Append stdout and stderr to ec2-setup.log

echo "Script started at $(date)"

# Variables (to be replaced with actual values or Terraform variables)
PROJECT_NAME="${PROJECT_NAME}"
CERTBOT_EMAIL="${CERTBOT_EMAIL}"
GENERAL_SECRETS_ID="${GENERAL_SECRETS_ID}"
ENV_SECRETS_ID="${ENV_SECRETS_ID}"
DOCKERHUB_REPO="${DOCKERHUB_REPO}"

# Update and upgrade packages
echo "Updating and upgrading packages..."
sudo apt update -y > /dev/null && sudo apt upgrade -y > /dev/null
echo "Packages updated and upgraded."

# Install required software
echo "Installing required software: docker, nginx, docker-compose, unzip..."
sudo apt install -y docker.io nginx docker-compose unzip > /dev/null
echo "Required software installed."

# Install Snapd and Certbot
echo "Installing Snapd and Certbot..."
sudo apt install -y snapd > /dev/null
sudo snap install --classic certbot > /dev/null
sudo ln -s /snap/bin/certbot /usr/bin/certbot
echo "Snapd and Certbot installed."

# Install AWS CLI
echo "Installing AWS CLI..."
curl -s "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip -q awscliv2.zip
sudo ./aws/install > /dev/null
rm -f awscliv2.zip
echo "AWS CLI installed."

# Configure AWS CLI default region
echo "Configuring AWS CLI default region..."
mkdir -p ~/.aws
echo "[default]" > ~/.aws/config
echo "region = ap-southeast-1" >> ~/.aws/config
echo "AWS CLI region configured."

# Docker login using credentials from secrets
echo "Retrieving secrets from AWS Secrets Manager..."
GENERAL_SECRETS=$(aws secretsmanager get-secret-value --secret-id $GENERAL_SECRETS_ID --query SecretString --output text)
DOCKER_USERNAME=$(echo "$GENERAL_SECRETS" | jq -r '.DOCKER_USERNAME')
DOCKER_PASSWORD=$(echo "$GENERAL_SECRETS" | jq -r '.DOCKER_PASSWORD')
echo "$DOCKER_PASSWORD" | docker login -u "$DOCKER_USERNAME" --password-stdin
echo "Docker login successful."

# Enable Docker
echo "Starting and enabling Docker service..."
sudo systemctl start docker
sudo systemctl enable docker
echo "Docker service started and enabled."

# Enable Nginx
echo "Starting and enabling Nginx service..."
sudo systemctl start nginx
sudo systemctl enable nginx
sudo nginx -t
echo "Nginx service started and enabled."

# Create project directory
echo "Creating project directory: /home/ubuntu/${PROJECT_NAME}..."
mkdir -p /home/ubuntu/${PROJECT_NAME}
cd /home/ubuntu/${PROJECT_NAME}
echo "Project directory created."

# Create docker-compose template
echo "Creating docker-compose.yml..."
cat <<EOF > docker-compose.yml
version: "3.8"
services:
  redis:
    container_name: redis
    image: redis
    ports:
      - "6379:6379"
  app:
    container_name: app
    image: jermaine1337/${DOCKERHUB_REPO}:dev
    env_file:
      - .env
    restart: always
    command: uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload
    ports:
      - "8000:8000"
    depends_on:
      - redis
EOF
echo "docker-compose.yml created."

# Create .env file
echo "Creating .env file from AWS Secrets Manager..."
ENV_SECRETS=$(aws secretsmanager get-secret-value --secret-id $ENV_SECRETS_ID --query SecretString --output text)
echo "$ENV_SECRETS" > .env
chmod 600 .env
echo ".env file created."

# Pull and deploy Docker images
echo "Pulling and deploying Docker images..."
docker-compose pull > /dev/null
docker-compose up -d
echo "Docker images deployed."

# Configure Nginx
# Create Nginx site configuration file
echo "Configuring Nginx site configuration..."
cat <<EOF | sudo tee /etc/nginx/sites-available/${PROJECT_NAME}.mindhive.asia > /dev/null
server {
    server_name ${PROJECT_NAME}.mindhive.asia;

    location / {
        proxy_pass http://0.0.0.0:8000;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
}
EOF

# Create a symlink to enable the site in Nginx
sudo ln -s /etc/nginx/sites-available/${PROJECT_NAME}.mindhive.asia /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl restart nginx
echo "Nginx configured."

# Install SSL certificate with Certbot
echo "Installing SSL certificate with Certbot..."
sudo certbot --nginx --non-interactive --agree-tos -m "${CERTBOT_EMAIL}" -d "${PROJECT_NAME}.mindhive.asia" > /dev/null
echo "SSL certificate installed."

echo "EC2 instance setup complete at $(date)"
