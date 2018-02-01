# Mining OS openstack-diskimage-builder
Dynamically generates USB disk images for mining crypto currencies using docker.


## Execution Example

The following will create an image files `image.raw` that can be used to burn to a USB flash drive for booting a mining rig. The operating system 
* contains drivers for ROCm
* Based on ubuntu xenial
* includes miners
    * claymore
    * ethminer
    * sgminer
    * cgminer

```bash
docker run --privileged -v $PWD:/work r351574nc3/amdgpu-diskimage-builder:latest ubuntu-minimal devuser driver-rocm miners bootloader
```