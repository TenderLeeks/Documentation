#!/usr/bin/env bash
set -e

VERSION="${2:-v16.9.1}"
DIR="${3:-${HOME}}"

echo "Node version is ${VERSION}."
echo "The Node installation directory is ${DIR}"
echo

function uninstall() {
  if [ -f "/etc/profile.d/node.sh" ]; then
    rm -f /etc/profile.d/node.sh
    echo "rm /etc/profile.d/node.sh"
  else
    echo "not found /etc/profile.d/node.sh"
  fi

  if [ -f "/tmp/node-${VERSION}-linux-x64.tar.gz" ]; then
    rm -f /tmp/node-"${VERSION}"-linux-x64.tar.gz
    echo "rm /tmp/node-${VERSION}-linux-x64.tar.gz"
  else
    echo "not found /tmp/node-${VERSION}-linux-x64.tar.gz"
  fi

  if [ -d "${DIR}/node-${VERSION}" ]; then
    rm -rf "${DIR}"/node-"${VERSION}"
    echo "rm ${DIR}/node-${VERSION}"
  else
    echo "not found ${DIR}/node-${VERSION}"
  fi
}

function install() {
  uninstall
  echo
  cd /tmp
  wget https://nodejs.org/dist/"${VERSION}"/node-"${VERSION}"-linux-x64.tar.gz
  tar -zxf node-"${VERSION}"-linux-x64.tar.gz -C "${DIR}"
  mv "${DIR}"/node-"${VERSION}"-linux-x64 "${DIR}"/node-"${VERSION}"
  tee /etc/profile.d/node.sh <<EOF
export NODE=${DIR}/node-${VERSION}
export PATH=\$NODE/bin:\$PATH
EOF
  source /etc/profile
  node -v
  [ $? -eq 0 ] && echo "Successful installation"
}

function install_all() {
  install
  npm install -g cnpm --registry=https://registry.npm.taobao.org
  npm install yarn -g
  npm install pm2 -g
  npm install apidoc -g
}

case "$1" in
    install)
        install
        ;;
    uninstall)
        uninstall
        ;;
    install_all)
        install_all
        ;;
    *)
        echo "Usage: $0 {install|install_all|uninstall}"
        exit 2
esac
