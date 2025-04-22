FROM hashicorp/terraform:1.10.4
COPY --from=10.145.150.200:8084/dr8/docker/zscaler-assets:rootca /zscaler /zscaler
RUN /zscaler/setup-ca-certificates.sh

ARG USERNAME=vscode
ARG GROUPNAME=vscode
ARG UID=1000
ARG GID=1000
ENV TF_REGISTRY_CLIENT_TIMEOUT=50
ENV TF_DOCS=v0.19.0
ENV TERRAGRUNT=v0.76.6

RUN apk add -q curl unzip aws-cli shadow sudo bash jq
RUN curl -s https://raw.githubusercontent.com/terraform-linters/tflint/master/install_linux.sh | bash
RUN curl -sSLo ./terraform-docs.tar.gz https://terraform-docs.io/dl/${TF_DOCS}/terraform-docs-${TF_DOCS}-$(uname)-amd64.tar.gz \
 && tar -xzf terraform-docs.tar.gz \
 && chmod +x terraform-docs \
 && mv terraform-docs /usr/local/bin/terraform-docs
RUN curl -sSLo ./terragrunt https://github.com/gruntwork-io/terragrunt/releases/download/${TERRAGRUNT}/terragrunt_linux_amd64 \
 && chmod +x terragrunt \
 && mv terragrunt /usr/local/bin/terragrunt
RUN mkdir -p /home/vscode \
 && chown ${UID}:${GID} /home/vscode \
 && useradd -u ${UID} ${USERNAME} -s /bin/bash \
 && echo ${USERNAME}' ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/${USERNAME}-user

USER ${USERNAME}

ENTRYPOINT []
