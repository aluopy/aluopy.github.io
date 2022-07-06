---
title: "Linux 合并两块磁盘 (>2TB) 并挂载到同一目录"
permalink: /linux/merge-disks/
toc: true
categories: linux
tags:
  - lvm
  - pv
  - vg
  - lv
---

本文总体解决方案：

- 对第一块磁盘设备进行分区（`parted`）
- 基于第一块磁盘得到的分区创建 PV（***PV Name***：`/dev/sdb1`）
- 创建 VG 来管理刚刚创建的 PV（***VG Name***：`vgdata`）
- 基于创建的 VG 创建 LV（***LV Name***：`lvData`）
- LV 的格式化及挂载（设置开机自动挂载）（***LV Name***：`lvData`）
- 对第二块磁盘设备进行分区（`parted`）
- 基于第二块磁盘得到的分区创建 PV（***PV Name***：`/dev/sdc1`）
- VG 卷组扩容 - 第二块磁盘创建的 PV 加入到之前创建的 VG（***PV Name***：`/dev/sdc1`，***VG Name***：`vgdata`）
- 扩展 LV 逻辑卷（***LV Name***：`lvData`）
- 更新 LV（命令：`resize2fs /dev/vgdata/lvData`，***/dev/vgdata/lvData*** 为 LV Path）

## 1、前置知识

### 1.1、相关概念

#### LVM

**Logical Volume Manager - 逻辑盘卷管理**

Linux环境下对磁盘分区进行管理的一种机制，LVM是建立在硬盘和分区之上的一个逻辑层，来提高磁盘分区管理的灵活性。

LVM的工作原理其实很简单，它就是通过将底层的物理硬盘抽象的封装起来，然后以逻辑卷的方式呈现给上层应用。在传统的磁盘管理机制中，我们的上层应用是直接访问文件系统，从而对底层的物理硬盘进行读取，而在LVM中，其通过对底层的硬盘进行封装，当我们对底层的物理硬盘进行操作时，其不再是针对于分区进行操作，而是通过一个叫做逻辑卷的东西来对其进行底层的磁盘管理操作。比如说我增加一个物理硬盘，这个时候上层的服务是感觉不到的，因为呈现给上层服务的是以逻辑卷的方式。

LVM最大的特点就是可以对磁盘进行动态管理。因为逻辑卷的大小是可以动态调整的，而且不会丢失现有的数据。如果我们新增加了硬盘，其也不会改变现有上层的逻辑卷。作为一个动态磁盘管理机制，逻辑卷技术大大提高了磁盘管理的灵活性。

#### PV

**Physical Volume - 物理卷**

物理卷在逻辑卷管理中处于最底层，它可以是实际物理硬盘上的分区，也可以是整个物理硬盘，也可以是raid设备。

#### VG

**Volumne Group - 卷组**

卷组建立在物理卷之上，一个卷组中至少要包括一个物理卷，在卷组建立之后可动态添加物理卷到卷组中。一个逻辑卷管理系统工程中可以只有一个卷组，也可以拥有多个卷组。

#### LV

**Logical Volume - 逻辑卷**

逻辑卷建立在卷组之上，卷组中的未分配空间可以用于建立新的逻辑卷，逻辑卷建立后可以动态地扩展和缩小空间。系统中的多个逻辑卷可以属于同一个卷组，也可以属于不同的多个卷组。

### 1.2、常用的LVM命令：

| 功能/命令 | 物理卷管理  | 卷组管理    | 逻辑卷管理  |
| :-------- | :---------- | :---------- | :---------- |
| 扫描      | `pvscan`    | `vgscan`    | `lvscan`    |
| 建立      | `pvcreate`  | `vgcreate`  | `lvcreate`  |
| 显示      | `pvdisplay` | `vgdisplay` | `lvdisplay` |
| 删除      | `pvremove`  | `vgremove`  | `lvremove`  |
| 扩展      |             | `vgextend`  | `lvextend`  |
| 缩小      |             | `vgreduce`  | `lvreduce`  |

## 2、使用 parted 方式格式化磁盘并且创建 LVM

### 2.1、查看磁盘信息

```shell
$ sudo fdisk -l
... ...
磁盘 /dev/sdb：2254.9 GB, 2254857830400 字节，4404019200 个扇区
Units = 扇区 of 1 * 512 = 512 bytes
扇区大小(逻辑/物理)：512 字节 / 512 字节
I/O 大小(最小/最佳)：512 字节 / 512 字节


磁盘 /dev/sdc：2254.9 GB, 2254857830400 字节，4404019200 个扇区
Units = 扇区 of 1 * 512 = 512 bytes
扇区大小(逻辑/物理)：512 字节 / 512 字节
I/O 大小(最小/最佳)：512 字节 / 512 字节
... ...
```

### 2.2、创建分区

我这里有 2 块 2254.9GB 的磁盘待格式化到一个分区，先格式化磁盘 `/dev/sdb `

```shell
# 使用 parted 开始分区
$ sudo parted /dev/sdb
GNU Parted 3.1
使用 /dev/sdb
Welcome to GNU Parted! Type 'help' to view a list of commands.
# 运行命令：mklabel gpt，将 MBR 分区形式转为 GPT 分区形式
(parted) mklabel gpt
# 运行命令：mkpart primary ext4，划分一个采用 ext4 文件系统的主分区，并设置分区的开始位置和结束位置。
# 如果一个数据盘只分一个分区，则运行命令：mkpart primary ext4 0 -1
(parted) mkpart primary ext4 0 -1                                         
警告: The resulting partition is not properly aligned for best performance.
# 输入 i 忽略
忽略/Ignore/放弃/Cancel? i
# 打印分区信息
(parted) print                                                            
Model: VMware Virtual disk (scsi)
Disk /dev/sdb: 2255GB
Sector size (logical/physical): 512B/512B
Partition Table: gpt
Disk Flags: 

Number  Start   End     Size    File system  Name     标志
 1      17.4kB  2255GB  2255GB               primary

# 使用 toggle 更改硬盘类型
(parted) toggle 1 lvm       
# 运行命令：quit，退出 parted 操作
(parted) quit                                                             
信息: You may need to update /etc/fstab.
# 运行命令 partprobe，使系统重读分区表
$ partprobe
```

### 2.3、创建 PV

将一块普通磁盘改变成 LVM 里最基本物理磁盘。

```shell
# 查看磁盘信息
$ sudo fdisk -l
... ...
磁盘 /dev/sdb：2254.9 GB, 2254857830400 字节，4404019200 个扇区
Units = 扇区 of 1 * 512 = 512 bytes
扇区大小(逻辑/物理)：512 字节 / 512 字节
I/O 大小(最小/最佳)：512 字节 / 512 字节
磁盘标签类型：gpt
Disk identifier: E3A150FE-5567-4E47-83B4-CA1CA725CD86


#         Start          End    Size  Type            Name
 1           34   4404017247    2.1T  Linux LVM       primary

磁盘 /dev/sdc：2254.9 GB, 2254857830400 字节，4404019200 个扇区
Units = 扇区 of 1 * 512 = 512 bytes
扇区大小(逻辑/物理)：512 字节 / 512 字节
I/O 大小(最小/最佳)：512 字节 / 512 字节
... ...

# 创建 PV
$ sudo pvcreate /dev/sdb1
  Physical volume "/dev/sdb1" successfully created.
  
# 扫描 PV
$ sudo pvscan
  ... ...
  PV /dev/sdb1                      lvm2 [2.05 TiB]
  ... ...
  
# 显示 PV 信息
$ sudo pvdisplay
  --- Physical volume ---
  ... ...
  
  "/dev/sdb1" is a new physical volume of "2.05 TiB"
  --- NEW Physical volume ---
  PV Name               /dev/sdb1
  VG Name               
  PV Size               2.05 TiB
  Allocatable           NO
  PE Size               0   
  Total PE              0
  Free PE               0
  Allocated PE          0
  PV UUID               zIU3UV-r5WN-9EFf-Ld4Q-Fpuu-9MC4-LsLwDS
```

### 2.4、创建 VG

创建 VG（卷组），来管理 PV 。

```shell
# 创建名为 vgdata 的 VG，并将 /dev/sdb1 加入
# -s 是指定 PE 大小，默认是 4M
# $ vgcreate vgdata /dev/sdb1 -s 8M
$ sudo vgcreate vgdata /dev/sdb1
  Volume group "vgdata" successfully created
  
# 显示 VG 信息
$ sudo vgdisplay
  --- Volume group ---
  ... ...
   
  --- Volume group ---
  VG Name               vgdata
  System ID             
  Format                lvm2
  Metadata Areas        1
  Metadata Sequence No  1
  VG Access             read/write
  VG Status             resizable
  MAX LV                0
  Cur LV                0
  Open LV               0
  Max PV                0
  Cur PV                1
  Act PV                1
  VG Size               2.05 TiB
  PE Size               4.00 MiB
  Total PE              537599
  Alloc PE / Size       0 / 0   
  Free  PE / Size       537599 / 2.05 TiB
  VG UUID               59GTm3-4aPI-hepU-luxk-q7M7-JxFb-Olg5P2
  
# 扫描 VG
$ sudo vgscan
  Reading volume groups from cache.
  ... ...
  Found volume group "vgdata" using metadata type lvm2
```

### 2.5、创建 LV

有了卷组我们就可以创建 LV , LV 是我们真正用来写数据的，比如新建一个文本等。

```shell
# 创建 LV，-L 指定 LV 大小为 2099G，-n LV名字方便区分，vgdata 加入到 vgdata 组，上面创建的。
# 这里需要注意，在实际执行中，磁盘大小可能会有出入，这里根据实际情况稍作调整即可。
# VG Size：2.05 TiB ===> LV：2.05 * 1024 = 2099.2 G
$ sudo lvcreate -L 2099G -n lvData vgdata
  Logical volume "lvData" created.

# 显示 LV 信息
$ sudo lvdisplay
  ... ...
   
  --- Logical volume ---
  LV Path                /dev/vgdata/lvData
  LV Name                lvData
  VG Name                vgdata
  LV UUID                zY4G0H-3YyU-YlCe-IFGO-vTZg-ShDN-n4VROg
  LV Write Access        read/write
  LV Creation host, time localhost.localdomain, 2021-09-26 11:15:38 +0800
  LV Status              available
  # open                 0
  LV Size                <2.05 TiB
  Current LE             537344
  Segments               1
  Allocation             inherit
  Read ahead sectors     auto
  - currently set to     8192
  Block device           253:3
```

### 2.6、格式化 LV 及挂载

```shell
# 格式化 lvData 为 ext4 格式
$ sudo mkfs.ext4 /dev/vgdata/lvData
mke2fs 1.42.9 (28-Dec-2013)
文件系统标签=
OS type: Linux
块大小=4096 (log=2)
分块大小=4096 (log=2)
Stride=0 blocks, Stripe width=0 blocks
137560064 inodes, 550240256 blocks
27512012 blocks (5.00%) reserved for the super user
第一个数据块=0
Maximum filesystem blocks=2699034624
16792 block groups
32768 blocks per group, 32768 fragments per group
8192 inodes per group
Superblock backups stored on blocks: 
	32768, 98304, 163840, 229376, 294912, 819200, 884736, 1605632, 2654208, 
	4096000, 7962624, 11239424, 20480000, 23887872, 71663616, 78675968, 
	102400000, 214990848, 512000000

Allocating group tables: 完成                            
正在写入inode表: 完成                            
Creating journal (32768 blocks): 完成
Writing superblocks and filesystem accounting information: 完成

# 创建挂载点 /pdf
$ sudo mkdir /pdf

# 挂载到 /pdf 目录下
$ sudo mount /dev/vgdata/lvData /pdf

# 查看是否挂载成功
$ sudo df -h
文件系统                     容量   已用  可用  已用% 挂载点
devtmpfs                   7.8G     0  7.8G    0% /dev
tmpfs                      7.8G     0  7.8G    0% /dev/shm
tmpfs                      7.8G  8.6M  7.8G    1% /run
tmpfs                      7.8G     0  7.8G    0% /sys/fs/cgroup
/dev/mapper/cl-root         50G  3.5G   47G    8% /
/dev/sda1                 1014M  139M  876M   14% /boot
/dev/mapper/cl-home        142G   33M  142G    1% /home
tmpfs                      1.6G     0  1.6G    0% /run/user/0
/dev/mapper/vgdata-lvData  2.1T   81M  2.0T    1% /pdf
```

### 2.7、开机自动挂载

```shell
$ sudo echo "/dev/vgdata/lvData /pdf ext4 defaults 0 0" >> /etc/fstab
```

## 3、两块磁盘挂载指向一个文件夹 LVM

### 3.1、扩展 VG 卷组

刚才我们已经把磁盘 `/dev/sdb` 格式化了，现在我们需要格式化磁盘 `/dev/sdc` 。前面的操作和上面一样，先使用 parted 方式格式化磁盘并且创建 LVM 。

```shell
# 使用 parted 开始分区
$ sudo parted /dev/sdc
GNU Parted 3.1
使用 /dev/sdc
Welcome to GNU Parted! Type 'help' to view a list of commands.
(parted) mklabel gpt                                                      
(parted) mkpart primary ext4 0 -1                                         
警告: The resulting partition is not properly aligned for best performance.
忽略/Ignore/放弃/Cancel? i                                                
(parted) toggle 1 lvm                                                     
(parted) quit                                                             
信息: You may need to update /etc/fstab.

# 运行命令 partprobe，使系统重读分区表
$ sudo partprobe

# 普通磁盘转换成 PV
$ sudo pvcreate /dev/sdc1
  Physical volume "/dev/sdc1" successfully created.
  
# 查看 VG 组信息
$ sudo pvs
  PV         VG     Fmt  Attr PSize    PFree   
  ... ...
  /dev/sdb1  vgdata lvm2 a--     2.05t 1020.00m
  /dev/sdc1         lvm2 ---     2.05t    2.05t
  
# 加入 VG 组，vgdata 要加入 VG 组名，/dev/sdc1 新 PV
$ sudo vgextend vgdata /dev/sdc1
  Volume group "vgdata" successfully extended
  
# 查看 VG 卷组详细信息
$ sudo vgdisplay
  --- Volume group ---
  ... ...
   
  --- Volume group ---
  VG Name               vgdata
  System ID             
  Format                lvm2
  Metadata Areas        2
  Metadata Sequence No  3
  VG Access             read/write
  VG Status             resizable
  MAX LV                0
  Cur LV                1
  Open LV               1
  Max PV                0
  Cur PV                2
  Act PV                2
  VG Size               4.10 TiB
  PE Size               4.00 MiB
  Total PE              1075198
  Alloc PE / Size       537344 / <2.05 TiB
  Free  PE / Size       537854 / 2.05 TiB
  VG UUID               59GTm3-4aPI-hepU-luxk-q7M7-JxFb-Olg5P2
```

### 3.2、扩展 LV 逻辑卷

```shell
# 缩小LV：lvextend --size +1781G /dev/vgdata/lvData
$ sudo lvextend -L +2099G /dev/vgdata/lvData
  Size of logical volume vgdata/lvData changed from <2.05 TiB (537344 extents) to <4.10 TiB (1074688 extents).
  Logical volume vgdata/lvData successfully resized.

# LV 扩容完系统还没有识别，需要用 resize2fs 来更新，系统才能识别到
$ sudo resize2fs /dev/vgdata/lvData
resize2fs 1.42.9 (28-Dec-2013)
Filesystem at /dev/vgdata/lvData is mounted on /pdf; on-line resizing required
old_desc_blocks = 263, new_desc_blocks = 525
The filesystem on /dev/vgdata/lvData is now 1100480512 blocks long.

$ sudo df -h
文件系统                     容量   已用  可用  已用% 挂载点
devtmpfs                   7.8G     0  7.8G    0% /dev
tmpfs                      7.8G     0  7.8G    0% /dev/shm
tmpfs                      7.8G  8.6M  7.8G    1% /run
tmpfs                      7.8G     0  7.8G    0% /sys/fs/cgroup
/dev/mapper/cl-root         50G  3.5G   47G    7% /
/dev/sda1                 1014M  139M  876M   14% /boot
/dev/mapper/cl-home        142G   33M  142G    1% /home
tmpfs                      1.6G     0  1.6G    0% /run/user/0
/dev/mapper/vgdata-lvData  4.1T   66M  3.9T    1% /pdf
```

至此合并两块大于2T的磁盘到一个分区的操作已经完成，同理可以合并多块磁盘设备。