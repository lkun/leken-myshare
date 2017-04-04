#!/bin/bash

# application directory
cd `dirname $0`
APP_HOME=`pwd`

# read the port and registry settings in the configure file
HTTP_PORT=`sed '/lion.httpPort/!d;s/.*=//' conf/lion.properties | tr -d '\r'`

GET_PID_BY_ALL_PORT() {
   echo `/usr/sbin/ss -tnlp sport = ":${HTTP_PORT}" |grep -v State |awk -F"[,)]" '{print $2}'`
}

# get process id by HTTP port
psid=$(GET_PID_BY_ALL_PORT)

# check psid to see if it has been started
if [ x"$psid" == x ];then
   echo "================================"
   echo "Waring: Lion Server is not running"
   echo "================================"
   exit 1
fi

LOGS_DIR="$APP_HOME/logs"
if [ ! -d $LOGS_DIR ]; then
    mkdir $LOGS_DIR
fi
DUMP_DIR=$LOGS_DIR/dump
if [ ! -d $DUMP_DIR ]; then
  mkdir $DUMP_DIR
fi
DUMP_DATE=`date +%Y%m%d%H%M%S`
DATE_DIR=$DUMP_DIR/$DUMP_DATE
if [ ! -d $DATE_DIR ]; then
  mkdir $DATE_DIR
fi

echo "Dumping Lion Server (PID=$psid) ..."
JSTACK_DUMP_COUNT=1
while [ ${JSTACK_DUMP_COUNT} -lt 4 ]; do
  echo "do jstack dump($JSTACK_DUMP_COUNT)"
  jstack $psid > $DATE_DIR/jstack.$JSTACK_DUMP_COUNT.dump 2>&1
  if [ ${JSTACK_DUMP_COUNT} -lt 3 ]; then
    echo "wait for 5 seconds to do next jstack dump"
    sleep 5s
  fi
  JSTACK_DUMP_COUNT=$((JSTACK_DUMP_COUNT+1))
done

echo -e ".\c"
jinfo $psid > $DATE_DIR/jinfo.dump 2>&1
echo -e ".\c"
jstat -gcutil $psid > $DATE_DIR/jstat-gcutil.dump 2>&1
echo -e ".\c"
jstat -gccapacity $psid > $DATE_DIR/jstat-gccapacity.dump 2>&1
echo -e ".\c"
jmap -dump:format=b,file=$DATE_DIR/jmap.bin $psid
echo -e ".\c"
jmap -heap $psid > $DATE_DIR/jmap-heap.dump 2>&1
echo -e ".\c"
jmap -histo $psid > $DATE_DIR/jmap-histo.dump 2>&1
echo -e ".\c"
if [ -r /usr/sbin/lsof ]; then
/usr/sbin/lsof -p $psid > $DATE_DIR/lsof.dump
echo -e ".\c"
fi


if [ -r /bin/netstat ]; then
/bin/netstat -an > $DATE_DIR/netstat.dump 2>&1
echo -e ".\c"
fi
if [ -r /usr/bin/iostat ]; then
/usr/bin/iostat > $DATE_DIR/iostat.dump 2>&1
echo -e ".\c"
fi
if [ -r /usr/bin/mpstat ]; then
/usr/bin/mpstat > $DATE_DIR/mpstat.dump 2>&1
echo -e ".\c"
fi
if [ -r /usr/bin/vmstat ]; then
/usr/bin/vmstat > $DATE_DIR/vmstat.dump 2>&1
echo -e ".\c"
fi
if [ -r /usr/bin/free ]; then
/usr/bin/free -t > $DATE_DIR/free.dump 2>&1
echo -e ".\c"
fi
if [ -r /usr/bin/sar ]; then
/usr/bin/sar > $DATE_DIR/sar.dump 2>&1
echo -e ".\c"
fi
if [ -r /usr/bin/uptime ]; then
/usr/bin/uptime > $DATE_DIR/uptime.dump 2>&1
echo -e ".\c"
fi

echo "OK!"
echo "DUMP: $DATE_DIR"