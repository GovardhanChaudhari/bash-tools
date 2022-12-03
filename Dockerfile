FROM bitnami/minideb

WORKDIR /home/bash-tools

COPY . .

CMD["sh"]

