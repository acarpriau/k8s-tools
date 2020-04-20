ARG ALPINE_VERSION=3.11

FROM alpine:${ALPINE_VERSION} as builder
MAINTAINER Anthony CARPRIAU <acarpriau@akyrios.be>

ARG AWS_IAM_AUTHENTICATOR_VERSION=1.10.3/2018-07-26
ARG HELM2_VERSION="2.12.1"
ARG HELM_VERSION="3.1.2"
ARG KUBE_VERSION="1.14.10"

ENV OC_VERSION="v3.11.0" \
    OC_TAG_SHA=0cbc58b \
    BUILD_DEPS='tar gzip' \
    RUN_DEPS='curl ca-certificates gettext'

RUN apk --no-cache update && \
    apk add --update --no-cache ca-certificates git openssh && \
    apk add --update -t deps curl tar gzip make bash && \
    rm -rf /var/cache/apk/*

WORKDIR /get
# helm - https://github.com/helm/helm/releases
ENV HELM_VERSION=$HELM_VERSION
RUN wget https://get.helm.sh/helm-v3.1.2-linux-amd64.tar.gz
RUN tar xvf helm-v${HELM_VERSION}-linux-amd64.tar.gz
RUN mv /get/linux-amd64/helm /get/linux-amd64/helm3

# helm2 
ENV HELM2_VERSION=$HELM2_VERSION
RUN curl -LO https://storage.googleapis.com/kubernetes-helm/helm-v${HELM2_VERSION}-linux-amd64.tar.gz
RUN echo "$(curl -Ls https://storage.googleapis.com/kubernetes-helm/helm-v${HELM2_VERSION}-linux-amd64.tar.gz.sha256)  helm-v${HELM2_VERSION}-linux-amd64.tar.gz" | tee helm-v${HELM2_VERSION}-linux-amd64.tar.gz.sha256
RUN sha256sum -cw helm-v${HELM2_VERSION}-linux-amd64.tar.gz.sha256
RUN tar xvf helm-v${HELM2_VERSION}-linux-amd64.tar.gz

# kubectl
ENV KUBECTL_VERSION=$KUBE_VERSION
RUN curl -LO https://storage.googleapis.com/kubernetes-release/release/v${KUBECTL_VERSION}/bin/linux/amd64/kubectl
RUN echo "$(curl -Ls https://storage.googleapis.com/kubernetes-release/release/v${KUBECTL_VERSION}/bin/linux/amd64/kubectl.sha512)  kubectl" | tee kubectl.sha512
RUN sha512sum -cw kubectl.sha512

# AWS IAM Authenticator - sha256sum does not like AWS's stored sha256 file.  We need to rebuild it
ENV AWS_IAM_AUTHENTICATOR_VERSION=$AWS_IAM_AUTHENTICATOR_VERSION
RUN curl -LO https://amazon-eks.s3-us-west-2.amazonaws.com/${AWS_IAM_AUTHENTICATOR_VERSION}/bin/linux/amd64/aws-iam-authenticator
RUN curl -Ls https://amazon-eks.s3-us-west-2.amazonaws.com/${AWS_IAM_AUTHENTICATOR_VERSION}/bin/linux/amd64/aws-iam-authenticator.sha256 | awk '{ print $1, "", $2 }' | tee aws-iam-authenticator.sha256
RUN sha256sum -cw aws-iam-authenticator.sha256

# OpenShift CLI
RUN apk --no-cache add $BUILD_DEPS $RUN_DEPS && \
    curl -sLo /tmp/oc.tar.gz https://github.com/openshift/origin/releases/download/${OC_VERSION}/openshift-origin-client-tools-${OC_VERSION}-${OC_TAG_SHA}-linux-64bit.tar.gz && \
    tar xzvf /tmp/oc.tar.gz -C /tmp/ && \
    mv /tmp/openshift-origin-client-tools-${OC_VERSION}-${OC_TAG_SHA}-linux-64bit/oc /usr/local/bin/ && \
    rm -rf /tmp/oc.tar.gz /tmp/openshift-origin-client-tools-${OC_VERSION}-${OC_TAG_SHA}-linux-64bit && apk del $BUILD_DEPS

WORKDIR /build
RUN cp /get/linux-amd64/tiller .
RUN cp /get/linux-amd64/helm .
RUN cp /get/linux-amd64/helm3 .
RUN cp /get/kubectl .
RUN cp /get/aws-iam-authenticator .
RUN chmod +x *

FROM alpine:$ALPINE_VERSION
RUN apk add --update --no-cache ca-certificates openssl git openssh
RUN apk -uv add --no-cache groff jq less python3
RUN pip3 install --upgrade awscli
COPY --from=builder /build /usr/local/bin/
COPY --from=praqma/helmsman /bin/helmsman /usr/local/bin/helmsman

CMD ["/usr/local/bin/oc"]
