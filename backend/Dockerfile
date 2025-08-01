# Use the official Bun image
FROM oven/bun:1.1.13 as base

# Install build dependencies including Python and node-gyp requirements
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

# Set npm configuration to handle optional dependencies gracefully
ENV NPM_CONFIG_OPTIONAL=false
ENV BUN_CONFIG_OPTIONAL=false

# Install dependencies with specific flags to handle native modules
RUN bun install --no-optional --verbose

# Copy the rest of the app
COPY . .

# Expose the backend port
EXPOSE 4000

# Start the backend server
CMD ["bun", "run", "dev"]