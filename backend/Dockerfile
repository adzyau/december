# Use the official Bun image
FROM oven/bun:1.1.13 as base

# Install build dependencies
RUN apt-get update && apt-get install -y \
    build-essential \
    python3 \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Copy package files
COPY package.json ./
COPY bun.lock ./

# Install dependencies
RUN bun install

# Copy the rest of the app
COPY . .

# Expose the backend port
EXPOSE 4000

# Start the backend server
CMD ["bun", "run", "dev"]