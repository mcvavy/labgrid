# 🏠 LabGrid

A modern, production-grade Kubernetes infrastructure for running enterprise workloads in a lab environment. Built with K3s, Azure, and GitOps principles.

## 🌟 Features

- **GitOps-Driven Infrastructure**: All infrastructure and application deployments managed through Git
- **Production-Grade Security**: Azure Key Vault integration, OIDC authentication, and secure secret management
- **High Availability**: 10-node K3s cluster with proper redundancy
- **Automated Database Management**: CloudNativePG for PostgreSQL cluster management
- **Modern Storage Solutions**: Synology CSI integration for persistent storage
- **Automated Certificate Management**: Let's Encrypt integration for SSL/TLS
- **Monitoring & Observability**: Prometheus and Grafana for metrics and visualization
- **Automated Backups**: Azure Blob Storage integration for database backups
- **Infrastructure as Code**: Terraform for Azure infrastructure management
- **Learning Environment**: Dedicated kubeadm cluster for CKA exam preparation

## 🏗️ Architecture

### Core Components

- **Production Clusters**: 
  - 10-node High Availability K3s cluster
  - kubeadm-based cluster on Proxmox for CKA practice
- **Database Layer**: PostgreSQL clusters managed by CloudNativePG
- **Storage**: Synology NAS integration via CSI driver
- **Networking**: Azure networking with proper segmentation
- **Security**: Azure Key Vault for secrets management
- **Monitoring**: Prometheus & Grafana stack
- **CI/CD**: GitHub Actions for automation

### Applications

- **n8n**: Workflow automation platform
- **PostgreSQL**: Database clusters
- **Monitoring Stack**: Prometheus, Grafana
- **Certificate Management**: cert-manager
- **Secret Management**: External Secrets Operator
- **Learning Tools**: Various Kubernetes components for CKA practice

## 🛠️ Infrastructure

Everything needed to run my clusters & deploy my applications

| Component | Description |
|-----------|-------------|
| ![K3s](https://img.shields.io/badge/K3s-FFC107?style=for-the-badge&logo=kubernetes&logoColor=black) | Lightweight Kubernetes distribution powering my 10-node production cluster |
| ![Kubeadm](https://img.shields.io/badge/Kubeadm-326CE5?style=for-the-badge&logo=kubernetes&logoColor=white) | Standard Kubernetes installation tool for my CKA practice cluster on Proxmox |
| ![CloudNativePG](https://img.shields.io/badge/CloudNativePG-336791?style=for-the-badge&logo=postgresql&logoColor=white) | Database operator for running PostgreSQL clusters with high availability |
| ![Synology](https://img.shields.io/badge/Synology-1A1A1A?style=for-the-badge&logo=synology&logoColor=white) | NAS storage with CSI driver for persistent volume provisioning |
| ![Azure](https://img.shields.io/badge/Azure-0078D4?style=for-the-badge&logo=microsoftazure&logoColor=white) | Cloud platform for Key Vault, networking, and blob storage |
| ![Prometheus](https://img.shields.io/badge/Prometheus-E6522C?style=for-the-badge&logo=prometheus&logoColor=white) | Monitoring system for metrics collection and alerting |
| ![Grafana](https://img.shields.io/badge/Grafana-F46800?style=for-the-badge&logo=grafana&logoColor=white) | Visualization platform for infrastructure and application metrics |
| ![Terraform](https://img.shields.io/badge/Terraform-7B42BC?style=for-the-badge&logo=terraform&logoColor=white) | Primary Infrastructure as Code tool for managing all infrastructure components |
| ![GitHub](https://img.shields.io/badge/GitHub-181717?style=for-the-badge&logo=github&logoColor=white) | Version control and CI/CD platform for GitOps workflows |

### Networking

- VLAN-based network segmentation
- Azure networking integration
- Load balancer services for external access
- Internal DNS resolution

### Storage

- Synology NAS for persistent storage
- CSI driver for Kubernetes integration
- Azure Blob Storage for backups
- NFS shares for shared data

### Security

- Azure Key Vault for secrets management
- OIDC authentication for cluster access
- Network isolation and segmentation
- Automated certificate management
- Regular security updates

## 🚀 Getting Started

### Prerequisites

- Azure subscription
- Azure CLI
- kubectl
- terraform
- helm


## 📁 Project Structure

```
labgrid/
├── Apps/                    # Application deployments
│   ├── charts/             # Helm charts
│   └── n8n/                # n8n specific configurations
├── Base/                   # Base infrastructure
│   ├── provider.tf         # Provider configurations
│   └── main.tf            # Main infrastructure code
└── README.md              # This file
```

## 🔒 Security

- OIDC authentication for Kubernetes access
- Azure Key Vault for secrets management
- Network segmentation and isolation
- Automated certificate management
- Regular security updates via Renovate

## 🔄 Automation

- Automated infrastructure deployment via Terraform
- GitOps-driven application deployment
- Automated database backups
- Automated dependency updates via Renovate
- Automated certificate renewal

## 📊 Monitoring

- Prometheus for metrics collection
- Grafana for visualization
- Custom dashboards for infrastructure monitoring
- Alert management

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## 📝 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🙏 Acknowledgments

- Inspired by various open-source homelab projects
- Built with modern cloud-native tools and practices
- Community-driven development

---

Made with ❤️ for the Kubernetes community

### Infrastructure as Code

- **Terraform as Primary IaC Tool**:
  - Azure resource management
  - Kubernetes cluster provisioning
  - Database cluster configuration
  - Storage and networking setup
  - Security and access management
  - Monitoring stack deployment
- **State Management**: Azure Storage for Terraform state
- **Module-based Architecture**: Reusable Terraform modules for consistent deployments
- **Version Control**: All infrastructure code versioned in Git
- **Automated Deployment**: CI/CD pipeline for infrastructure changes
