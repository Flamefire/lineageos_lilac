## Dumping stock firmware

Based on https://forum.xda-developers.com/t/dumping-stock-firmware-to-use-for-lineage-custom-build.4034621 by dcrin/derfelot

Find AIK-Linux in the dev sections on xda containing `unsin` and `unpackimg`.

Three .sin files from stock are needed: vendor, kernel, system.
Extract them with `unsin`.

You will end up with one .img file and two .ext4 files.

- `kernel_X-FLASH-ALL-C93B.img`
- `system_X-FLASH-ALL-C93B.ext4`
- `vendor_X-FLASH-ALL-C93B.ext4

Unpack the kernel with: `./unpackimg.sh kernel_X-FLASH-ALL-C93B.img`

Own your files: `sudo chown -R $USER:$USER ramdisk/`

Note that the `ramdisk` folder will be in the same folder as `unpackimg.sh` independent from where you called that script from!

Mount the ext4 images:

- `sudo mkdir /mnt/system && sudo mount -o loop system_X-FLASH-ALL-C93B.ext4 /mnt/system`
- `sudo mkdir /mnt/vendor && sudo mount -o loop vendor-FLASH-ALL-C93B.ext4 /mnt/vendor`

The kernel copy you did previously gave you an empty `system` and `vendor` folder.
Copy all contents of the mounts into those empty folders.

Finally rename `ramdisk` to something more appropriate and use it with `./extract-files.sh /location of extracted contents`.

