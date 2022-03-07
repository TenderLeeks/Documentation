#!/usr/bin/env bash

PROJECT_ENTRY="golang.sh"
PROJECT_NAME="golang"


function uninstall() {
  _VERSION="$1"
  _DIR="$2"
  if [ -f "/etc/profile.d/go.sh" ]; then
    rm -f /etc/profile.d/go.sh
    echo "rm /etc/profile.d/go.sh"
  fi

  if [ -f "/tmp/go${_VERSION}.linux-amd64.tar.gz" ]; then
    rm -f /tmp/go"${_VERSION}".linux-amd64.tar.gz
    echo "rm go${_VERSION}.linux-amd64.tar.gz"
  fi

  if [ -d "${_DIR}/go" ]; then
    rm -rf "${_DIR}"/go
    echo "rm ${_DIR}/go"
  fi
}

function install() {
  _VERSION="$1"
  _DIR="$2"
  uninstall "${_VERSION}" "${_DIR}"
  echo
  cd /tmp
  wget https://golang.google.cn/dl/go"${_VERSION}".linux-amd64.tar.gz
  tar -zxf go"${_VERSION}".linux-amd64.tar.gz -C "${_DIR}"
  tee /etc/profile.d/go.sh <<EOF
export GOROOT=${_DIR}/go
export PATH=\$GOROOT/bin:\$PATH
export GOPATH=${_DIR}/go/go_path
export GOPROXY=https://goproxy.cn
EOF
  source /etc/profile
  go version
  [ $? -eq 0 ] && echo "Successful installation"
}

function show_help() {
  echo "Usage: $PROJECT_ENTRY <command> ... [parameters ...]
Commands:
  -h, --help               显示此帮助消息。
  --install                将 ${PROJECT_NAME} 安装到系统。
  --uninstall              卸载 ${PROJECT_NAME}。

Parameters:
  -V <version>                      安装 ${PROJECT_NAME} 版本号，默认：1.17.3
  -d, --directory <directory>       安装目录，默认用户家目录：${HOME}
"
}

function _startswith() {
  _str="$1"
  _sub="$2"
  echo "$_str" | grep -- "^$_sub" >/dev/null 2>&1
}

function _process() {
  _CMD=""
  _DIR="${HOME}"
  _VERSION="1.17.3"
  while [ ${#} -gt 0 ]; do
    case "${1}" in
    -h | --help)
      show_help
      return
      ;;
    --install)
      _CMD="install"
      ;;
    --uninstall)
      _CMD="uninstall"
      ;;
    -d | --directory)
      _DIR="$2"
      shift
      ;;
    -V)
      _VERSION="$2"
      shift
      ;;
    *)
      echo "未知参数：$1"
      show_help
      return
      ;;
    esac
    shift 1
  done
  
  case "${_CMD}" in
  install) install "${_VERSION}" "${_DIR}" ;;
  uninstall) uninstall "${_VERSION}" "${_DIR}" ;;
  *)
    echo "无效命令：${_CMD}"
    show_help
    return 1
    ;;
  esac
}

function main() {
  [ -z "$1" ] && show_help && return
  if _startswith "$1" '-'; then _process "$@"; else "$@"; fi
}

main "$@"
