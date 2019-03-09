#!/bin/bash

# Монтируем директорию
mount -t cifs //192.168.0.156/am/home/TABLET /mnt/office_share_TABLET -o user=tablet_sinc,password=Pass#word,domain=am.local,rw
# Копируем новые файлы и обновляем измененные
cp -u -f -R  /var/www/vhosts/TABLET/* /mnt/office_share_TABLET
# Отмонтируем директорию
umount /mnt/office_share_TABLET


