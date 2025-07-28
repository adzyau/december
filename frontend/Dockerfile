# Use the official Bun image
FROM oven/bun:1.1.13 as base

WORKDIR /app

# Copy package and lock files
COPY package.json bun.lock ./

# Install dependencies
RUN bun install

# Copy the rest of the app
COPY . .

# Expose the frontend port
EXPOSE 3000

# Start the Next.js app in development mode
CMD ["bun", "dev"] 