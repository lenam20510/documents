user=namml
pass="()90lNml"
IP="//192.168.106.19"
WORK=/root/work
# MOUNT_COM=mount.cifs
MOUNT_COM=mount

mount_fld=$WORK/workspaces
[ ! -d $mount_fld ] && mkdir -p $mount_fld
sudo $MOUNT_COM //192.168.106.9/workspaces $mount_fld -o username=$user,password="$pass",vers=3.0

mount_fld=$WORK/receive_document
[ ! -d $mount_fld ] && mkdir -p $mount_fld
sudo $MOUNT_COM //192.168.106.9/receive_document $mount_fld -o username=$user,password="$pass",vers=3.0


