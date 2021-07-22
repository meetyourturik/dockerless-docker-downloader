# dockerless-docker-downloader

Inspired by:

https://devops.stackexchange.com/questions/2731/downloading-docker-images-from-docker-hub-without-using-docker

and mainly 

https://gitlab.com/Jancsoj78/dockerless_docker_downloader/-/blob/master/dockerless_downloader.ps1

This reworked powershell script allows to download docker images on a windows machine without docker.\
In the original one it wasn't obvious how does one import the image.\
Upgraded script uses proper manifest schema to build manifest json and easily upload the image.\

Set the **$image** and **$tag** variables to the desired image name and version (for 'official' images like postgres use 'library/' prefix)\

Images can later be transfered to the machine with docker (eg using pscp) and uploaded using following commands:

```bash
tar -cvf imagename.tar *
docker load < imagename.tar
```

Some useful info found here:

https://github.com/coollog/build-containers-the-hard-way/blob/master/README.md

In case something stops working, here's manifest schema for the curious mind to try and fix it: 

https://docs.docker.com/registry/spec/manifest-v2-2/
