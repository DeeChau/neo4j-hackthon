FROM bitnami/neo4j:3

COPY ./sample.conf /opt/bitnami/neo4j/conf/neo4j.conf

ENV _JAVA_OPTIONS=-Xmx6G

USER 1001
ENTRYPOINT [ "/app-entrypoint.sh" ]
CMD [ "nami", "start", "--foreground", "neo4j" ]
