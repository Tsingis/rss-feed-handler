[![Quality Gate Status](https://sonarcloud.io/api/project_badges/measure?project=Tsingis_rss-notification&metric=alert_status)](https://sonarcloud.io/summary/new_code?id=Tsingis_rss-notification) [![Deploy Status](https://github.com/tsingis/rss-notification/actions/workflows/terraform.yml/badge.svg)](https://github.com/Tsingis/rss-notification/actions/workflows/terraform.yml)

# RSS Feeds updates via AWS SNS Topic Subscription

## How it works

- Scheduled new entries via subscription on daily basis providing title and link

## Tools

- AWS Account
- Python
- Terraform

## Manual deployment

1. Set `terraform.tfvars` contents
2. Run `terraform init -backend-config="bucket=<TF_STATE_BUCKET>"`
3. Run `terraform plan -out=tfplan`
4. Run `terraform apply tfplan`
