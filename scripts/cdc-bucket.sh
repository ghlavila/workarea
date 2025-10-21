#!/bin/bash

if [ "$1" = "" ]
then
    echo "Must provide client ID as argument (e.g., aig)"
    exit 1
fi

# check to see if installed if not then install it
rpm -qa | grep mount-s3 || sudo yum -y install /data/packages/mount-s3.rpm
mount-s3 --version

if [ "$?" -ne 0 ]
then
    echo "exiting with error"
    exit 1
fi

# create fuse.conf if it doesn't exist
[ -f /etc/fuse.conf ] || sudo touch /etc/fuse.conf
# make fuse.conf writable
sudo chmod 777 /etc/fuse.conf
# if commented user_allow_other exists, uncomment it
if grep -q "^# *user_allow_other\s*$" /etc/fuse.conf; then
    sed 's/^# *user_allow_other/user_allow_other/' /etc/fuse.conf > /tmp/fuse.conf.tmp
    sudo mv /tmp/fuse.conf.tmp /etc/fuse.conf
# if user_allow_other doesn't exist at all, add it
elif ! grep -q "user_allow_other" /etc/fuse.conf; then
    echo "user_allow_other" >> /etc/fuse.conf
fi


# construct bucket name from client ID
client_id=$1
bucket="gh-prod-cdc-${client_id}"
mounted_bucket="gh_prod_cdc_${client_id}"


# mount bucket if not already mounted
if mountpoint -q /$mounted_bucket; then
  echo -e "\n#############\n  /$mounted_bucket already mounted\n#############"
  df -ah /$mounted_bucket
else
  if [ -d /$mounted_bucket ]; then
      echo -e "/mounted_bucket directory exists"
     sudo chown $USER:$USER /$mounted_bucket
  else
     sudo mkdir /$mounted_bucket
     sudo chown $USER:$USER /$mounted_bucket
  fi
  echo -e "\n#############\n  Mounting /$mounted_bucket\n#############\n"
  mount-s3 $bucket /$mounted_bucket --log-directory /data/s3logs --allow-other --allow-overwrite --allow-delete --part-size 100000000 --gid 10 --dir-mode 770 --file-mode 770
fi

echo done mounting $mounted_bucket

