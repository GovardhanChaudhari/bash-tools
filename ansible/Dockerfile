FROM cytopia/ansible:latest-tools as ansible
COPY ansible.cfg /etc/
RUN ["apk","add","--no-cache","openssh"]
EXPOSE 22
CMD ["/usr/sbin/sshd","-D"]
