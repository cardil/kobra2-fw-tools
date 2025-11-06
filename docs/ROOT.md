# ROOT

## Via serial console shell

At the moment the only way to get root access is to use the serial console.

Complete the [UART guide](UART.md) to get yourself in the u-boot environment.

1. Enter these commands to change bootargs:
   ```shell
   setenv init /bin/sh
   saveenv
   bootd
   ```
   Now you have a interim root shell.
2. Now you need to override the root password. To do this, you need to mount the overlay partition:
   ```shell
   mount -t proc p /proc
   . /lib/functions/preinit.sh
   . /lib/preinit/80_mount_root
   do_mount_root
   . /etc/init.d/boot
   link_by_name
   . /lib/preinit/81_initramfs_config
   do_initramfs_config
   ```
3. Then you can override the root password:
   ```
   cp /etc/shadow /overlay/upper/etc/shadow
   vi /overlay/upper/etc/shadow
   ```
   Just replace the password hash with something. You can use [this website](https://unix4lyfe.org/crypt/) to generate a password hash or just use `$1$///xTLYF$krWXTe62/dm.crd6CH4HW0` as password (this is `toor` password used in this guide). Later on you can change it to something more secure.
4. After that is done, you need to reboot into U-Boot again and change the bootargs back to normal:
   ```shell
   setenv init /sbin/init
   setenv bootdelay 3
   saveenv
   reset
   ```
   > [!NOTE]
   > We are extending the boot delay to 3 seconds to make it easier to interupt the u-boot.

That's it! You now have root access.

## SSH access

For permanent ssh access, you can do the following (thanks [rol](https://klipper.discourse.group/u/rol) for the commands):

```shell
wget http://bin.entware.net/armv7sf-k3.2/installer/generic.sh
chmod 755 generic.sh
./generic.sh
sed -i '$i\/opt/etc/init.d/rc.unslung start' /etc/rc.local
echo 'export PATH="$PATH:/opt/sbin:/opt/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"' >> /etc/profile
reboot

opkg update
opkg install dropbear
reboot
```
> [!WARNING]
> After you flash the printer with diffrent firmware you will need to repeat this process, as the rootfs partition will be overwritten. Unless, you'll flash with custom firmware built with this repo.

## Custom firmware

In order to be able to flash custom firmware, you'll need to replace the `swupdate` certs on the printer. Otherwise the firmware update will hang.

Replace the `/etc/swupdate_public.pem` in the printer with the one from the `RESOURCES` directory or create your own. Make sure to copy the original `/etc/swupdate_public.pem` key in case you want to return to the original Anycubic updates.
