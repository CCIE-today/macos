#!/bin/bash

# 禁用独立显卡
# 2 表示自动

# -b battery 为电池模式, 0 表示用核显
sudo pmset -b GPUSwitch 0

# -c charger 为电源模式，1 表示用独显
sudo pmset -c GPUSwitch 1