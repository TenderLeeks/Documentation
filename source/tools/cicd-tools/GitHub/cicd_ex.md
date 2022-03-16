

`cat .github)/workflows/ci.yml`

```yaml
name: dotnet package
on:
  push:
    branches:
      - master

jobs:
  build:
    name: Build
    runs-on: ubuntu-latest
#    services:
#      mysql:
#        image: mysql:5.7
#        env:
#          MYSQL_ALLOW_EMPTY_PASSWORD: yes
#          MYSQL_DATABASE: laravel
#        ports:
#          - 3306:3306
#        options: --health-cmd="mysqladmin ping" --health-interval=10s --health-timeout=5s --health-retries=3
      
    steps:
      - uses: actions/checkout@v2
      - name: Setup dotnet
        uses: actions/setup-dotnet@v1
        with:
          dotnet-version: '6.0.x'
      - run: dotnet --version
      - run: dotnet publish tj-financing/src/Tank.Financing.Web/Tank.Financing.Web.csproj -o build/Web
      - run: dotnet publish tj-financing/src/Tank.Financing.DbMigrator/Tank.Financing.DbMigrator.csproj -o build/DbMigrator
      - run: docker build -t tank_financing_test -f .github/workflows/Dockerfile .
      - run: docker tag tank_financing_test hoopoxtest/tank_financing_test
      - run: docker login -u ${{ secrets.DOCKER_TEST_USER }} -p ${{ secrets.DOCKER_TEST_PASSWORD }}
      - run: docker push hoopoxtest/tank_financing_test
      - run: curl ${{ secrets.DEPLOY_TEST_SERVER_URL }}

```

`cat Dockerfile`

```dockerfile
FROM mcr.microsoft.com/dotnet/runtime-deps:6.0-alpine AS base

FROM mcr.microsoft.com/dotnet/sdk:6.0-alpine AS build-env

#FROM mcr.microsoft.com/dotnet/aspnet:6.0

WORKDIR /app

COPY ./build/Web /app/Web
COPY ./build/DbMigrator /app/DbMigrator
COPY ./.github/workflows/start.sh /app

ENTRYPOINT ["/bin/sh", "/app/start.sh"]

```

`cat start.sh`

```shell
#!/bin/bash

cd /app/DbMigrator
dotnet Tank.Financing.DbMigrator.dll

sleep 2

cd /app/Web
dotnet Tank.Financing.Web.dll
```

