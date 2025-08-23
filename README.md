[![Quality Gate Status](https://sonarcloud.io/api/project_badges/measure?project=Tsingis_rss-notification&metric=alert_status)](https://sonarcloud.io/summary/new_code?id=Tsingis_rss-notification) [![Deploy Status](https://github.com/tsingis/rss-notification/actions/workflows/terraform.yml/badge.svg)](https://github.com/Tsingis/rss-notification/actions/workflows/terraform.yml)

# RSS Feeds updates via AWS SNS Topic Subscription

## How it works

- Scheduled new entries via subscription on daily basis providing title and link

## Tools

- Python
- AWS
- Terraform

## Dev environment setup

- Install pipenv globally `pip install -r requirements.txt`
- Set up environment `pipenv install --ignore-pipfile --dev`
- Activate virtual environment `pipenv shell`

## Manual deployment

1. Activate virtual environment if not active `pipenv shell`
2. Run `pipenv requirements > deps.txt`
3. Run `pipenv run create_package.py -r deps.txt`
4. Set `terraform.tfvars` contents
5. Run `terraform init -backend-config="bucket=<TF_STATE_BUCKET>"`
6. Run `terraform plan -out=tfplan`
7. Run `terraform apply tfplan`
