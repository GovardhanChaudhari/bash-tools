FROM bitnami/minideb

WORKDIR /home/bash-tools

COPY . .

#RUN /bin/bash -c 'source /home/bash-tools/index.sh'
RUN ls '/home/bash-tools/index.sh'
CMD ["ls", "/home/bash-tools/"]