# Use the official Bun image
FROM oven/bun:1.1.13 as base

# Install build dependencies
RUN apt-get update && apt-get install -y \
    build-essential \
    python3 \
    python3-dev \
    make \
    g++ \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Copy package files
COPY package.json ./
COPY bun.lock ./

# Install dependencies
RUN bun install --verbose

# Copy the rest of the app
COPY . .

# Install next globally for better reliability
RUN bun add -g next@13.4.19

# Expose the frontend port
EXPOSE 3000

# Start the Next.js app in development mode
CMD ["bun", "run", "dev"]