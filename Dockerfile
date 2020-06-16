FROM alpine:3.10.3

LABEL "com.github.actions.name"="Label approved pull requests"
LABEL "com.github.actions.description"="Label approved pull requests with a personal label of the approver"
LABEL "com.github.actions.icon"="tag"
LABEL "com.github.actions.color"="gray-dark"

LABEL version="1.0.0"
LABEL repository="http://github.com/machtfit/label-when-approved-action"
LABEL homepage="http://github.com/machtfit/label-when-approved-action"
LABEL maintainer="Oliver Runge <oliver.runge@machtfit.de>"

RUN apk add --no-cache bash curl jq

ADD entrypoint.sh /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]
