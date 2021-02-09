[English](README.md) | 简体中文

## 关于工具

Meteorite 是一个（暂时仅）针对 CentOS-7 的运维工具箱（CentOS-8 将于 2021 年底停止维护，所以不支持该版本），主要功能是快速部署 LNMP（PHP、MariaDB、OpenResty）生产环境。

## 下载工具

你可以通过克隆仓库的方式下载：

```sh
git clone https://gitee.com/vtrois/meteorite.git
```

**提示**：Gitee 与 GitHub 内容同步会有一个小时的延迟。

## 使用说明

### 交互安装

```sh
bash meteorite.sh
```

**提示**：交互安装方式根据提示选择需要安装的产品。工具类脚本不会在此体现，需要带参数执行脚本。

### 自动安装

```sh
bash meteorite.sh --auto
```

**提示**：自动安装包含系统加固和优化以及 PHP、MariaDB、OpenResty、Redis 和 Memcached，但不包括内核升级，如果需要升级内核，需要先带参数执行脚本。

### 升级内核工具

```sh
bash meteorite.sh --upgrade_kernel
```

**提示**：将自动升级最新的稳定版内核，如需修改内核版本，请先修改 options.conf 配置文件。

### 硬盘挂载工具

```sh
bash meteorite.sh --auto_fdisk
```

**提示**：腾讯云服务器将使用弹性云硬盘的软链接方式挂载。

### 信息展示工具

```sh
bash meteorite.sh --system_info
```

**提示**：腾讯云服务器将额外显示 UUID、实例 ID、实例名称、可用区、计费类型、创建时间、到期时间等信息。

### NTP 服务器工具

```sh
bash meteorite.sh --ntp_service
```

更多工具说明，请使用 `-h` 参数进行查询。

## 版权说明

该仓库代码文件使用 [MIT](https://github.com/vtrois/meteorite/blob/main/LICENSE) 协议进行授权。