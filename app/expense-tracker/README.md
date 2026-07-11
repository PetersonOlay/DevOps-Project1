# expense-tracker

Node.js/Express API storing expense records in RDS Postgres and receipt files in S3.

## Environment variables

| Variable        | Description                                              |
|-----------------|------------------------------------------------------------|
| `DB_HOST`       | RDS endpoint (address only, no port)                       |
| `DB_PORT`       | RDS port, usually `5432`                                    |
| `DB_NAME`       | Database name                                                |
| `DB_SECRET_ARN` | Secrets Manager ARN of the RDS-managed master credentials    |
| `S3_BUCKET`     | App S3 bucket name                                            |
| `AWS_REGION`    | AWS region                                                     |
| `APP_ENV`       | Environment name, used as an S3 key prefix (`dev`/`stg`/`prod`) |
| `PORT`          | HTTP port, default `3000`                                     |

Credentials are never passed as env vars: the app fetches the DB password from Secrets Manager
and talks to S3 using the pod's IRSA role, both at runtime via the AWS SDK's default credential
chain.

## Endpoints

- `POST /expenses` — multipart form: `amount`, `category`, `expense_date`, `description`
  (optional), `receipt` (optional file).
- `GET /expenses?category=&month=YYYY-MM` — list, optionally filtered.
- `GET /expenses/:id` — detail, including a presigned receipt URL if one was uploaded.
- `GET /expenses/summary` — totals grouped by category and month.
- `DELETE /expenses/:id` — deletes the record and its receipt object.
- `GET /healthz` — liveness/readiness probe target.

## Local development

```
npm install
export DB_HOST=localhost DB_PORT=5432 DB_NAME=expenses DB_SECRET_ARN=... S3_BUCKET=... AWS_REGION=us-east-1
npm run migrate
npm start
```

(Requires AWS credentials in your environment for the Secrets Manager/S3 calls, or a local
Postgres + stub for offline testing.)

## Build & push to ECR

```
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin <ecr_repository_url>
docker build -t <ecr_repository_url>:dev .
docker push <ecr_repository_url>:dev
```

`<ecr_repository_url>` comes from `terraform -chdir=../../environments/dev output ecr_repository_url`.
