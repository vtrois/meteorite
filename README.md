## About

Meteorite tool is an operations and maintenance toolkit for CentOS 7 (CentOS 8 will be out of maintenance by the end of 2021, so it will not be supported and optimized for that version), with the main function of quickly deploying LNMP (PHP, MariaDB, OpenResty) production environments.

## Download

You can just clone the repository:

```sh
git clone https://github.com/vtrois/meteorite.git
```

## Using

### Interactive installation

```sh
bash meteorite.sh
```

**Notice**: Follow the prompts to select and install, kernel upgrade not included.

### Automatic installation

```sh
bash meteorite.sh --auto
```

**Notice**: Including system hardening and optimization. but does not include kernel upgrade, if you need to upgrade the kernel, you need to run it before running the automatic installation script.

### Upgrade Kernel

```sh
bash meteorite.sh --install_kernel
```

### Auto fdisk tool

```sh
bash meteorite.sh -f
```

### System info tool

```sh
bash meteorite.sh -i
```

For more parameters, please use the `-h` parameter to query.

## License

The code is available under the [MIT](https://github.com/vtrois/meteorite/blob/main/LICENSE) license.