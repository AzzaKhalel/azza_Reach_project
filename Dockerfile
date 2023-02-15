FROM php:zts-alpine3.17

# Set the working directory to /app
WORKDIR '/usr/src/myapp'

# Copy package.json to the working directory
COPY phpapp/* .

# Make port 3000 available to the world outside this container
EXPOSE 3000

# Run index.js when the container launches
CMD ["php", "login.php"]