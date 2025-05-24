# Use official NGINX image
FROM nginx:alpine

# Remove default static files
RUN rm -rf /usr/share/nginx/html/*

# Copy your static site files to the NGINX root
COPY . /usr/share/nginx/html

# Expose port (for reference)
EXPOSE 80
