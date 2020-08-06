# Skywalking-Ingress-Overlay
通过叠加Skywalking Nginx Lua的方式增强Ingress

# 配置方式
该镜像默认启用了Skywalking，且未配置开关按钮，请与官方镜像配合使用。

通过增加环境变量的方式来进行配置，支持如下环境变量：

SW_SERVICE_NAME: 服务名称

SW_SERVICE_INSTANCE_NAME: 实例名称，可以取自ID

SW_BACKEND_SERVERS: 后端服务地址，使用http端口。如：http://skywalking-aop.skywalking:12800

```
- name: SW_SERVICE_NAME
  value: Kubernetes Ingress
- name: SW_BACKEND_SERVERS
  value: http://skywalking-aop.skywalking:12800
- name: SW_SERVICE_INSTANCE_NAME
  valueFrom:
    fieldRef:
      fieldPath: metadata.uid
```