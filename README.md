# azza_Reach_project
containerized multi-tier PHP web application hosted on AWS ECS using terraform 
# created a simple PHP multi tear web application which using a DB in the backend (simple login and registeration form)
# prepared the Docker file which using php docker image to upload my php code and prepare the web server
# Build the image from the Docker file on a Docker server
# Created an ECR repo for my image by terraform
# Tag my image on the Docker server to be pushed on the new ECR
# Create an ECS cluster, ECS task defenition and ECS service to host my app on container and used 3 containers for my application 
# Create an ALB to load balance the work load on these containers
# Create a DB on RDS to be the backend of my application and mentioned its information container as an Environment variables to be used by my app
# Create a domain name for my application using Route53
# Create a CloudFront distribution to cache my app static pages on different edge locations to reduce the latency of responce from my app in these locations
