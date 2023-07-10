# docker build --platform linux/amd64 -t gagangoku1/backer-mysql .
# docker push gagangoku1/backer-mysql
FROM ubuntu/mysql:8.0-20.04_beta

RUN apt-get update && apt-get install -y bash curl gnupg

RUN echo "deb http://packages.cloud.google.com/apt cloud-sdk-xenial main" | tee -a /etc/apt/sources.list.d/google-cloud-sdk.list && \
  curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add - && \
  apt-get update && \
  apt-get install -y python3 google-cloud-sdk

WORKDIR /app
COPY entrypoint.sh .

RUN chmod +x /app/entrypoint.sh

ENTRYPOINT ["/app/entrypoint.sh"]
