#!/usr/bin/env bash

ZIP=`which zip`
CP=`which cp`
RM=`which rm`
MYSQLDUMP=`which mysqldump`
FIND=`which find`
MKDIR=`which mkdir`
DATE=`date +%Y%m%d-%H%M-%S`
HOST="localhost"
USERDB="root"
PASSDB="SENHA"
DAYS="1"
PATHBKP="/mnt/backup"
PATHBKPFL="/mnt/backup/conffiles"
DBGRP1=("base01" "base02")
PATHGRP1=("/mnt/www/site01/BASE" "/mnt/www/site02/BASE")
# A ordem dos nomes e path para STGRP1 e PATHGRP2 devem coincidir
STGRP1=("default" "site01" "site02")
PATHGRP2=("/mnt/www/default/" "/mnt/www/site01/" "/mnt/www/site02/")
#PATHGRP3=("/root/*" "/etc/nginx/nginx.conf" "/etc/php/7.4/fpm/php.ini" "/etc/nginx/conf.d/limit_request.conf" "/etc/nginx/sites-available" "/etc/sysctl.d/local.conf" "/etc/mysql/mariadb.conf.d/50-server.cnf" "/etc/mysql/mariadb.conf.d/50-client.cnf" "/etc/mysql/mariadb.conf.d/50-mysql-clients.cnf" "/etc/haproxy/haproxy.cfg" "/etc/haproxy/certs")
PATHGRP3=("/root/*" "/etc/apache2/apache2.conf" "/etc/apache2/ports.conf" "/etc/apache2/conf-available" "/etc/apache2/sites-available" "/etc/php/7.4/apache2/php.ini" "/etc/php/7.4/fpm/php.ini" "/etc/sysctl.d/local.conf" "/etc/mysql/mariadb.conf.d/50-server.cnf" "/etc/mysql/mariadb.conf.d/50-client.cnf" "/etc/mysql/mariadb.conf.d/50-mysql-clients.cnf" "/etc/haproxy/haproxy.cfg" "/etc/haproxy/certs" "/etc/ssh/sshd_config")


echo "### REMOVENDO ARQUIVOS ANTERIORES A $DAYS DIA(S) PARA LIBERAR ESPAÇO NO DIRETORIO $PATHBKP"
$FIND $PATHBKP -mtime $DAYS -type f -delete
echo ""


echo "### BACKUP DATABASE   ################################"
CONT=0
for BASE in ${PATHGRP1[@]} ; do
   if [[ -d $BASE ]] ; then
      echo ""
      echo "### Tarefa $CONT - ############################"
      echo "Diretorio $i existente."
      cd $BASE
      echo "Removendo arquivos do diretorio $i modificado nas ultimas 24 horas."
      $FIND $BASE -mtime $DAYS -type f -delete
      echo "Iniciando backup da BASE ${DBGRP1[$CONT]} - aguarde."
      $MYSQLDUMP --opt -c -Q -x -h $HOST -u $USERDB -p$PASSDB ${DBGRP1[$CONT]} > ${DBGRP1[$CONT]}-$DATE.sql
      ((CONT=CONT+1))
   else
      echo ""
      echo "### Tarefa $CONT - ############################"
      $MKDIR -p $BASE
      echo "Diretorio $PATH criado."
      cd $BASE
      echo "Iniciando backup da BASE ${DBGRP1[$CONT]} - aguarde."
      $MYSQLDUMP --opt -c -Q -x -h $HOST -u $USER -p$PASS ${DBGRP1[$CONT]} > ${DBGRP1[$CONT]}-$DATE.sql
      ((CONT=CONT+1))
   fi
done
echo ""


echo "### DIRETORIOS   #####################################"
echo ""
if [[ -d $PATHBKP && -d $PATHBKPFL ]] ; then
   echo "Diretorio $PATHBKP existente."
   echo "Diretorio $PATHBKPFL existente."
else
   $MKDIR -p $PATHBKP $PATHBKPFL
   echo "Diretorio $PATHBKP criado."
   echo "Diretorio $PATHBKPFL criado."
fi
echo ""


### GASTOU INICALMENTE 42 min
echo "### BACKUP SITES   ###################################"
CONT=0
for SITE in ${PATHGRP2[@]} ; do
   echo ""
   echo "### Tarefa $CONT - ############################"
   echo "Iniciando backup do SITE $SITE no local $PATHBKP/${STGRP1[$CONT]}.tar.gz - aguarde."
   $ZIP -r $PATHBKP/${STGRP1[$CONT]}-$DATE.zip $SITE > /dev/null 2>&1
   ((CONT=CONT+1))
done
echo ""



echo "### BACKUP FILES #####################################"
CONT=0
for FILE in ${PATHGRP3[@]} ; do
   echo ""
   echo "### Tarefa $CONT - ############################"
   echo "Iniciando backup dos FILES $FILE para $PATHBKPFL - aguarde."
   $CP -u -r $FILE $PATHBKPFL
   ((CONT=CONT+1))
done
echo ""
$ZIP -r $PATHBKP/conffiles-$DATE.zip $PATHBKPFL > /dev/null 2>&1
$RM -rf $PATHBKPFL




### Conectar SSH e transferir
#cp dos arquivos mais novos do caminho /mnt/volume_sfo3_01/backup  para o Destino e nao sobrescrever
