# syntax=docker/dockerfile:1.7

# Install only production dependencies in the builder stage.
FROM node:24.22.2-trixie-slim AS builder

WORKDIR /app
COPY app/package.json app/package-lock.json ./
RUN npm ci --omit=dev
COPY app/ ./

# Copy the installed app into a fresh runtime image.
FROM node:24.22.2-trixie-slim

WORKDIR /app
COPY --from=builder /app /app

ENV NODE_ENV=production
EXPOSE 3000

HEALTHCHECK --interval=10s --timeout=3s --start-period=5s --retries=5 \
  CMD node -e "require('http').get('http://localhost:3000/health', r => process.exit(r.statusCode===200?0:1)).on('error', () => process.exit(1))"

CMD ["node", "src/index.js"]
