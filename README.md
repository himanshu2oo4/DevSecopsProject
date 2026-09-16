# 🎮 End-to-End Kubernetes DevSecOps Tetris Project

## Project Overview

This project is a complete DevSecOps implementation for a Tetris application, built to demonstrate how a containerized application moves from source code to a secure Kubernetes deployment on Amazon EKS.

The project combines application CI, security scanning, containerization, Infrastructure as Code, AWS identity management, Amazon EKS, Kubernetes deployment, and automated verification.

The goal is to understand how the different DevSecOps components work together as one delivery pipeline rather than treating each tool as a standalone exercise.


## Architecture 
---
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

## Project Goals

The project demonstrates:

- Continuous Integration and Continuous Deployment
- Secure authentication between GitHub Actions and AWS
- Infrastructure provisioning with Terraform
- Kubernetes deployment on Amazon EKS
- Source-code quality analysis
- Dependency vulnerability scanning
- Container vulnerability scanning
- Docker image publishing
- Kubernetes API authorization through EKS Access Entries
- Automated deployment verification
- Public application exposure through an AWS Load Balancer

---

# High-Level Architecture

**Developer → GitHub → GitHub Actions → Security Checks → Docker Hub → AWS Authentication → Amazon EKS → Kubernetes → AWS Load Balancer → Tetris**

The current delivery flow is divided into source/CI, security, container, infrastructure, identity, Kubernetes, and application-access stages.

---

# Repository Structure

The main GitHub repository is:

`https://github.com/himanshu2oo4/DevSecopsProject`

The important project areas are:

- `Tetris-V2` — Tetris application source and Docker configuration
- `EKS-tf` — Terraform infrastructure configuration
- `K8s` — Kubernetes namespace, deployment, and service configuration
- `.github/workflows` — GitHub Actions CI/CD workflows

This separation keeps application, infrastructure, Kubernetes, and automation concerns organized.

---

# 🎮 Application

The Tetris application is a web application running inside a Docker container.

The application listens on **port 3000**.

Kubernetes keeps port 3000 as the application target port and exposes the application externally through a Kubernetes Service.

---

# 🐳 Docker and Docker Hub

The Tetris application is containerized using Docker.

The CI pipeline builds the application image and publishes it to Docker Hub.

The current image naming convention uses:

**`tetrisv2:1.0.0`**

The Docker stage performs application preparation, image creation, Trivy image scanning, Docker Hub authentication, and image publishing.

A future improvement is to replace the fixed version with an immutable Git commit based tag so every deployment can be traced to an exact source revision.

---

# 🔎 SonarQube

SonarQube is integrated into the GitHub Actions pipeline for source-code quality analysis.

The SonarQube scan is followed by a Quality Gate check. This ensures that code-quality checks happen during CI before the application continues through the delivery pipeline.

The workflow uses GitHub Secrets for SonarQube connectivity and authentication:

- `SONAR_TOKEN`
- `SONAR_HOST_URL`

---

# 🛡️ OWASP Dependency-Check

OWASP Dependency-Check is used to identify known vulnerabilities in application dependencies.

The tool runs during CI and produces a security report that is retained as a GitHub Actions artifact.

This provides dependency-level security visibility before the application is deployed to Kubernetes.

---

# 🔐 Trivy Security Scanning

Trivy is used at two stages.

## Filesystem Scanning

The application source directory is scanned for vulnerabilities, including CRITICAL, HIGH, and MEDIUM severity findings.

A JSON report is also generated and uploaded as a workflow artifact.

## Docker Image Scanning

The built Tetris Docker image is scanned before it is pushed to Docker Hub.

This creates security checkpoints at both the project-filesystem level and the final-container level.

---

# ☁️ AWS Infrastructure

The infrastructure is hosted in:

**AWS Region:** `ap-south-1`

**AWS Account:** `815802019107`

**EKS Cluster:** `tetris-eks-cluster`

Terraform is used to provision and manage the infrastructure.

The infrastructure includes:

- Amazon VPC
- Public subnets
- Private subnets
- Internet Gateway
- NAT Gateway
- EKS control plane
- EKS managed node group
- EKS add-ons
- EKS Access Entries

Worker nodes are placed in private subnets. NAT provides outbound connectivity for private resources when required.

---

# 🏗️ Terraform

Terraform is the Infrastructure as Code layer of the project.

The project uses the Terraform AWS provider and the Terraform AWS EKS module.

Terraform is responsible for making the EKS environment repeatable and manageable as configuration instead of creating the infrastructure manually through the AWS Console.

The EKS configuration also includes explicit access entries so the intended AWS identities can reach the Kubernetes API.

---

# 🖥️ EKS Managed Node Group

The EKS cluster uses a managed node group.

The intended instance type is:

**`c7i-flex.large`**

The node group is configured with:

- Minimum size: 1
- Desired size: 1
- Maximum size: 3

This provides a small starting footprint while retaining room for future scaling.

---

# 🔌 EKS Add-ons

The EKS environment uses the following AWS-managed add-ons:

## VPC CNI

Provides Kubernetes Pod networking through the AWS VPC networking model.

## kube-proxy

Supports Kubernetes Service networking on the worker nodes.

## CoreDNS

Provides DNS resolution and service discovery inside the Kubernetes cluster.

These components are important parts of a functioning EKS networking and service-discovery layer.

---

# 🔐 AWS IAM and GitHub OIDC

GitHub Actions does not use long-lived AWS access keys for this project.

Instead, the pipeline uses GitHub OpenID Connect (OIDC) to obtain temporary AWS credentials.

The authentication flow is:

**GitHub Actions → GitHub OIDC Token → AWS STS → IAM Role**

The GitHub Actions IAM role is:

`arn:aws:iam::815802019107:role/GitHubActionsTerraformRole`

The GitHub OIDC provider is:

`arn:aws:iam::815802019107:oidc-provider/token.actions.githubusercontent.com`

This removes the need to store a permanent AWS access key and secret key in GitHub Secrets.

---

# 🎯 GitHub OIDC Repository Restriction

The IAM trust relationship was restricted to the verified GitHub repository and main branch subject.

The subject used in the trust policy is:

`repo:himanshu2oo4@86143385/DevSecopsProject@1367378255:ref:refs/heads/main`

The audience is:

`sts.amazonaws.com`

This means the IAM role trust relationship is tied to the intended GitHub Actions identity instead of broadly trusting arbitrary GitHub OIDC tokens.

---

# 📜 IAM Permissions

The project uses different permissions for different layers.

## EKS Cluster Metadata Permission

The GitHub Actions role uses `eks:DescribeCluster` so the workflow can retrieve the EKS cluster information needed to configure Kubernetes access.

This permission is associated with the Tetris cluster.

An important lesson from the project is:

**AWS IAM permission is not the same as Kubernetes API authorization.**

Being allowed to describe an EKS cluster does not automatically allow an identity to create Pods, Deployments, Services, or other Kubernetes resources.

---

# 🔑 EKS Access Entries

EKS Access Entries connect AWS identities to Kubernetes API authorization.

Two identities are represented in the project.

## GitHub Actions Identity

Principal:

`arn:aws:iam::815802019107:role/GitHubActionsTerraformRole`

The principal is associated with the AWS-managed EKS access policy:

`AmazonEKSClusterAdminPolicy`

The scope is the cluster.

This is what enables GitHub Actions to authenticate to the Kubernetes API and perform deployment operations.

## Local Development Identity

The local AWS identity was checked through the AWS CLI and is:

`arn:aws:iam::815802019107:user/learner`

The same identity is intended to have a separate EKS Access Entry for local kubectl access.

The local flow is:

**Windows → AWS CLI → IAM user `learner` → EKS Access Entry → Kubernetes API**

For this learning project, the cluster-admin EKS access policy is used for simplicity. A production implementation should use least-privilege access appropriate to each role.

---

# 🔄 Terraform Access Entry State Migration

During the project, an existing AWS access entry was previously represented in Terraform state under a `cluster_creator` key even though the underlying AWS principal was the GitHub Actions role.

The Terraform state was migrated so the entry is represented correctly under the GitHub Actions access-entry key.

This approach avoids unnecessary deletion and recreation of an already-existing AWS access relationship.

---

# 💻 Local Kubernetes Access

The local Windows environment uses AWS CLI to create/update the Kubernetes configuration for the EKS cluster.

The cluster context is:

`arn:aws:eks:ap-south-1:815802019107:cluster/tetris-eks-cluster`

The kubeconfig update succeeded, but local kubectl initially returned a credentials/authorization error because the `learner` IAM user had not yet been authorized through an EKS Access Entry.

After the local Access Entry is present, local kubectl can be used for troubleshooting, inspection, and manual validation.


---

# ☸️ Kubernetes Layer

Kubernetes resources are maintained separately from Terraform.

The Kubernetes area contains the application namespace, Deployment, and Service.

This keeps infrastructure provisioning and application deployment as separate concerns.

---

# 📦 Namespace

The application uses a dedicated namespace:

**`tetris`**

The namespace provides a clean logical boundary for application resources and makes it easier to inspect, manage, and troubleshoot Tetris-specific resources.

---

# 🚀 Kubernetes Deployment

The application is deployed through a Kubernetes Deployment.

The Deployment is configured for:

**2 replicas**

The Pods run the Tetris Docker image and listen on **port 3000**.

Resource requests and limits are defined for the application containers.

The Kubernetes hierarchy is:

**Deployment → ReplicaSet → 2 Tetris Pods**

The Deployment maintains the desired number of replicas and allows Kubernetes to recreate a failed Pod.

---

# 🌐 Kubernetes Service

The Tetris application is exposed through a Kubernetes Service of type:

**LoadBalancer**

The service exposes **port 80** externally and forwards traffic to the application's **port 3000** inside the Pods.

The traffic path is:

**Internet → AWS Load Balancer :80 → Kubernetes Service :80 → Tetris Pod :3000**

Port 3000 therefore remains the application port while port 80 becomes the public entry point.

---

# 🌍 AWS Load Balancer

When the LoadBalancer Service is created, AWS provisions an external Load Balancer.

The Load Balancer hostname becomes the public endpoint for the application.

The browser flow is:

**Browser → AWS Load Balancer → Tetris Service → Tetris Pods**

The external address can be checked from the Kubernetes Service status.

If the service shows a pending external endpoint, AWS is still provisioning the Load Balancer.

---

# ⚙️ GitHub Actions CI/CD

The current pipeline is organized into logical jobs.

## Build and Test

This stage handles application validation and security checks, including source checkout, Node.js setup, dependency installation, SonarQube analysis, Quality Gate validation, OWASP Dependency-Check, Trivy filesystem scanning, and artifact upload.

## Docker Stage

This stage handles Docker image creation, Trivy image scanning, Docker Hub authentication, and image publishing.

## Terraform Stage

This stage handles AWS authentication followed by Terraform initialization, formatting, validation, and planning.

## EKS Deployment Stage

The deployment stage uses the GitHub Actions IAM role to configure kubectl against the EKS cluster and then applies the Kubernetes resources.

It verifies the EKS connection, applies the namespace, Deployment, and Service, and checks the resulting Kubernetes resources.

---

# ⏱️ Deployment Verification

After Kubernetes resources are applied, GitHub Actions performs verification of the Tetris deployment.

The verification focuses on:

- Pods
- Deployment
- ReplicaSet
- Service
- Load Balancer status

A repeated one-minute verification/watch approach can be used when you want to observe the deployment becoming ready rather than checking the cluster only once.

For CI logs, repeated timestamped checks are easier to read and retain than an interactive terminal watch session.

A deployment can also be validated by waiting for the Deployment rollout to complete within a defined timeout, then printing the final Kubernetes state.

---

# 🧪 Deployment Success Criteria

A healthy deployment should show:

### Pods

Two Tetris Pods should be running and ready.

### Deployment

The desired replicas should be available.

### Service

`tetris-service` should show type `LoadBalancer`.

### External Access

The Service should eventually receive an AWS Load Balancer hostname.

Once that endpoint is available, the Tetris application can be opened from a browser.

---

# 🔐 GitHub Secrets

GitHub Secrets are used for service credentials and application-related integrations.

Current secrets include:

- `DOCKERHUB_USERNAME`
- `DOCKERHUB_TOKEN`
- `SONAR_TOKEN`
- `SONAR_HOST_URL`

Long-lived AWS access keys are not used by GitHub Actions because the workflow authenticates through OIDC and the AWS IAM role.

---

# 🛡️ Layered Security Model

The project uses multiple security controls across the delivery lifecycle.

### Source Security

SonarQube provides source-code quality analysis.

### Dependency Security

OWASP Dependency-Check identifies known dependency vulnerabilities.

### Filesystem Security

Trivy scans the application filesystem.

### Container Security

Trivy scans the resulting Docker image.

### Cloud Authentication

GitHub Actions uses OIDC instead of long-lived AWS credentials.

### Cloud Authorization

AWS IAM controls AWS-level permissions.

### Kubernetes Authorization

EKS Access Entries control which AWS identities are authorized to use the Kubernetes API.

This provides a layered DevSecOps security model rather than relying on a single security tool.

---

# 🔄 End-to-End Delivery Flow

**Developer Push**

↓

**GitHub Repository**

↓

**GitHub Actions**

↓

**Build and Test**

↓

**SonarQube**

↓

**OWASP Dependency-Check**

↓

**Trivy Filesystem Scan**

↓

**Docker Build**

↓

**Trivy Image Scan**

↓

**Docker Hub**

↓

**GitHub OIDC**

↓

**AWS STS**

↓

**GitHubActionsTerraformRole**

↓

**Terraform / Amazon EKS**

↓

**EKS Access Entry**

↓

**Kubernetes API**

↓

**Tetris Namespace**

↓

**Tetris Deployment**

↓

**2 Tetris Pods**

↓

**Tetris Service**

↓

**AWS Load Balancer**

↓

**🎮 Tetris Application**

---

# 📈 Current Milestones

The project has established the following major milestones:

- Dockerized Tetris application
- Docker Hub integration
- SonarQube scan
- SonarQube Quality Gate
- OWASP Dependency-Check
- Trivy filesystem scan
- Trivy container scan
- Terraform-based EKS infrastructure
- EKS managed node group
- EKS networking add-ons
- GitHub OIDC provider
- GitHub Actions IAM role
- Repository/branch-restricted OIDC trust
- EKS Access Entry for GitHub Actions
- Successful GitHub Actions Kubernetes API access
- Local IAM identity discovery
- EKS Access Entry design for local access
- Kubernetes namespace
- Kubernetes Deployment
- Kubernetes Service
- AWS Load Balancer based application exposure
- Automated deployment verification




## TARGET 
---


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

# 🚧 Next Improvements

The next planned stages are:

## Immutable Image Versioning

Replace the fixed Docker image version with a Git SHA or another immutable versioning strategy.

## Private Registry Authentication

Support private Docker Hub repositories with Kubernetes image-pull credentials when required.

## Kubernetes Security Hardening

Add security contexts, least-privilege service accounts, network controls, and additional runtime controls.

## Helm

Package the Kubernetes deployment into a reusable Helm chart.

## Argo CD

Introduce Argo CD for GitOps-based continuous synchronization.

## GitOps

Move deployment state management toward a Git-driven desired-state workflow.

## Ingress and HTTPS

Use ingress-based routing, HTTPS, and production-style application exposure.

## Monitoring and Observability

Add metrics, dashboards, logging, and operational visibility for the application and cluster.

---

# 🎯 Target Architecture

The long-term target is to evolve the current deployment into:

**GitHub → CI Security → Docker Registry → GitOps Repository → Argo CD → Amazon EKS → Ingress → Application → Monitoring**

This represents a fuller production-style DevSecOps lifecycle where source control, CI, security, infrastructure, Kubernetes, deployment automation, and observability work together.

---

# 🧠 Key Lessons

This project demonstrates several practical DevOps concepts:

- IAM authorization and Kubernetes API authorization are separate layers.
- EKS Access Entries provide a direct way to authorize AWS identities for Kubernetes operations.
- GitHub OIDC removes the need for long-lived AWS credentials in GitHub Actions.
- Security checks can be incorporated before application deployment.
- Terraform makes EKS infrastructure reproducible and manageable as code.
- Kubernetes Deployments maintain desired replicas and support self-healing behavior.
- Kubernetes LoadBalancer Services can provide an AWS-managed external entry point.
- A CI/CD pipeline includes more than building code; it also covers security, infrastructure, deployment, and validation.

---

# 🏁 Project Status

The core DevSecOps foundation is established.

The major authentication path is:

**GitHub Actions → OIDC → AWS IAM Role → EKS Access Entry → Kubernetes API**

The application deployment path is:

**Docker Hub → EKS Deployment → Tetris Pods → Service → AWS Load Balancer**

The next stage is to move this working foundation toward a production-style **Helm + Argo CD + GitOps + Ingress + Monitoring** architecture.

---

## Repository

`https://github.com/himanshu2oo4/DevSecopsProject`
