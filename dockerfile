# Use the official NGINX base image
FROM nginx:1.25

# Copy our custom index.html into the container's default nginx folder
COPY ./index.html /usr/share/nginx/html/index.html