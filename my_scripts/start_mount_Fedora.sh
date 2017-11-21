user=namml
pass="90()lNml"
IP="//192.168.106.9"
WORK=~/work

mount_fld=$WORK/2portLAN_IMP
[ ! -d $mount_fld ] && mkdir -p $mount_fld
sudo mount.cifs //192.168.106.9/2portLAN_IMP $mount_fld -o username=$user,password="$pass"

mount_fld=$WORK/namml
[ ! -d $mount_fld ] && mkdir -p $mount_fld
sudo mount.cifs //192.168.106.9/namml $mount_fld -o username=$user,password="$pass"

