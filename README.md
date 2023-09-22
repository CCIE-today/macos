# macOS

#### 介绍
操作系统常用配置  

#### 架构
<img src="https://gitee.com/suzhen99/macos/raw/master/about.png" width="100%">

- USB: Apple T2 总线  
- 以太网：Apple T2 Controller  
- 图型卡：AMD Radeon Pro 5500M, Intel UHD Graphics 630  
- 摄像头：UVC Camera VendorID_1452  
- 蓝牙：BCM_4364B3


#### 说明

1.  <strong>kvm_efi_patch.sh</strong>  
    VMware 嵌套虚拟化补丁  
    默认支持嵌套虚拟化，条件是 VMware 中的 KVM 需要`EFI`

2.  <strong>macOS.sh</strong>  
    常用环境配置

3.  <strong>xattr-d-patch.sh</strong>  
    删除可执行文件属性

4.  <strong>oc_update.md</strong>  
    更新台面式机 oc 版本

5. <strong>mbp-driver.sh</strong>  
    MBP+RHEL8.0