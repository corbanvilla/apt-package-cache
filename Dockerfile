FROM nginx:1.15.2

LABEL maintainer="corbanvilla@gmail.com"

EXPOSE 80

RUN apt-get update && \
    apt-get install dpkg-dev git -y

COPY nginx.conf /etc/nginx/nginx.conf
COPY default.conf /etc/nginx/conf.d/default.conf
COPY entrypoint.sh /repo/entrypoint.sh

VOLUME /repo/debs
VOLUME /repo/package-list.txt
VOLUME /repo/cowrie

WORKDIR /repo

ENTRYPOINT [ "bash", "/repo/entrypoint.sh" ]
