# Demo Blue-Green Deployment

[![ko-fi](https://ko-fi.com/img/githubbutton_sm.svg)](https://ko-fi.com/M4M0U28LL)

Zero downtime deployment with Docker Compose &amp; Nginx

## Quick Test

Easily run demo with command

```bash
./pull.run-service.sh
```

## Run demo with your configuration

Change the image in `docker-compose.yml`

```yaml
...
services:
  api_blue: &api
    image: <<your-docker-image-name>>
...
```

Build image command (Optional)

```bash
docker build -t <<your-docker-image-name>> .
```
