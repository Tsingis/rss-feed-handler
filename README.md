[![Quality Gate Status](https://sonarcloud.io/api/project_badges/measure?project=Tsingis_rss-notification&metric=alert_status)](https://sonarcloud.io/summary/new_code?id=Tsingis_rss-notification) [![Deploy Status](https://github.com/tsingis/rss-notification/actions/workflows/deploy.yml/badge.svg)](https://github.com/tsingis/rss-notification/actions/workflows/deploy.yml)

# RSS Feed via AWS SNS Topic Subscription

## How it works

- Scheduled new entries via subscription on daily basis providing title and link

## Tools

- AWS Account
- Serverless Framework and Account
- Python 3.12
- Node.js 22
- Docker

## Manual deployment

1. Set environment variables `.env` file
2. Start Docker
3. Run `npm install`
4. Run `npm run deploy`
