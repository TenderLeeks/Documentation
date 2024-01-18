# Docker Scripts

## 清除主机Docker历史镜像

```bash
mkdir -p /opt/scripts/
vim /opt/scripts/delete_old_images.sh
```

```bash
#!/bin/bash

# 0 * * * * bash /opt/scripts/delete_old_images.sh >/dev/null 2>&1

HOME_DIR=$(cd $(dirname "$0") && pwd )

LOG_DIR="${HOME_DIR}/logs"

LOG_FILE="${LOG_DIR}/delete_old_images.log"

[ -d "${LOG_DIR}" ] || mkdir -p "${LOG_DIR}"

function log() {
  if [[ $# -eq 1 ]];then
    msg=$1
    echo -e "$(date +"%Y-%m-%d %H:%M:%S") \033[32m[INFO]\033[0m ${msg}" >> "${LOG_FILE}"
  elif [[ $# -eq 2 ]];then
    param=$1
    msg=$2
    if [[ ${param} = "-w" ]];then
      echo -e "$(date +"%Y-%m-%d %H:%M:%S") \033[34m[WARNING]\033[0m ${msg}" >> "${LOG_FILE}"
    elif [[ ${param} = "-e" ]];then
      echo -e "$(date +"%Y-%m-%d %H:%M:%S") \033[31m[ERROR]\033[0m ${msg}" >> "${LOG_FILE}"
      exit 1
    elif [[ ${param} = "-d" ]];then
      echo "$(date +"%Y-%m-%d %H:%M:%S") [DEBUG] ${msg}" >> "${LOG_FILE}"
      if [[ ${DEBUG_FLAG} = 1 ]];then
        set -x
      fi
    fi
  fi
}


image_name=$(docker images | awk 'NR >1 {print $1}' | sort -u)

for name in ${image_name}; do
  log "检查镜像: ${name}"
  image_id=$(docker images|grep ${name}|awk 'NR > 1 {print $3}')

  if [ -n "${image_id}" ]; then
    log "image_id: ${image_id}"
    
    for image in ${image_id}; do
      docker_name=$(docker images|grep ${image} | awk '{print $1}')
      
      if [ "x${docker_name}" == "x${name}" ]; then
        if docker rmi ${image}; then
          log "删除镜像: ${image} 成功"
        else
          log "删除镜像: ${image} 失败"
        fi
      fi
    done
  fi
done

log "------------------"

```

