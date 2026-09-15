# 🎮 End-to-End Kubernetes DevSecOps Tetris Project

An end-to-end DevSecOps project for deploying a Tetris application on **Amazon EKS** using Terraform, GitHub Actions, Docker Hub, SonarQube, OWASP Dependency-Check, and Trivy.

## Current Progress

- ✅ Tetris application containerized with Docker
- ✅ Docker image pushed to Docker Hub
- ✅ SonarQube scan and Quality Gate configured
- ✅ OWASP Dependency-Check configured
- ✅ Trivy filesystem and Docker image scans configured
- ✅ GitHub Actions OIDC configured
- ✅ GitHub Actions can assume `GitHubActionsTerraformRole`
- ✅ EKS cluster `tetris-eks-cluster` provisioned with Terraform
- ✅ EKS managed node group created
- ✅ EKS add-ons configured: VPC CNI, CoreDNS, kube-proxy
- ✅ GitHub Actions IAM role configured through EKS Access Entry
- ✅ GitHub Actions successfully runs `kubectl get nodes`
- 🔄 Local IAM user `learner` EKS Access Entry being added
- 🔄 Kubernetes deployment connected to GitHub Actions
- ⏳ Tetris application exposed through AWS Load Balancer
- ⏳ Dynamic Docker image tags
- ⏳ Helm
- ⏳ Argo CD / GitOps
- ⏳ Monitoring and observability

---

# Architecture

```text
Developer
   │ git push
   ▼
GitHub Repository
   │
   ▼
GitHub Actions
   ├── Build & Test
   ├── SonarQube
   ├── OWASP
   ├── Trivy
   └── Docker Build/Push
              │
              ▼
          Docker Hub
              │
              ▼
        GitHub OIDC
              │
              ▼
            AWS STS
              │
              ▼
   GitHubActionsTerraformRole
              │
              ▼
          Amazon EKS
              │
        ┌─────┴─────┐
        ▼           ▼
     Pod 1        Pod 2
       :3000       :3000
        └─────┬─────┘
              ▼
       Tetris Service :80
              │
              ▼
       AWS Load Balancer
              │
              ▼
          Internet
              │
              ▼
           🎮 Tetris
```

---

# AWS / EKS

**Region:** `ap-south-1`
**EKS Cluster:**

```text
tetris-eks-cluster
```

Terraform uses:

```hcl
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 21.0"
}
```

The cluster uses public API endpoint access and an EKS managed node group.

## EKS Add-ons

```hcl
addons = {
  vpc-cni = {
    before_compute = true
    most_recent    = true
  }

  kube-proxy = {
    most_recent = true
  }

  coredns = {
    most_recent = true
  }
}
```

- **VPC CNI** — Kubernetes networking through AWS VPC networking.
- **kube-proxy** — Kubernetes Service networking.
- **CoreDNS** — DNS resolution inside the cluster.

---

# GitHub Actions OIDC

The project uses GitHub Actions OIDC instead of storing long-lived AWS access keys.

Flow:

```text
GitHub Actions
      ↓
GitHub OIDC Provider
      ↓
AWS STS
      ↓
GitHubActionsTerraformRole
      ↓
AWS / EKS
```

OIDC provider:

```text
# should be installed on aws 
arn:aws:iam::acc-id:oidc-provider/token.actions.githubusercontent.com
```

IAM role:

```text role for the github actions to create aws resources using terraform
arn:aws:iam::Acc-id:role/GitHubActionsTerraformRole
```

The trust policy is restricted to the intended GitHub repository/branch subject.

---

# EKS Access Entries

A key concept in this project:

```text
AWS IAM permission
        ≠
Kubernetes API authorization
```

`eks:DescribeCluster` allows EKS metadata access, but Kubernetes API authorization is handled separately through the EKS Access Entry.

## 1. GitHub Actions Access Entry

GitHub Actions uses:

```text
arn:aws:iam::acc-id:role/GitHubActionsTerraformRole
```

and is associated with:

```text
AmazonEKSClusterAdminPolicy
```

Terraform:

```hcl
github_actions = {
  principal_arn = "arn:aws:iam::acc-id:role/GitHubActionsTerraformRole"

  policy_associations = {
    admin = {
      policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"

      access_scope = {
        type = "cluster"
      }
    }
  }
}
```

This access is working:

```bash
kubectl get nodes
```

from GitHub Actions.

## 2. Local Windows Access Entry

The local AWS identity was checked with:

```powershell
aws sts get-caller-identity
```

and returned:

```text
arn:aws:iam::acc-id:user/learner
```

The planned Terraform entry is:

```hcl
local_user = {
  principal_arn = "arn:aws:iam::acc-id:user/learner"

  policy_associations = {
    admin = {
      policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"

      access_scope = {
        type = "cluster"
      }
    }
  }
}
```

After applying this entry, local access can be configured with:

```powershell
aws eks update-kubeconfig --region ap-south-1 --name tetris-eks-cluster
kubectl get nodes
```

The kubeconfig update has already succeeded; the previous local `kubectl` error happened because `learner` was not yet authorized in EKS.

> For a production environment, use least-privilege permissions instead of cluster-admin access. Cluster-admin is being used here for the learning project.

---

# Docker

Current image convention:

```text
himanshu1236/tetrisv2:1.0.0
```

The Docker job:

1. Checks out the code.
2. Sets up Node.js.
3. Runs `npm ci`.
4. Builds the image.
5. Scans it with Trivy.
6. Logs into Docker Hub.
7. Pushes the image.

Example:

```bash
docker build -t himanshu1236/tetrisv2:1.0.0 .
docker push himanshu1236/tetrisv2:1.0.0
```

---

# Security Scanning

## SonarQube

```text
Source Code
    ↓
SonarQube Scan
    ↓
Quality Gate
```

GitHub Secrets:

```text
SONAR_TOKEN
SONAR_HOST_URL
```

## OWASP Dependency-Check

Scans application dependencies for known vulnerabilities.

The configured output directory is:

```text
reports
```


## Trivy Filesystem Scan

The repository is scanned with:

```yaml
scan-type: fs
severity: CRITICAL,HIGH,MEDIUM
```

JSON output:

```text
trivy-fs-report.json
```

## Trivy Docker Image Scan

The built Docker image is scanned before it is pushed to Docker Hub.

---

# Kubernetes

Kubernetes manifests:

```text
Manifests-file/
├── namespace.yaml
├── deployment-service.yaml
```



## Deployment

The Tetris application is confirmed to run on **port 3000**.

Architecture:

```text
Deployment
    ↓
ReplicaSet
    ├── Tetris Pod 1 :3000
    └── Tetris Pod 2 :3000
```

## Service

`Manifest-file/service.yaml`

```yaml
apiVersion: v1
kind: Service
metadata:
  name: tetris-service
  namespace: tetris
spec:
  type: LoadBalancer
  selector:
    app: tetris
  ports:
    - protocol: TCP
      port: 80
      targetPort: 3000
```

Traffic:

```text
Browser
   ↓
AWS Load Balancer :80
   ↓
tetris-service :80
   ↓
Tetris Pods :3000
```

---

# GitHub Actions CI/CD

Current target pipeline:

```text
security-checks
      ↓
Docker-stuffs
      ↓
terraform-builds
      ↓
deploy-to-eks
```


# 🎮 Accessing the Tetris Game

Because the Service uses:

```yaml
type: LoadBalancer
```

AWS provisions an external Load Balancer.

Check:

```bash
kubectl get svc tetris-service -n tetris
```

Expected:

```text
NAME             TYPE           CLUSTER-IP     EXTERNAL-IP
tetris-service   LoadBalancer   10.100.x.x     k8s-tetris-xxxx.elb.amazonaws.com
```

Open:

```text
http://k8s-tetris-xxxx.elb.amazonaws.com
```

in a browser.

You access port **80** externally. The container continues to listen on **3000**.

If `EXTERNAL-IP` shows `<pending>`, AWS is still provisioning the Load Balancer.

---

# Useful Commands

## AWS identity

```powershell
aws sts get-caller-identity
```

## EKS kubeconfig

```powershell
aws eks update-kubeconfig --region ap-south-1 --name tetris-eks-cluster
```

## Nodes

```powershell
kubectl get nodes
```

## Tetris Pods

```powershell
kubectl get pods -n tetris
```

## Deployment

```powershell
kubectl get deployment -n tetris
```

## Service / Load Balancer

```powershell
kubectl get svc -n tetris
```

## Logs

```powershell
kubectl logs -n tetris <pod-name>
```

## Pod details

```powershell
kubectl describe pod -n tetris <pod-name>
```

## Watch Load Balancer provisioning

```powershell
kubectl get svc -n tetris -w
```

---

# Planned Improvements

1. Complete local `learner` EKS Access Entry.
2. Deploy Kubernetes manifests through GitHub Actions.
3. Verify Tetris Pods.
4. Verify AWS Load Balancer.
5. Access Tetris from the browser.
6. Replace `1.0.0` with immutable Git SHA image tags.
7. Add Docker Hub `imagePullSecrets` if the repository is private.
8. Add Kubernetes security hardening.
9. Package deployment with Helm.
10. Install and configure Argo CD.
11. Implement GitOps.
12. Add monitoring and logging.

---

# Target DevSecOps Architecture

```text
                       GitHub
                          │
                       Git Push
                          │
                          ▼
                 ┌─────────────────┐
                 │ GitHub Actions  │
                 └────────┬────────┘
                          │
          ┌───────────────┼────────────────┐
          │               │                │
          ▼               ▼                ▼
       Build          SonarQube        Security
          │            Quality Gate      Scans
          │                         ┌─────┴─────┐
          │                       OWASP       Trivy
          │
          ▼
      Docker Build
          │
          ▼
      Docker Hub
          │
          ▼
    AWS OIDC Authentication
          │
          ▼
 GitHubActionsTerraformRole
          │
          ▼
       Amazon EKS
          │
          ▼
       Argo CD
          │
          ▼
       GitOps Sync
          │
          ▼
 Kubernetes Deployment
          │
      ┌───┴───┐
      ▼       ▼
    Pod 1   Pod 2
      │       │
      └───┬───┘
          ▼
       Service
          │
          ▼
   AWS Load Balancer
          │
          ▼
       Internet
          │
          ▼
       🎮 Tetris
```

---

# 🏁 Milestones

## Authentication milestone

```text
GitHub Actions
      ↓
GitHub OIDC
      ↓
AWS STS
      ↓
GitHubActionsTerraformRole
      ↓
EKS Access Entry
      ↓
Kubernetes API
      ↓
kubectl get nodes ✅
```

## Local access milestone

```text
Windows PowerShell
      ↓
AWS CLI
      ↓
IAM user: learner
      ↓
EKS Access Entry
      ↓
Kubernetes API
      ↓
kubectl
```

## Application deployment milestone

```text
GitHub Actions
      ↓
kubectl apply
      ↓
Tetris Deployment
      ↓
Tetris Pods
      ↓
LoadBalancer Service
      ↓
AWS Load Balancer
      ↓
🎮 Public Tetris Application
```

---

## Repository

`https://github.com/himanshu2oo4/DevSecopsProject`
