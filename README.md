# dockerless-docker-downloader

Inspired by:

https://devops.stackexchange.com/questions/2731/downloading-docker-images-from-docker-hub-without-using-docker

and mainly 

https://gitlab.com/Jancsoj78/dockerless_docker_downloader/-/blob/master/dockerless_downloader.ps1

This reworked powershell script allows to download docker images on a windows machine without docker.\
In the original one it wasn't obvious how does one import the image.\
Upgraded script uses proper manifest schema to build manifest json and easily upload the image.\\

Images can later be transfered to the machine with docker and uploaded using following commands:

```bash
tar -cvf imagename.tar *
docker load < imagename.tar
```

Some useful info found here:

https://github.com/coollog/build-containers-the-hard-way/blob/master/README.md

In case something stops working, here's manifest schema: 

https://docs.docker.com/registry/spec/manifest-v2-2/