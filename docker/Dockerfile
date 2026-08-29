FROM alpine:latest 
RUN apk add --no-cache --update openssh
# Create a group and user
RUN addgroup -S user && adduser -S user -G user -D
RUN mkdir -p /home/user/.ssh && ln -s /run/secrets/user_ssh_key /home/user/.ssh/id_rsa
RUN chown -R user:user /home/user/.ssh
RUN echo "Host *.trabe.io\n\tStrictHostKeyChecking no\n" >> /home/user/.ssh/config
USER user
EXPOSE 22
CMD ["/usr/sbin/sshd","-D"]
