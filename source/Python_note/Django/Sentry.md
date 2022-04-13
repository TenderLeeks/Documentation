# 错误和异常日志上报 Sentry

## Sentry 集成

两种方法安装 Sentry：

- 使用 Docker 官方服务（量大需要付费，使用方便）。
- 自己搭建服务（从源码安装，或者使用 docker 搭建服务）。

使用 Docker 来安装 Sentry，使用 release 版本

- 链接：https://github.com/getsentry/onpremise/releases
- ./install.sh
- docker-compose up -d

Django 配置集成 sentry，自动上报未捕获异常，错误日志

