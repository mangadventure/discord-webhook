FROM alpine:3.19

RUN apk add --no-cache curl~=8.5 jq~=1.7

COPY action.sh /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
