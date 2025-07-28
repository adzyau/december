# Multi-stage Dockerfile for December AI Development Platform

# Stage 1: Build frontend
FROM node:18-alpine AS frontend-builder

# Install bun
RUN curl -fsSL https://bun.sh/install | bash
ENV PATH="/root/.bun/bin:$PATH"

WORKDIR /app/frontend
COPY frontend/package*.json ./
COPY frontend/bun.lock* ./
RUN bun install

COPY frontend/ .
RUN bun run build

# Stage 2: Build backend
FROM node:18-alpine AS backend-builder

# Install bun
RUN curl -fsSL https://bun.sh/install | bash
ENV PATH="/root/.bun/bin:$PATH"

WORKDIR /app/backend
COPY backend/package*.json ./
COPY backend/bun.lock* ./
RUN bun install

COPY backend/ .

# Stage 3: Production image
FROM node:18-alpine AS production

# Install system dependencies
RUN apk add --no-cache \
    curl \
    bash \
    docker-cli \
    && rm -rf /var/cache/apk/*

# Install bun
RUN curl -fsSL https://bun.sh/install | bash
ENV PATH="/root/.bun/bin:$PATH"

WORKDIR /app

# Copy built frontend
COPY --from=frontend-builder /app/frontend/.next ./frontend/.next
COPY --from=frontend-builder /app/frontend/public ./frontend/public
COPY --from=frontend-builder /app/frontend/package.json ./frontend/
COPY --from=frontend-builder /app/frontend/next.config.ts ./frontend/
COPY --from=frontend-builder /app/frontend/node_modules ./frontend/node_modules

# Copy backend
COPY --from=backend-builder /app/backend ./backend

# Copy config file
COPY config.ts ./

# Create startup script
RUN echo '#!/bin/bash\n\
echo "Starting December AI Platform..."\n\
\n\
# Copy config to backend\n\
cp /app/config.ts /app/backend/config.ts\n\
\n\
# Start backend in background\n\
cd /app/backend && bun src/index.ts &\n\
BACKEND_PID=$!\n\
\n\
# Wait for backend to start\n\
sleep 5\n\
\n\
# Start frontend\n\
cd /app/frontend && bun start &\n\
FRONTEND_PID=$!\n\
\n\
echo "December is running!"\n\
echo "Frontend: http://localhost:3000"\n\
echo "Backend API: http://localhost:4000"\n\
\n\
# Wait for both processes\n\
wait $BACKEND_PID $FRONTEND_PID\n\
' > /app/start.sh && chmod +x /app/start.sh

# Expose ports
EXPOSE 3000 4000

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
  CMD curl -f http://localhost:4000 || exit 1

CMD ["/app/start.sh"]