FROM alpine:latest

RUN apk add --update python3 py3-pip 

COPY tufts /src/tufts

EXPOSE 80/tcp
CMD ["python3", "/src/tufts" ]
