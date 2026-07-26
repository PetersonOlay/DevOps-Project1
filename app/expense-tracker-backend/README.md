# expense-tracker-backend

Node.js/Express API storing expense records in RDS Postgres and receipt files in S3.

## Environment variables

| Variable        | Description                                              |
|-----------------|------------------------------------------------------------|
| `DB_HOST`       | RDS endpoint (address only, no port)                       |
| `DB_PORT`       | RDS port, usually `5432`                                    |
| `DB_NAME`       | Database name                                                |
| `DB_USERNAME`   | RDS master username, synced from Secrets Manager by External Secrets Operator |
| `DB_PASSWORD`   | RDS master password, synced from Secrets Manager by External Secrets Operator |
| `S3_BUCKET`     | App S3 bucket name                                            |
| `AWS_REGION`    | AWS region                                                     |
| `APP_ENV`       | Environment name, used as an S3 key prefix (`dev`/`stg`/`prod`) |
| `PORT`          | HTTP port, default `3000`                                     |

`DB_USERNAME`/`DB_PASSWORD` come from a Kubernetes Secret that External Secrets Operator syncs
from the RDS-managed Secrets Manager secret (see `helm/expense-tracker/templates/backend-secretstore.yaml`
and `backend-externalsecret.yaml`) — the app never calls the AWS SDK for this itself. S3 access
still goes through the pod's IRSA role via the AWS SDK's default credential chain.

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
export DB_HOST=localhost DB_PORT=5432 DB_NAME=expenses DB_USERNAME=... DB_PASSWORD=... S3_BUCKET=... AWS_REGION=us-east-1
npm run migrate
npm start
```

(Requires AWS credentials in your environment for the S3 calls, or a local Postgres + stub for
offline testing.)

## Build & push to ECR

```
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin <backend_ecr_repository_url>
docker build -t <backend_ecr_repository_url>:dev .
docker push <backend_ecr_repository_url>:dev
```

`<backend_ecr_repository_url>` comes from `terraform -chdir=../../environments/dev output ecr_repository_url`.
