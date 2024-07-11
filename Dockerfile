# before migrating away from MPL
FROM docker.io/hashicorp/terraform:1.5.7 as terraform
# latest version at time
FROM docker.io/amazon/aws-cli:2.17.12 as aws-cli
# Fedora Linux 39
# FROM quay.io/ansible/creator-ee:v24.2.0 as ansible
# choosing 3.11.9 because that's the version shown in aws --version
FROM docker.io/python:3.11.9

COPY --from=terraform /bin/terraform /bin/terraform
COPY --from=aws-cli /usr/local/aws-cli /usr/local/aws-cli
COPY --chown=root:root --chmod=600 id_rsa* /root/.ssh/

# putting in path
RUN ln -s /usr/local/aws-cli/v2/current/bin/aws /usr/local/bin/aws
# installing python bits to help make ansible more reproducable
RUN pip3 install pipx
RUN pipx install pipenv==2024.0.1 && pipx ensurepath
# install system packages for ansible to use
# I'm intentionally not clearing the cache like normal so it's easy for people to install packages locally
RUN apt-get update && apt-get install -y rsync jq direnv nmap
RUN echo 'eval "$(direnv hook bash)"' >> ~/.bashrc
WORKDIR /app