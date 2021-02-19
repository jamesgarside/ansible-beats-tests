FROM ubuntu:latest

ARG BEAT_TYPE
ARG CONTAINER_PERSIST

ENV CONTAINER_PERSIST=${CONTAINER_PERSIST}
ENV BEAT_TYPE=${BEAT_TYPE}

RUN apt-get update && apt-get install ansible nano curl jq -y

#RUN sed -i 's/#PasswordAuthentication yes/PasswordAuthentication no/g' /etc/ssh/sshd_config
#RUN systemctl enable ssh
#RUN service ssh start

COPY ${BEAT_TYPE} /root/${BEAT_TYPE}
RUN chmod u+x /root/${BEAT_TYPE}/tests/beat_deploy.sh
RUN mv /root/${BEAT_TYPE}/tests/beat_deploy.sh /root/beat_deploy.sh
USER root

ENTRYPOINT ["/root/beat_deploy.sh"]