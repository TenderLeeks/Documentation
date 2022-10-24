



在用ubuntu:18.04基本镜像进行构建的时候。出现啦选择时区的地方，然后会卡住。

```
可以通过配置环境变量，来跳过这个步骤
ENV DEBIAN_FRONTEND=noninteractive
```



