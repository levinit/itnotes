#!/usr/bin/sh
user=
password=
database=
table='*'
path=~/backup
prefix=
timestamp=$(date +%F)
num=7

[[ -d $path ]] mkdir -p $path

mysqldump -u$user -p$password $database --skip-lock-tables | xz > $path/$prefix-$timestamp.sql.xz

cd $path

find . -name '*.sql.xz' -mtime $num -exec rm {} \;

#restore
#xz -d xx.xz
#mysql -uuser -ppassword < xxx.sql