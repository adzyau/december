# 1. Build frontend
FROM oven/bun:1.0.25 as frontend-build
WORKDIR /app/frontend
COPY frontend/package.json frontend/bun.lock ./
RUN bun install --frozen-lockfile
COPY frontend ./
RUN bun run build

# 2. Build backend
FROM oven/bun:1.0.25 as backend-build
WORKDIR /app/backend
COPY backend/package.json backend/bun.lock ./
RUN bun install --frozen-lockfile
COPY backend ./
COPY config.ts /app/backend/config.ts
RUN bun build src/index.ts

# 3. Production image
FROM oven/bun:1.0.25
WORKDIR /app

# Copy built frontend
COPY --from=frontend-build /app/frontend/.next /app/frontend/.next
COPY --from=frontend-build /app/frontend/public /app/frontend/public
COPY --from=frontend-build /app/frontend/package.json /app/frontend/package.json
COPY --from=frontend-build /app/frontend/bun.lock /app/frontend/bun.lock

# Copy built backend
COPY --from=backend-build /app/backend /app/backend
COPY --from=backend-build /app/backend/package.json /app/backend/package.json
COPY --from=backend-build /app/backend/bun.lock /app/backend/bun.lock

# Copy root config
COPY config.ts /app/backend/config.ts

# Install dependencies for both
WORKDIR /app/frontend
RUN bun install --frozen-lockfile
WORKDIR /app/backend
RUN bun install --frozen-lockfile

# Expose ports (adjust if needed)
EXPOSE 3000 3001

# Start both servers using bun concurrently
WORKDIR /app
RUN bun add concurrently
CMD ["bun", "concurrently", "--kill-others", "bun --cwd backend src/index.ts", "bun --cwd frontend start"] 