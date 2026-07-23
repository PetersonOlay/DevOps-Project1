FROM node:20-alpine AS builder
WORKDIR /app
COPY package.json package-lock.json* ./
RUN npm install --omit=dev

FROM node:20-alpine
WORKDIR /app
RUN addgroup -S app && adduser -S app -G app
COPY --from=builder /app/node_modules ./node_modules
COPY package.json ./
COPY src ./src

USER app
EXPOSE 3000
CMD ["node", "src/index.js"]
