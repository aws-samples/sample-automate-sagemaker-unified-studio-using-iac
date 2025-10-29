# Amazon SageMaker Unified Studio CloudFormation Automation

## Introduction

Amazon SageMaker Unified Studio is a comprehensive data and AI platform that brings together data management, analytics, and machine learning capabilities in a unified environment. Built on Amazon DataZone, it provides a centralized workspace where data scientists, analysts, and business users can collaborate to discover, prepare, analyze, and build machine learning models using data across their organization.

### Key Features

- **Unified Data Access**: Seamlessly access and work with data from multiple sources including data lakes, data warehouses, and databases
- **Collaborative Environment**: Enable cross-functional teams to collaborate on data and AI projects with proper governance and access controls
- **Built-in Analytics Tools**: Access to popular analytics and ML tools including Amazon SageMaker, Amazon Athena, Amazon Redshift, and more
- **Data Governance**: Comprehensive data cataloging, lineage tracking, and access management capabilities
- **Self-Service Analytics**: Empower business users with self-service data discovery and analysis capabilities

## Overview

This CloudFormation automation provides a complete setup for Amazon SageMaker Unified Studio with the following components:

### Scope

The deployment includes the following architectural components:

#### Domain Layer
- **Domain**: Central governance domain with KMS encryption
- **Roles**: Domain execution and service roles with proper IAM policies
- **KMS**: Customer-managed encryption keys for data security
- **Ownership**: Automated role and user assignment with cascade permissions

#### Blueprint Configurations (3 BPs)
1. **Tooling Only**: Basic compute and analytics environment
2. **Tooling + Lakehouse DB**: Analytics environment with data lake database capabilities
3. **Tooling + Lakehouse DB + Lakehouse Catalog**: Full data mesh setup with catalog and database

#### Project Profiles
- **Authorization**: Root Domain Unit (DU) with cascade permissions for all users
- **Admin Project**: Administrative project with tooling-only configuration
- **Automation Role**: `dg-corp-admin` as project owner with full administrative access

### Architecture Components

```
┌─────────────────────────────────────────────────────────────────┐
│                    Amazon SageMaker Unified Studio              │
├─────────────────────────────────────────────────────────────────┤
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐  │
│  │   Domain Stack  │  │ Blueprint Stack │  │ Project Stack   │  │
│  │                 │  │                 │  │                 │  │
│  │ • Domain        │  │ • Tooling BP    │  │ • Admin Project │  │
│  │ • KMS Keys      │  │ • Lakehouse DB  │  │ • User Profiles │  │
│  │ • IAM Roles     │  │ • Lakehouse Cat │  │ • Memberships   │  │
│  │ • SSO Config    │  │ • Project Prof  │  │                 │  │
│  └─────────────────┘  └─────────────────┘  └─────────────────┘  │
└─────────────────────────────────────────────────────────────────┘
```

## Prerequisites

To follow along with this walkthrough, you'll need:

- **AWS Account**: If you're new to AWS, see the [AWS Account Setup Guide](https://docs.aws.amazon.com/accounts/latest/reference/manage-acct-creating.html)

- **Development Environment**: 
  - AWS CLI configured with appropriate permissions
    - New to AWS CLI? See the [AWS CLI Installation Guide](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html)
    - Required permissions at high level: Amazon VPC, Amazon SageMaker, Amazon S3, AWS IAM, AWS CloudFormation access.

- **Identity Management**: AWS IAM Identity Center configured (formerly AWS SSO)
  - New to Identity Center? See the [Getting Started Guide](https://docs.aws.amazon.com/singlesignon/latest/userguide/getting-started.html)

- **Network Infrastructure**: Existing VPC with subnets
  - Need help creating a VPC? Check the [VPC Getting Started Guide](https://docs.aws.amazon.com/vpc/latest/userguide/vpc-getting-started.html)


## Deployment Instructions

### Step 1: Update Configuration

Edit the `params.json` file with your environment-specific values.

### Step 2: Setup CloudFormation Bucket

Run the setup script to create the S3 bucket and upload child templates:

```bash
./setup-cloudformation-bucket.sh
```

This script will:
- Create a versioned S3 bucket for CloudFormation templates
- Apply appropriate bucket policies for CloudFormation access
- Upload all child stack templates to the bucket

### Step 3: Deploy the Stack

Deploy the master CloudFormation stack:

```bash
aws cloudformation deploy \
  --template-file master-stack.yaml \
  --stack-name test-apg-sus \
  --parameter-overrides file://params.json \
  --capabilities CAPABILITY_IAM CAPABILITY_NAMED_IAM
```

## Stack Components

### 1. Domain Stack (`sus-domain-stack.yaml`)
Creates the foundational SageMaker Unified Studio domain including:
- DataZone domain with V2 configuration
- KMS encryption keys with appropriate policies
- Domain execution and service roles
- SSO integration and user profiles
- Automation roles for domain management

### 2. Blueprint Stack (`sus-blueprints-stack.yaml`)
Configures environment blueprints and project profiles:
- Tooling blueprint for compute environments
- Lakehouse Database blueprint for data lake capabilities
- Lakehouse Catalog blueprint for data cataloging
- Project profiles combining different blueprint configurations
- S3 buckets and KMS keys for blueprint resources

### 3. Project Stack (`sus-project-stack.yaml`)
Sets up the administrative project:
- Admin project using tooling-only profile
- Project memberships for SSO users and automation roles
- Lake Formation data lake administrator configuration

## Configuration Parameters

Key parameters that can be customized:

| Parameter | Description | Example Value |
|-----------|-------------|---------------|
| `pSUSDomainName` | Name of the SUS domain | `APG-SUS-Enterprise` |
| `pSUSToolingBPVpcId` | VPC ID for blueprint deployment | `vpc-04639bb1c4xxxxx` |
| `pSUSToolingBPSubnets` | Subnet IDs (comma-separated) | `subnet-xxx, subnet-yyy` |
| `pSSOUserID` | SSO User ID for project ownership | `xxxxxxxx-xxxx-xxxx-xxxx-...` |
| `pSSOGroupID` | SSO Group ID for domain ownership | `xxxxxxxx-xxxx-xxxx-xxxx-...` |

## Post-Deployment Configuration

After successful deployment:

1. **Verify Domain**: Check the SageMaker Unified Studio console to confirm domain creation
2. **Test Access**: Verify SSO users can access the domain and admin project
3. **Blueprint Validation**: Confirm all three blueprints are enabled and configured
4. **Project Creation**: Test creating new projects using the configured project profiles

## Security Recommendations

This section outlines key security considerations for deploying Amazon SageMaker Unified Studio in production environments.

### IAM Policy Management

This solution uses AWS-managed IAM policies for SageMaker and DataZone integration. While these policies are maintained by AWS and follow least-privilege principles, consider the following for production deployments:

- Review permissions in each managed policy to ensure alignment with your security requirements
- Consider creating custom policies if more restrictive permissions are needed
- Regularly audit policies and subscribe to AWS security bulletins for updates
- Implement custom policies when:
  - Organizational security requires stricter permissions
  - Specific compliance requirements must be met
  - Additional conditions or resource restrictions are needed

### S3 Access Logging

The blueprint tooling S3 bucket (`rSUSBPToolingBucket`) is used for service-to-service communication. Consider enabling S3 access logging if:

- Compliance requirements mandate audit trails
- Security policies require detailed access monitoring
- Incident response procedures need forensic data

To enable logging:
1. Create a dedicated logging bucket
2. Configure bucket logging in CloudFormation
3. Implement appropriate lifecycle policies for log management

Note: Enabling logging will incur additional storage costs and require maintenance for log retention.

### KMS Key Policy Configuration

The Domain KMS key policy includes a wildcard principal (`*`) to support dynamically created DataZone roles. This is secure because:

- Access is restricted to the current AWS account
- Only roles matching `datazone_*` pattern are allowed
- Permissions are limited to read operations (Decrypt, GenerateDataKey)
- No administrative access is granted

The policy is designed to safely handle service-to-service encryption while maintaining security best practices.

## Troubleshooting

### Common Issues

1. **Blueprint Configuration Conflicts**: If blueprints were manually configured before deployment, delete existing configurations using AWS CLI
2. **IAM Permission Errors**: Ensure the deployment role has all required CloudFormation capabilities
3. **VPC/Subnet Issues**: Verify VPC and subnet IDs exist and are accessible in the deployment region

### Useful Commands

```bash
# List DataZone domains
aws datazone list-domains

# Check blueprint configurations
aws datazone list-environment-blueprints --domain-identifier <domain-id>

# View CloudFormation stack events
aws cloudformation describe-stack-events --stack-name test-apg-sus
```

## Support and Documentation

For additional information:
- [Amazon SageMaker Unified Studio Documentation](https://docs.aws.amazon.com/sagemaker-unified-studio/latest/userguide/what-is-sagemaker-unified-studio.html)
- [Amazon DataZone User Guide](https://docs.aws.amazon.com/datazone/latest/userguide/)
- [AWS CloudFormation Documentation](https://docs.aws.amazon.com/cloudformation/)

## License

This project is licensed under the MIT-0 License. See the LICENSE file for details.


## Contributors

This project was developed and maintained by:

- **Manish Garg**
- **Kanchan Kumar**
- **SHUBHAM KUMAR**
