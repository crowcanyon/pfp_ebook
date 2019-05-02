#!/bin/bash
## Deploy

mkdir ~/institute/
mount_smbfs //$1:$2@www/institute/ ~/institute/
rsync -rv --size-only --delete ./docs/ ~/institute/pfp/
umount ~/institute/
rm -r ~/institute/
