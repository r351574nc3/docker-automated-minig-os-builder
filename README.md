# docker-kickstart
Fedora/RHEL kickstart docker image for creating livecd images with docker


## Execution Example
```
docker run --rm -v $PWD/conf:/kickstarts --privileged=true r351574nc3/docker-kickstart:latest livecd-tools.ks
```

* `--privileged=true` is important because it allows docker to communicate with a loopback device which `livecd-tools` needs in order to create the ISO image.