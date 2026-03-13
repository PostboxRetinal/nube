FROM haproxy:2.3
RUN mkdir -p /run/haproxy/
COPY haproxy.cfg /usr/local/etc/haproxy/haproxy.cfg
COPY errors/ /usr/local/etc/haproxy/errors/