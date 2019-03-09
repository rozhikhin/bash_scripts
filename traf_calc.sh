#!/bin/sh
#
#    traf_calc - logger of iptable's statistic
#
# Путь к iptables
IPTABLES="/sbin/iptables"
# Путь к логам
F_PATH="/var/log/iptables"
#Файл, в который сбрасываются значения счетчиков в течении дня
F_BEGIN_TRAF="$F_PATH/begin.traf"
##Файл, в который сбрасываются значения счетчиков для отчета в течении дня
F_TRAF="$F_PATH/"`date +"%Y%m%d"`".traf"
#Файл, в который сбрасываются значения счетчиков в конце дня
F_MONTH_TRAF="$F_PATH/month.traf"
#Файл, в который сбрасываются суммарные значения счетчиков в течении месяца
F_TRAF_MONTH_REPORT="$F_PATH/"`date +"%Y%m"`".traf"
#Файл с названиями цепочек пользователей, работающих в обход прокси
F_CHAIN="/root/traf_count/var_file"
#Файл, с параметрами пользователей, работающих в обход проксид, ля контроля превышения установленных лимитов
F_BLOCK="/root/traf_count/no_proxy_limit"
#Почта администратора
ADMIN_MAIL="admin@example.ru"
#Адрес почтового сервера
MAIL_ADDR="111.222.111.222"

day_traf()
    {
    i=0
    while read line
    do
	i=`expr ${i} + 1`
	area[$i]=$line

	TR_DAY_FROM_FILE=`cat /var/log/iptables/begin.traf | grep ${area[$i]} | head -c 18`
	TR_DAY_FROM_IPTAB=`$IPTABLES  -L ${area[$i]} -v -x | grep RETURN | head -c 18 | tail -c 9`
	TR_CURRENT_DAY=`expr ${TR_DAY_FROM_FILE} + ${TR_DAY_FROM_IPTAB}`
	ARRAY_CUR_DAY[$i]=$TR_CURRENT_DAY
	
    done < $F_CHAIN
    
    j=0
    while read line
    do
	j=`expr ${j} + 1`
	area[$j]=$line
	if [ "$j" -eq 1 ]; then
	    echo "${ARRAY_CUR_DAY[$j]}                                     ${area[$j]}" > $F_BEGIN_TRAF
	else
	    echo "${ARRAY_CUR_DAY[$j]}                                     ${area[$j]}" >> $F_BEGIN_TRAF
	fi
	                                                                        
    done < $F_CHAIN
    $IPTABLES -Z
    
    }
    
day_report()
    {
        echo "" >> $F_TRAF
        echo `date +"%d/%m/%Y  %T"`"        Учет трафика почтового сервера" >> $F_TRAF
        echo "Трафик (байт)         Трафик (МБ)             Цепочка" >> $F_TRAF
        echo "--------------------------------------------------------------------------------------------" >> $F_TRAF
    
    i=0                    
    while read line
    do
	i=`expr ${i} + 1`
	area[$i]=$line
	
	TR_DAY_FROM_FILE=`cat /var/log/iptables/begin.traf | grep ${area[$i]} | head -c 18`    
	TR_DAY_MB=`expr ${TR_DAY_FROM_FILE} / 1000000`
	echo "$TR_DAY_FROM_FILE          $TR_DAY_MB MB      ${area[$i]}" >> $F_TRAF

    done < $F_CHAIN
    cat $F_TRAF | mutt  -s “GW_Traffic” $ADMIN_MAIL

    }
    
month_traf()
    {
    
    i=0                    
    while read line
    do
    	i=`expr ${i} + 1`
	area[$i]=$line

	TR_DAY_FILE=`cat /var/log/iptables/begin.traf | grep ${area[$i]} | head -c 18`
	TR_MONTH_FILE=`cat /var/log/iptables/month.traf | grep ${area[$i]} | head -c 18	`
	TR_CURRENT_MONTH=`expr ${TR_DAY_FILE} + ${TR_MONTH_FILE} + 0`
	ARRAY_CUR_MONTH[$i]=$TR_CURRENT_MONTH
    
    done < $F_CHAIN

    k=0
    while read line
    do
	k=`expr ${k} + 1`
	area[$k]=$line
    	if [ "$k" -eq 1 ]; then
	    echo "${ARRAY_CUR_MONTH[$k]}                                     ${area[$k]}" > $F_MONTH_TRAF
	else
	    echo "${ARRAY_CUR_MONTH[$k]}                                     ${area[$k]}" >> $F_MONTH_TRAF
	    
	fi
	
    done < $F_CHAIN
    
    }
    
month_traf_report()
    {
        echo " " > $F_TRAF_MONTH_REPORT
        echo `date +"%d/%m/%Y  %T"`"        Суммарный учет трафика шлюза" >> $F_TRAF_MONTH_REPORT
        echo "Трафик (байт)         Трафик (МБ)             Цепочка" >> $F_TRAF_MONTH_REPORT
        echo "--------------------------------------------------------------------------------------------" >> $F_TRAF_MONTH_REPORT
    
	i=0                    
        while read line
        do
	i=`expr ${i} + 1`
	area[$i]=$line
    
	TR_MONTH_FROM_FILE=`cat /var/log/iptables/month.traf | grep ${area[$i]} | head -c 18`    
	TR_MONTH_MB=`expr ${TR_MONTH_FROM_FILE} / 1000000`
	echo "$TR_MONTH_FROM_FILE          $TR_MONTH_MB MB      ${area[$i]}" >> $F_TRAF_MONTH_REPORT

    done < $F_CHAIN
    cat $F_TRAF_MONTH_REPORT | mutt  -s “GW_Traffic_Month” $ADMIN_MAIL
    
    }

end_day()
    {
    
	echo " " > /var/log/iptables/begin.traf
    
    }

no_proxy_limit()
    {
#Функция подсчитывает количесво трафика, используемого в течении месяца пользователем.
#В файл, определенный переменной $F_BLOCK в одну строку через пробел вносятся параметры для каждой цепочки.
#Данные параметры при считывании строки в цикле будут считаны в массив и будут испольоваться в качестве пременных в функции.
#    
#    i=0                    
    while read line
    do
#	i=`expr ${i} + 1`
#	area[$i]=$line
    
	m=0
	for param in $line;
	do
	    m=`expr $m + 1`
	    param_arr[$m]=$param
	done
	
	CHAIN_NAME=${param_arr[1]}
	TRAF_ALLOW=${param_arr[2]}
	STATE_FILE=${param_arr[3]}
	USER_MAIL=${param_arr[4]}
	
	if  [ ! -f $F_PATH/$STATE_FILE ]; then
	  echo "0" > $F_PATH/$STATE_FILE
	fi
	  
	read U_STATE < $F_PATH/$STATE_FILE
	
	
	DAY_TRAF=`cat /var/log/iptables/begin.traf | grep ${CHAIN_NAME} | head -c 18`
	MONTH_TRAF=`cat /var/log/iptables/month.traf | grep ${CHAIN_NAME} | head -c 18`
	TRAF_BYTE=`expr ${DAY_TRAF} + ${MONTH_TRAF} + 0`
	TRAF=`expr ${TRAF_BYTE} / 1000000`

	
	if [ $TRAF -gt $TRAF_ALLOW ] && [ $U_STATE -eq 0 ] ; then
	    echo "1" > $F_PATH/$STATE_FILE
#	    $IPTABLES -I $CHAIN_NAME 1 -d $MAIL_ADDR -j ACCEPT
#	    $IPTABLES -I $CHAIN_NAME 2 -s $MAIL_ADDR -j ACCEPT
	    $IPTABLES -I $CHAIN_NAME 1  -j DROP
#	    echo "$CHAIN_NAME TRAFFIC ALERT!!!"  | mutt  -s "$CHAIN_NAME" vasya234@smsmail.ru
	    echo "$CHAIN_NAME TRAFFIC ALERT!!!"  | mutt  -s "$CHAIN_NAME" $ADMIN_MAIL
	    echo "ИЗВИНИТЕ, НО У ВАС ЗАКОНЧИЛСЯ ВЫДЕЛЕННЫЙ ЛИМИТ ТРАФИКА!"  | mutt  -s "$CHAIN_NAME" $USER_MAIL
	fi

	if [ $TRAF -lt $TRAF_ALLOW ] && [ $U_STATE -eq 1 ] ; then
	    echo "0" > $F_PATH/$STATE_FILE
    	    $IPTABLES -D $CHAIN_NAME -j DROP
#    	    $IPTABLES -D $CHAIN_NAME -d $MAIL_ADDR -j ACCEPT
#    	    $IPTABLES -D $CHAIN_NAME -s $MAIL_ADDR -j ACCEPT
        fi
        	            	
    done < $F_BLOCK
    
    }
    
help_doc()
    {
	echo "Данный скрипт подсчитывает трафик по каждой определенной в правилах IPTABLES цепочке."
	echo "С определенной периодичностью (заданной через CRON) счетчики IPTABLES сохраняются в файл и обнуляются."
	echo "В конце дня счетчики и данные из файла, куда они сбрасывались в течении дня, записываются в файл,"
	echo "хранящий значения в течении месяца, и обновляемый каждый день, а файл, в котором хранились значения"
	echo "в течении дня, очищается."
	echo "Параметры: "
	echo "	-d 	- Считать данные из файла, хранящего значения счетчиков в течении дня. Затем считать "
	echo "		  текущие значения счетчиков IPTABLES, сложить и записать в файл."
	echo "	-r	- Вывести отчет о расходе трафика в течении текущего дня."
	echo "	-M	- Считать данные из файла, хранящего значения счетчиков в течении текущего месяца. Затем считать"
	echo "		  данные из файла, хранящего значения счетчиков в течении текущего дня, сложить и записать "
	echo "		  в файл, хранящий значения счетчиков в течении текущего месяца."
	echo "	-R	- Вывести отчет о расходе трафика в течении текущего месяца."
	echo "	-e	- Очистить файл со значениями счетчиков за прошедший день."
	echo "	-p	- Обработать файлы со значениями счетчиков и проверить, не превышен ли установленный лимит"
	echo "		  по использованию трафика. В случае превышения, запретить доступ к ресурсам Интернет и отправить"
	echo "		  уведомление по почте пользователю и сотруднику IT-отдела." 
	echo "	-h	- Помощь." 
	
    
    
    }

#echo "OPTIND starts at $OPTIND"
while getopts ":drMRephq:" optname
  do
     case "$optname" in
	"d")
	    day_traf	    
            ;;
        "r")
    	    day_report
    	    ;;
	"M")
	    month_traf
	    ;;
	"R")
	    month_traf_report
	    ;;
	"e")
	    end_day
	    ;;
	"p")
	    no_proxy_limit
	    ;;
	"h")
	    help_doc
	    ;;
        "?")
            echo "Unknown option $OPTARG"
	    ;;
	 ":")
	    echo "No argument value for option $OPTARG"
	    ;;
	    *)
	    # Соответствий не найдено
	    echo "Unknown error while processing options"
    	    ;;
    esac
  done
                                                                                                                                    