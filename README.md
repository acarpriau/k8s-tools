# Docker k8s-tools
This is a docker image containing various tools useful for communicating with Amazon EKS. This is useful when using a docker container in conjunction with CI to talk to Amazon EKS and OpenShift. It includes alpine linux, and the following tools:

* aws-iam-authenticator
* groff
* helm2
* helm3
* helmsman
* jq
* kubectl
* less
* openshift cli (oc)

# Build & push image
docker build -t ${HUB_USER}/k8s-tools:latest .

# Push to Dockerhub
docker push ${HUB_USER}/k8s-tools:latest
