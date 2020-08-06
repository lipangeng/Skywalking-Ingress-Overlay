FROM quay.io/kubernetes-ingress-controller/nginx-ingress-controller:0.11.0

ADD nginx.tmpl /etc/nginx/template
ADD skywalking /etc/nginx/lua/skywalking
ADD skywalking.sh /

RUN set -eux ;\
    \
    env ;\
    \
    chmod +x /skywalking.sh ;\
    /skywalking.sh


