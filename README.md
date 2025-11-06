# Anycubic Kobra 2 Series Tools

This repository contains tools for the Anycubic Kobra 2 Series 3D printers.

> [!WARNING]
> This repository is only partially maintained. I'm not the original author, just some user that tries to keep it alive.

## Documentation

Documentation can be found in the `docs` directory.

- [UART.md](docs/UART.md) - How to connect to the UART serial console.
- [ROOT.md](docs/ROOT.md) - How to root the printer.
- [EMMC_BACKUP.md](docs/EMMC_BACKUP.md) - How to backup the EMMC.
- [EMMC_RESTORE.md](docs/EMMC_RESTORE.md) - How to restore the EMMC.
- [OPTIONS.md](docs/OPTIONS.md) - Options for the firmware.
- [GCODE_COMMANDS.md](docs/GCODE_COMMANDS.md) - GCODE commands.
- [MQTT_API.md](docs/MQTT_API.md) - MQTT API.
- [COMMANDS.md](docs/COMMANDS.md) - Useful commands.
- [PRINTER_CFG.md](docs/PRINTER_CFG.md) - Printer.cfg things.
- [ENTER_FEL_MODE.md](docs/ENTER_FEL_MODE.md) - How to enter FEL mode.
- [DOWNLOAD_SDK.md](docs/DOWNLOAD_SDK.md) - How to download the SDK.
- [OLD_INFO.md](docs/OLD_INFO.md) - Old information.
- [CREDITS.md](docs/CREDITS.md) - Credits.
- [LINKS.md](docs/LINKS.md) - Useful things/addons for the printer.
- [VERSIONS.md](docs/VERSIONS.md) - Known firmware versions.

## Discussion

- [Telegram Group](https://t.me/kobra2modding)
- [Link (klipper.discourse.group)](https://klipper.discourse.group/t/printer-cfg-for-anycubic-kobra-2-plus-pro-max/11658)

## Usage

> [!IMPORTANT]
> Please backup all files in `/user` so you don't lose access to anycubic cloud and OTA updates. You can use the [EMMC_BACKUP.md](docs/EMMC_BACKUP.md) guide to backup the whole system. But backing up `/user` is enough to keep access to anycubic cloud and OTA updates.
>
> You could use `dd` command to backup also.

> [!WARNING] > **IF YOU DO NOT BACKUP OR DELETE THE FILES IN `/user` YOU WILL LOSE ACCESS TO ANYCUBIC CLOUD AND OTA UPDATES. YOU HAVE BEEN WARNED.**
>
> Everything you do is on **your** own risk. I am **not** responsible for any damage you do to your printer.

1. Clone the repository.

2. Place the `.bin .zip .swu` firmware files in the `FW` directory.

> [!TIP]
> If you don't have firmware files, you can use the script `fwdl.sh <model> <version>` to download in the folder `FW` the version for the printer model you need. The supported models are `K2Pro`, `K2Plus` and `K2Max`. The version is given in the format `X.Y.Z` like `3.0.9`.

3. Run `unpack.sh <update_file>` to unpack the selected firmware update file.

The supported file extensions are `bin`, `zip` and `swu`. The result is in the folder `unpacked`.

4. Modify the options file `options.cfg`.

To select the options you need and run `patch.sh` to patch the firmware files in the `unpacked` folder.

The result is still in the folder `unpacked`. You may manually modify the current state of the files if needed. You can also prepare different configuration files for different needs based on the default file `options.cfg`. The custom configuration file is provided as parameter: `patch.sh <custom_configuration_file>`. If no parameter is provided, the file `options.cfg` will be used.

5. Run `pack.sh` to pack the firmware files from the folder `unpacked`.

The result is the file `update/update.swu`.

At the end, if you selected `ssh` and `root_access` with a password, you will be asked if you want to upload the update automatically through ssh. If your printer has already a custom update (with ssh and root password) you can type `y` and press `enter`. The update will be transferred to the printer, executed and the printer will reboot. Otherwise, press enter to exit and follow the next step for USB update.

6. If your printer is still with the original firmware, you have to make root access first.

Follow the [ROOT guide](docs/ROOT.md).

Then apply the newly generated custom software `update/update.swu` by USB update (place the file `update.swu` in the folder `update` on the root of a FAT32 formatted USB disk). If your printer already has custom update installed, then you can directly apply the new update by USB update.

To do all this a little easier you can just use `build.sh` and it will run all the steps for you.

> [!WARNING]
> This repository is a work in progress and may contain bugs or may not work as expected any pull requests are welcome.

> [!NOTE]
> Default password for the root access (custom firmware with UART and SSH) is `toor` but it can be changed in the `options.cfg` file.

> [!IMPORTANT]
> Use only FAT32 formatted USB disk and place the file `update.swu` inside a folder `update` created at the root of the USB disk. You don't have to have a 4 GB usb. It can be 64 or 128 GB or more. You only need to format 1 partition to max 4 GB. Then FAT32 will be available.

## Advanced usage

Partition map of the printer:

![Partition map](./docs/images/partition.jpg)

## Repo layout

- **FW** - Place `.bin`, `.zip` or `.swu` firmware files here.
- **RESOURCES** - Contains resources for the firmware options.
- **TOOLS** - Contains tools to decrypt and encrypt firmware files and more.
- **unpacked** - Contains the unpacked firmware files.
- **update** - Contains the packed firmware files.
