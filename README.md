# Dockerization & Kubernetes

For the longest time I have had 1 single machine, with all my services running happily on it. It works because none of these apps ever scaled to tons of traffic. But, I did move around between Linode, AWS and finally GCP, and also between machine types. Every migration was certainly painful.

Also, I had 1 haproxy file with all my routes. There was always a risk that one service will break all routing for everyone.

Finally i have decided to move things to Docker & Kubernetes. I want to write this post to give an overview of my dockerization & k8 journey.

Read the full article here: https://theawake.dev/blog/tech/cost-of-dockerization/
