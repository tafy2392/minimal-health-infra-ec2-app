# minimal-health-infra-ec2-app

AWS dev web tier for the **rewards** service — EC2 ASG behind an ALB, provisioned with Terraform, configured with Ansible, delivered via GitHub Actions.

- **Health endpoint:** `GET /healthz` → `{"service":"rewards","status":"ok","commit":"...","region":"..."}`
- **See [SOLUTION.md](SOLUTION.md)** for architecture, design decisions, blue/green procedure, and known issues.

---

## Prerequisites

| Tool | Version | Install |
|------|---------|---------|
| Terraform | `~> 1.11` | `brew install terraform` |
| Packer | `~> 1.15` | `brew install packer` |
| Ansible | `~> 10` | `pip install ansible boto3 botocore` |
| AWS CLI | v2 | `brew install awscli` |
| SSM plugin | latest | `brew install --cask session-manager-plugin` |
| Node.js | `>= 24` | `brew install node` (local app dev only) |

AWS credentials configured in your environment (env vars, instance profile, or `~/.aws/config`).

---

## Repository Layout

```
.
├── app/                         # Node 24 rewards service
│   ├── index.js                 #   GET /healthz + secret-gated routes
│   ├── Dockerfile
│   └── package.json
├── ansible/
│   ├── playbooks/deploy.yml     # deploy + drift detection
│   ├── inventory/dev/           # aws_ec2 dynamic inventory
│   └── requirements.yml
├── docker-compose-dev.yaml      # updated by CI on every build
├── terraform/
│   ├── health-dev-aws-eu/       # dev environment root
│   │   ├── main.tf              #   module wiring + SSM data sources
│   │   ├── main.tfvars          #   non-secret variables
│   │   ├── backend.tfvars       #   S3 backend coordinates
│   │   ├── golden-ami.tf
│   │   ├── vpc.tf
│   │   └── remote-state/        #   one-time S3 + DynamoDB bootstrap
│   └── modules/
│       ├── vpc/                 #   VPC, subnets, IGW, route tables
│       ├── golden-ami/          #   Packer AMI via null_resource
│       └── aws-lb-asg/          #   ALB, SGs, listeners
│           └── aws-lb-tg/       #   ASG, launch template, TG, alarms
└── .github/workflows/
    ├── pr-checks.yml            # fmt · validate · tflint · tf plan → PR comment
    ├── build-node-app.yml       # docker build · push GHCR · update compose
    └── ansible-deploy.yml       # tf apply · ASG refresh · Ansible SSM deploy
```

---

## First-Time Bootstrap

### 1 — Create the Terraform state backend

```bash
cd terraform/health-dev-aws-eu/remote-state
terraform init
terraform apply
```

### 2 — Create required SSM parameters

```bash
# GitHub deploy key (private key for cloning the repo on the instance)
aws ssm put-parameter \
  --name "/dev/github/clone-token" \
  --value "$(cat ~/.ssh/your-deploy-key)" \
  --type SecureString

# Application secrets
aws ssm put-parameter \
  --name "/dev/app/secret" \
  --value "your-app-secret" \
  --type SecureString

aws ssm put-parameter \
  --name "/dev/app/virtual-host" \
  --value "healthcheck-app.example.com" \
  --type String
```

### 3 — Build the golden AMI

```bash
cd terraform/health-dev-aws-eu
terraform init -backend-config=backend.tfvars
terraform apply -var-file=main.tfvars \
  -target=module.golden_amis
```

### 4 — Apply full infrastructure

```bash
terraform apply -var-file=main.tfvars
```

---

## Running the App Locally

```bash
cd app
node index.js &

curl http://localhost:3000/healthz
# {"service":"rewards","status":"ok","commit":"unknown","region":"eu-central-1"}

# Secret-gated route
APP_SECRET=mysecret node index.js &
curl -H "X-App-Secret: mysecret" http://localhost:3000/
```

---

## Running Ansible Locally

```bash
# Install dependencies
pip install -r ansible/requirements.txt
ansible-galaxy collection install -r ansible/requirements.yml

# Run deploy playbook against dev
ansible-playbook \
  -i ansible/inventory/dev \
  ansible/playbooks/deploy.yml \
  -e deploy_env=dev \
  -e app_secret="$(aws ssm get-parameter --name /dev/app/secret --with-decryption --query Parameter.Value --output text)" \
  -e app_virtual_host="healthcheck-app.example.com" \
  -e git_commit="$(git rev-parse --short HEAD)"
```

---

## CI/CD Workflows

| Trigger | Workflow | What it does |
|---------|----------|--------------|
| PR opened/updated | `pr-checks.yml` | `terraform fmt`, `validate`, `tflint`, `terraform plan` → comment on PR |
| Merge to `main` | `build-node-app.yml` | Build Docker image, push to GHCR, update `docker-compose-dev.yaml` in-repo |
| Build succeeds | `ansible-deploy.yml` | `terraform apply`, ASG instance refresh, Ansible over SSM → `.env` + `docker compose up -d` |

GitHub environments used: **`dev`** (auto-deploy) — add a **`prod`** environment with required reviewers for manual-approval prod promotion.

---

## Clean-up

```bash
cd terraform/health-dev-aws-eu
terraform destroy -var-file=main.tfvars

# Deregister Packer AMIs
aws ec2 describe-images --owners self \
  --filters "Name=tag:ManagedBy,Values=packer" \
  --query "Images[*].ImageId" --output text | \
  xargs -n1 aws ec2 deregister-image --image-id

# Destroy state backend last
cd terraform/health-dev-aws-eu/remote-state
terraform destroy
```

