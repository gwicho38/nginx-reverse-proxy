# Use the official NGINX image from Docker Hub
FROM nginx:latest

# Copy custom NGINX configuration
COPY nginx.conf /etc/nginx/nginx.conf

# Expose ports 80 and 443
EXPOSE 80 443

# Start NGINX when the container starts
CMD ["nginx", "-g", "daemon off;"]
