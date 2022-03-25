# vscode
vscode 带各种环境


## docker-compose

```bash
version: '3'
services:
  vscode:
    image: hewenyulucky/vscode
    environment:
      - GOPROXY=https://goproxy.cn,direct
      - TZ=Asia/Shanghai
    ports:
      - "8080:8080"
    restart: always

```

## Password

```bash
cat ~/.config/code-server/config.yaml
```