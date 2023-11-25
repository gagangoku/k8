# docker build --platform linux/amd64 -t gagangoku1/ellie-cult-cron .
# docker push gagangoku1/ellie-cult-cron
FROM ubuntu:22.04

RUN apt-get update && apt-get install -y bash wget

WORKDIR /app
COPY entrypoint.sh .

RUN chmod +x /app/entrypoint.sh

ENTRYPOINT ["/app/entrypoint.sh"]
