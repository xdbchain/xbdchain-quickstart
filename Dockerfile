ARG FRIENDBOT_IMAGE_REF

FROM $FRIENDBOT_IMAGE_REF AS friendbot

FROM --platform=linux/amd64 ubuntu:22.04

ARG STELLAR_CORE_VERSION
ARG HORIZON_VERSION
ENV REVISION $REVISION

EXPOSE 5432
EXPOSE 8000
EXPOSE 11625
EXPOSE 11626

ADD dependencies /
RUN /dependencies

COPY --from=friendbot /app/friendbot /usr/local/bin/friendbot

RUN adduser --system --group --quiet --home /var/lib/stellar --disabled-password --shell /bin/bash stellar;

RUN wget -qO - https://apt.stellar.org/SDF.asc | apt-key add -
RUN echo "deb https://apt.stellar.org jammy stable" | tee -a /etc/apt/sources.list.d/SDF.list
RUN apt-get update && apt-get install -y stellar-core=${STELLAR_CORE_VERSION} stellar-horizon=${HORIZON_VERSION}

RUN ["mkdir", "-p", "/opt/stellar"]
RUN ["touch", "/opt/stellar/.docker-ephemeral"]

RUN ["ln", "-s", "/opt/stellar", "/stellar"]
RUN ["ln", "-s", "/opt/stellar/core/etc/stellar-core.cfg", "/stellar-core.cfg"]
RUN ["ln", "-s", "/opt/stellar/horizon/etc/horizon.env", "/horizon.env"]
ADD common /opt/stellar-default/common
ADD local /opt/stellar-default/local
ADD pubnet /opt/stellar-default/pubnet
ADD futurenet /opt/stellar-default/futurenet

ADD start /
RUN ["chmod", "+x", "start"]

ENTRYPOINT ["/start"]
