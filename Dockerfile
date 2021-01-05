FROM busybox

WORKDIR /tmp

ENV SKYWALKING_VERSION v0.3.0

RUN set -eux ;\
	wget -O skywalking.tar.gz https://github.com/apache/skywalking-nginx-lua/archive/${SKYWALKING_VERSION}.tar.gz ;\
	tar --strip-components 1 -zxvf skywalking.tar.gz

# 二阶段构建
FROM k8s.gcr.io/ingress-nginx/controller:v0.43.0

COPY --from=0 /tmp/lib  /etc/nginx/lua

ADD nginx.tmpl /etc/nginx/template