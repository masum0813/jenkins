# lts with jdk8, starting with 2.303 jdk11 is the default
FROM jenkins/jenkins:2.319.3-lts-jdk11

ENV VELERO_VERSION=1.7.0

# https://docs.docker.com/engine/reference/builder/#automatic-platform-args-in-the-global-scope
ARG TARGETARCH
ARG TARGETOS


# change user to root to install some tools
USER root
RUN apt-get update -y \
 && apt-get install python3-pip python3-venv jq libltdl7 netcat rsync -y \
 && apt-get clean -y

RUN pip3 install awscli \
    ansible==2.10.7 \
    openshift==0.12.1 \
    docker==5.0.0 \
    ansible-modules-hashivault==4.2.3

RUN curl -L https://github.com/mikefarah/yq/releases/download/3.3.2/yq_${TARGETOS}_${TARGETARCH} -o /usr/bin/yq && \
    chmod +x /usr/bin/yq

RUN curl -L -o /usr/bin/aws-iam-authenticator \
    https://amazon-eks.s3.us-west-2.amazonaws.com/1.17.9/2020-08-04/bin/${TARGETOS}/${TARGETARCH}/aws-iam-authenticator && \
    chmod +x /usr/bin/aws-iam-authenticator

RUN curl -L https://github.com/vmware-tanzu/velero/releases/download/v${VELERO_VERSION}/velero-v${VELERO_VERSION}-${TARGETOS}-${TARGETARCH}.tar.gz -o /tmp/velero-tar.gz && \
    tar xvf /tmp/velero-tar.gz && \
    mv velero-v${VELERO_VERSION}-${TARGETOS}-${TARGETARCH}/velero /usr/local/bin && \
    rm -rf /tmp/velero-tar.gz velero-v${VELERO_VERSION}-${TARGETOS}-${TARGETARCH}

RUN curl -L -o /tmp/vault.zip \
    https://releases.hashicorp.com/vault/1.9.3/vault_1.9.3_${TARGETOS}_${TARGETARCH}.zip && \
    cd /tmp && unzip vault.zip && mv vault /usr/bin/ && \
    rm -rf /tmp/vault.zip

# overrite install-plugins to limit concurrent downloads
COPY scripts/install-plugins.sh /usr/local/bin/install-plugins.sh

# move jenkins-plugin-cli binary in order to use the old plugin download strategy
RUN mv /bin/jenkins-plugin-cli /bin/jenkins-plugin-cli-moved
