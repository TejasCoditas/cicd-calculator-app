# Stage 1: Build the Next.js app
FROM node:20-alpine AS builder
WORKDIR /app

MAINTAINER Tejas

COPY package*.json ./
RUN npm install

COPY . .
RUN npm run build

# Stage 2: Serve using NGINX
FROM nginx:stable-alpine

# Remove default nginx website
RUN rm -rf /usr/share/nginx/html/*

# Copy exported static site from build stage
COPY --from=builder /app/out/ /usr/share/nginx/html/

EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]