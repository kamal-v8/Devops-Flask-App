# 2-Tier Flask Application on AWS

A containerized two-tier web application (Flask + MySQL) deployed on AWS EC2, fully automated with a Jenkins CI/CD pipeline and provisioned using Terraform.

---

```
                    ┌─────────────────────────────────────────────┐
                    │              AWS VPC (10.0.0.0/16)          │
                    │                                             │
  User ──────────►  │   EC2 Instance (t3.micro / Elastic IP)      │
                    │   ┌───────────────────────────────────┐     │
                    │   │  Docker Engine                    │     │
                    │   │                                   │     │
                    │   │  ┌──────────┐    ┌─────────────┐  │     │
   Port 5000  ──────┤───┤► │  Flask   │◄──►│   MySQL     │  │     │
                    │   │  │  :5000   │    │   :3306     │  │     │
                    │   │  └──────────┘    └─────────────┘  │     │
   Port 8080  ──────┤───┤► Jenkins CI/CD                    │     │
                    │   │                                   │     │
                    │   └───────────────────────────────────┘     │
                    └─────────────────────────────────────────────┘
```

---

## Tech Stack

| Tool | Purpose |
|---|---|
| **Python / Flask** | Backend web framework |
| **MySQL** | Relational database (2nd tier) |
| **Docker** | Containerization |
| **Docker Compose** | Multi-container orchestration |
| **Jenkins** | CI/CD pipeline automation |
| **Terraform** | Infrastructure as Code (IaC) |
| **AWS** | Cloud provider (VPC, EC2, EIP) |

---

## Project Structure

```
.
├── app.py                  # Flask application
├── requirements.txt        # Python dependencies
├── Dockerfile              # Docker image for Flask app
├── docker-compose.yaml     # Orchestrates Flask + MySQL containers
├── Jenkinsfile             # CI/CD pipeline definition
├── message.sql             # Reference SQL schema
├── templates/
│   ├── index.html          # Frontend (resume + guestbook)
│   └── image.jpg           # Profile image
└── terraform/
    ├── providers.tf        # AWS provider configuration
    └── main.tf             # VPC, Subnet, SG, EC2, EIP resources
```

---

## Ports Used

| Port | Service | Description |
|---|---|---|
| `22` | SSH | Remote access to EC2 |
| `80` | HTTP | General web traffic |
| `5000` | Flask | The web application |
| `8080` | Jenkins | CI/CD dashboard |
| `3306` | MySQL | Database (internal only) |

---

## Prerequisites

- An AWS account with IAM credentials configured (`aws configure`)
- Terraform installed on your local machine
- An SSH key pair generated at `~/.ssh/ec2-key` and `~/.ssh/ec2-key.pub`

---

## Infrastructure Setup (Terraform)

**1. Navigate to the terraform directory:**

```bash
cd terraform/
```

**2. Initialize Terraform:**

```bash
terraform init
```

**3. Preview the infrastructure:**

```bash
terraform plan
```

**4. Provision the infrastructure:**

```bash
terraform apply
```

**5. Get the Elastic IP of your instance:**

```bash
terraform output
```

**6. SSH into your EC2 instance:**

```bash
ssh -i ~/.ssh/ec2-key ubuntu@<YOUR_ELASTIC_IP>
```

---

## EC2 Instance Setup (Step-by-Step)

Once you SSH into the EC2 instance, run the following commands to set up the environment.

### Step 1: Update & Upgrade the System

```bash
sudo apt update && sudo apt upgrade -y
```

### Step 2: Install Git

```bash
sudo apt install git -y
git --version
```

### Step 3: Install Docker

```bash
sudo apt install docker.io -y
```

Enable Docker to start on boot and start the service:

```bash
sudo systemctl enable docker
sudo systemctl start docker
```

Add the `ubuntu` user to the `docker` group so you can run Docker commands without `sudo`:

```bash
sudo usermod -aG docker ubuntu
```

> **⚠️ Important:** Log out and log back in (or run `newgrp docker`) for the group change to take effect.

Verify Docker is working:

```bash
docker --version
docker ps
```

### Step 4: Install Docker Compose

```bash
sudo apt install docker-compose -y
docker-compose --version
```

### Step 5: Install Java 21 (Required for Jenkins)

Jenkins requires **Java 21** or later. Java 17 will NOT work with the latest Jenkins.

```bash
sudo apt install fontconfig openjdk-21-jre -y
java -version
```

### Step 6: Install Jenkins

Add the Jenkins repository and install:

```bash
curl -fsSL https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key | sudo tee /usr/share/keyrings/jenkins-keyring.asc > /dev/null

echo "deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] https://pkg.jenkins.io/debian-stable binary/" | sudo tee /etc/apt/sources.list.d/jenkins.list > /dev/null

sudo apt update
sudo apt install jenkins -y
```

Enable and start Jenkins:

```bash
sudo systemctl enable jenkins
sudo systemctl start jenkins
sudo systemctl status jenkins
```

### Step 7: Get the Jenkins Initial Admin Password

```bash
sudo cat /var/lib/jenkins/secrets/initialAdminPassword
```

Copy this password. Then open your browser and go to:

```
http://<YOUR_ELASTIC_IP>:8080
```

Paste the password, install the suggested plugins, and create your admin user.

### Step 8: Add Jenkins to the Docker Group

This is the step that allows Jenkins pipelines to run Docker commands. You need to add the **`jenkins` user** to the **`docker` group**.

```bash
sudo usermod -aG docker jenkins
```

Then restart both Docker and Jenkins for the permissions to take effect:

```bash
sudo systemctl restart docker
sudo systemctl restart jenkins
```

> **💡 Clarification:** You are adding `jenkins` → to the `docker` group. This gives the Jenkins service user permission to talk to the Docker daemon. Without this step, your Jenkins pipeline will fail with a `permission denied` error when trying to build or run containers.

---

## Jenkins Pipeline Setup

1. Open Jenkins at `http://<YOUR_ELASTIC_IP>:8080`
2. Click **New Item** → Enter a name (e.g., `flask-app`) → Select **Pipeline** → OK
3. Scroll down to **Pipeline** section:
   - **Definition:** Pipeline script from SCM
   - **SCM:** Git
   - **Repository URL:** `https://github.com/kamal-v8/Devops-Flask-App.git`
   - **Branch:** `*/main`
   - **Script Path:** `Jenkinsfile`
4. Click **Save** → Click **Build Now**

### What the Pipeline Does

| Stage | Action |
|---|---|
| **Clone Code** | Pulls the latest code from GitHub |
| **Build Docker Image** | Runs `docker build -t flask-app:latest .` |
| **Deploy** | Runs `docker-compose down` then `docker-compose up --build -d` |

---

## 🚀 Running the Project Manually (Without Jenkins)

If you want to run the app directly on the EC2 without Jenkins:

```bash
# Clone the repository
git clone https://github.com/kamal-v8/Devops-Flask-App.git
cd Devops-Flask-App

# Start both containers
docker-compose up --build -d

# Check that both containers are running
docker ps
```

You should see two containers:

- `flask` — Running on port `5000`
- `mysql` — Running on port `3306`

Access the app at:

```
http://<YOUR_ELASTIC_IP>:5000
```

---

## 🧹 Useful Commands

```bash
# View running containers
docker ps

# View container logs
docker logs flask
docker logs mysql

# Stop the application
docker-compose down

# Stop and remove all data (including database volume)
docker-compose down -v

# Rebuild and restart
docker-compose up --build -d
```

---

## Tear Down Infrastructure

When you're done and want to destroy all AWS resources to avoid charges:

```bash
cd terraform/
terraform destroy
```

Type `yes` when prompted.

---

## Common Issues & Fixes

| Problem | Cause | Fix |
|---|---|---|
| Jenkins fails to start | Wrong Java version (needs 21+) | `sudo apt install openjdk-21-jre -y` then restart Jenkins |
| `permission denied` on docker.sock | Jenkins user not in docker group | `sudo usermod -aG docker jenkins` then restart both services |
| `docker-compose: not found` | docker-compose not installed | `sudo apt install docker-compose -y` |
| MySQL container keeps restarting | Missing `MYSQL_ROOT_PASSWORD` env var                              | Add `MYSQL_ROOT_PASSWORD` to `docker-compose.yaml` |
| `InvalidKeyPair.Duplicate` in Terraform | Key pair already exists in AWS | Run `terraform import aws_key_pair.key my-key` |

---

## Author

**Kamal V** — [GitHub](https://github.com/kamal-v8)

## Inspired By

**prashantgohel321/DevOps-Project-Two-Tier-Flask-App - [GitHub](https://github.com/prashantgohel321)**[💐]
