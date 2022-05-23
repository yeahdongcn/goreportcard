FROM golang:1.16-alpine

# SSH key for getting code
ARG SSH_KEY

# hostname for internal github/gitlab server
ARG GIT_HOST

# most of this is verbatim from the project.  openssl is added
RUN apk update && apk upgrade && apk add --no-cache git make openssl openssh build-base

# trust repo's self signed cert
RUN echo | openssl s_client -showcerts -servername $GIT_HOST -connect $GIT_HOST:443 2>&1 | sed -ne '/BEGIN\ CERTIFICATE/,/END\ CERTIFICATE/ p' > /usr/local/share/ca-certificates/$GIT_HOST.pem && update-ca-certificates

# stage ssh key and accept repos's host key
RUN mkdir -p /root/.ssh && chmod 700 /root/.ssh && echo "$SSH_KEY" > /root/.ssh/id_rsa && chmod 600 /root/.ssh/id_rsa && ssh-keyscan -H $GIT_HOST > /root/.ssh/known_hosts

# configure git to use ssh over https
RUN git config --global url.git@$GIT_HOST:.insteadOf https://$GIT_HOST/

RUN unset GOPRIVATE && go env -w GOPRIVATE="$GIT_HOST/*"

# Install app dependencies
RUN GO111MODULE=off go get github.com/yeahdongcn/goreportcard

WORKDIR $GOPATH/src/github.com/yeahdongcn/goreportcard

RUN go mod tidy && go mod vendor

RUN ./scripts/make-install.sh

EXPOSE 8000

CMD ["make", "start"]