#!/bin/bash

# Резервное копирование каталога с виртуальными хостами

# Монтируем директорию СХД
mount  //192.168.0.212/backup/FtpCorpBackTmp  /root/ftp-back-tmp -o user=admin,password=Pass#word,rw,locale=ru_RU.UTF-8,iocharset=utf8

# Переходим в каталог с виртальными хостами
cd /var/www/vhosts/

# Получаем список директорий и создаем новый архив или обновляем существующий
ls | while read name ;
do
    tar -uvf   /root/ftp-back-tmp/"$name".tar "$name";
    
done

#cp -u -f -R  /var/www/vhosts/* /root/ftp-back-tmp

# Отмонтируем каталог 
umount /root/ftp-back-tmp

# Отправляем сообщение администратору
echo "Update backup FTP " | mutt -s "Накопительный бекап ФТП-каталога" admin@example.ru
