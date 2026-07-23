# expense-tracker-frontend

React + Vite UI for the expense-tracker API. Talks to the backend with same-origin relative
fetches (`/expenses`, `/healthz`) — deployed behind the same ALB Ingress as the backend, path-split
so both services share one origin and no CORS configuration is needed.

## Local development

```
npm install
npm run dev
```

`vite.config.js` proxies `/expenses` and `/healthz` to `http://localhost:3000` — run
`app/expense-tracker-backend` locally on port 3000 alongside this for a full local loop.

## Build & push to ECR

```
npm run build
docker build -t <frontend_ecr_repository_url>:dev .
docker push <frontend_ecr_repository_url>:dev
```
