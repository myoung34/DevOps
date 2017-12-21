FROM capitalone/cloud-custodian

RUN apk add -U ca-certificates curl
RUN curl -L https://github.com/Yelp/dumb-init/releases/download/v1.2.0/dumb-init_1.2.0_amd64 >/usr/local/bin/dumb-init
RUN chmod +x /usr/local/bin/dumb-init

RUN mkdir /opt
COPY run.sh /opt
RUN chmod +x /opt/run.sh

COPY rules /tmp

RUN echo 'policies:' >/tmp/custodian.yml
RUN for yml in $(find /tmp -name '*.yml'); do cat $yml; done | grep -v policies: >>/tmp/custodian.yml

ENTRYPOINT ["/usr/local/bin/dumb-init", "--"]
CMD ["/opt/run.sh"]
