#!/bin/bash
apt install squashfuse -y
sudo apt install snap snapd -y
sudo snap install lxd
sudo lxd init --auto

lxc list
lxc image list