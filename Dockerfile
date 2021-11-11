FROM python:3.7-alpine

ARG CLOUDSMITH_CLI_VERSION

RUN pip install --no-cache-dir cloudsmith-cli==${CLOUDSMITH_CLI_VERSION}
ENTRYPOINT [ "cloudsmith" ]
