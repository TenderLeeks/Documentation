#!/usr/bin/env bash
set -e

VERSION="${2:-1.17.3}"
DIR="${3:-${HOME}}"

echo "GoLang version is ${VERSION}."
echo "The GoLang installation directory is ${DIR}"
echo

function uninstall() {
  if [ -f "/etc/profile.d/go.sh" ]; then
    rm -f /etc/profile.d/go.sh
    echo "rm /etc/profile.d/go.sh"
  else
    echo "not found /etc/profile.d/go.sh"
  fi

  if [ -f "/tmp/go${VERSION}.linux-amd64.tar.gz" ]; then
    rm -f /tmp/go"${VERSION}".linux-amd64.tar.gz
    echo "rm go${VERSION}.linux-amd64.tar.gz"
  else
    echo "not found /tmp/go${VERSION}.linux-amd64.tar.gz"
  fi

  if [ -d "${DIR}/go" ]; then
    rm -rf "${DIR}"/go
    echo "rm ${DIR}/go"
  else
    echo "not found ${DIR}/go"
  fi
}

function install() {
  uninstall
  echo
  cd /tmp
  wget https://golang.google.cn/dl/go"${VERSION}".linux-amd64.tar.gz
  tar -zxf go"${VERSION}".linux-amd64.tar.gz -C "${DIR}"
  tee /etc/profile.d/go.sh <<EOF
export GOROOT=${DIR}/go
export PATH=\$GOROOT/bin:\$PATH
export GOPATH=${DIR}/go/go_path
export GOPROXY=https://goproxy.cn
EOF
  source /etc/profile
  go version
  [ $? -eq 0 ] && echo "Successful installation"
}


case "$1" in
    install)
        install
        ;;
    uninstall)
        uninstall
        ;;
    *)
        echo "Usage: $0 {install|uninstall}"
        exit 2
esac
