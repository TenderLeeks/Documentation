#!/bin/bash

set -e

NODE_VERSION="${1:-v16.9.1}"
INStALL_DIR="${2:-/opt}"

wget -q https://nodejs.org/dist/"${NODE_VERSION}"/node-"${NODE_VERSION}"-linux-x64.tar.gz -O /tmp/node-"${NODE_VERSION}"-linux-x64.tar.gz

tar -zxf /tmp/node-"${NODE_VERSION}"-linux-x64.tar.gz -C "${INStALL_DIR}"

mv "${INStALL_DIR}"/node-"${NODE_VERSION}"-linux-x64 "${INStALL_DIR}"/node-"${NODE_VERSION}"

tee /etc/profile.d/node.sh <<EOF
export NODE=/opt/node-${NODE_VERSION}
export PATH=\$NODE/bin:\$PATH
EOF

source /etc/profile
node -v

npm install -g cnpm --registry=https://registry.npm.taobao.org
cnpm install yarn -g
