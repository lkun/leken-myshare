#!/bin/bash

###################################
# Please change these parameters according to your real env.
###################################
# set Java Home: Remember that lark only supports JDK8!
# JAVA_HOME=/usr/local/jdk1.8.0_60

# check JAVA_HOME
if [ x"$JAVA_HOME" == x ]; then
    echo "==================== Failed! ====================="
    echo "======         Please set JAVA_HOME         ======"
    echo "=================================================="
    exit 1
fi

# check lsof command
LSOF_PATH=`which lsof`
if [ x"$LSOF_PATH" == x ]; then
    echo "==================== Failed! ====================="
    echo "======      can't find lsof command         ======"
    echo "Please install lsof command first and add to PATH "
    echo "=================================================="
    exit 1
fi

# set ulimit
ulimit -s 20480

# application directory
cd `dirname $0`
APP_HOME=`pwd`

# Java main class to start this program
APP_MAIN_CLASS=com.lion.lark.server.internal.LionServer

# get the full classpath, includes all the jars in lib directory
# especially the conf directory, it will be added to the first of classpath
CLASSPATH=${APP_HOME}/conf/
for i in "$APP_HOME"/lib/*.jar;do
   CLASSPATH="$CLASSPATH":"$i"
done

# read the port and registry settings in the configure file
HTTP_PORT=`sed '/lion.httpPort/!d;s/.*=//' conf/lion.properties | tr -d '\r' | grep -vi "none"`
JAVA_OPTS=`sed '/java.options/!d;s/.*options=//' conf/jvm.properties | tr -d '\r'`
JAVA_MEM_OPTS=`sed '/java.mem.options/!d;s/.*options=//' conf/jvm.properties | tr -d '\r'`


# Java JVM lunch parameters
if [ x"$JAVA_OPTS" == x ];then
    JAVA_OPTS="-Djava.awt.headless=true -Djava.net.preferIPv4Stack=true"
fi
if [ x"$JAVA_MEM_OPTS" == x ];then
    JAVA_MEM_OPTS="-server -Xms512m -Xmx2g -Xmn256m -Xss256k -XX:+DisableExplicitGC -XX:+UseConcMarkSweepGC -XX:+CMSParallelRemarkEnabled -XX:LargePageSizeInBytes=128m -XX:+UseFastAccessorMethods -XX:+UseCMSInitiatingOccupancyOnly -XX:CMSInitiatingOccupancyFraction=70 "
fi
JAVA_DEBUG_OPTS=""
JAVA_DEBUG_PORT=8000
JAVA_DEBUG_ENABLE=false
if [ "$2" == "debug" ]; then
    JAVA_DEBUG_ENABLE=true
    JAVA_DEBUG_OPTS=" -Xdebug -Xnoagent -Djava.compiler=NONE -Xrunjdwp:transport=dt_socket,address=$JAVA_DEBUG_PORT,server=y,suspend=n "
fi

# path of log file, because logback can't create missing directory, we need to help it by shell script
LOGS_DIR="$APP_HOME/logs"
if [ ! -d $LOGS_DIR ]; then
    mkdir $LOGS_DIR
    #echo "created logs directory: path=$LOGS_DIR"
fi
STDOUT_FILE=$LOGS_DIR/out.log

# waiting timeout for starting, in seconds
START_WAIT_TIMEOUT=90

GET_PID_BY_ALL_PORT() {
   pidUsed=$(GET_PID_BY_HTTP_PORT)
   echo ${pidUsed}
}

GET_PID_BY_HTTP_PORT() {
   if [ x"$HTTP_PORT" != x ];then
      echo `/usr/sbin/ss -tnlp sport = ":${HTTP_PORT}" |grep -v State |awk -F"[,)]" '{print $2}'`
   fi
}


GET_PID_BY_DEBUG_PORT() {
    echo `/usr/sbin/ss -tnlp sport = ":${JAVA_DEBUG_PORT}" |grep -v State |awk -F"[,)]" '{print $2}'`
}

###################################
#(function)start process
###################################
start() {
   PID=$(GET_PID_BY_ALL_PORT)

   if [ x"$PID" != x ];then
      echo "==================== Failed! ====================="
      islion=`ps -ef | grep $PID | grep -v grep | grep lion`

      if [ x"$islion" != x ]; then
         isThislion=`ps -ef | grep $PID | grep -v grep | grep "$APP_HOME"`
         if [ x"$isThislion" != x ]; then
            echo "========   lion is already started!   ========"
            echo "========             (pid=$PID)          ========"

         else
            echo "========  Port is used by other lion!  ========"
            echo "========             (pid=$PID)          ========"

         fi
      else
         echo "========  Port is used by other process!  ========"
         echo "========              (pid=$PID)         ========"

      fi

      echo "=================================================="
      echo "try: ps -ef | grep $PID | grep -v grep"

      status
   else
      if [ "$JAVA_DEBUG_ENABLE" = true ]; then
         checkJavaDebugPort
      fi

      echo "Starting lion Server ..."
      echo

      nohup $JAVA_HOME/bin/java $JAVA_OPTS $JAVA_MEM_OPTS $JAVA_DEBUG_OPTS $PINPOINT_OPTS -classpath $CLASSPATH $APP_MAIN_CLASS >$STDOUT_FILE 2>&1 &

      sleep 1
      PID=$(GET_PID_BY_ALL_PORT)
      starttime=0


       while  [ x"$PID" == x ]; do
           if [[ "$starttime" -lt ${START_WAIT_TIMEOUT} ]]; then
              sleep 1
              ((starttime++))
              echo -e ".\c"
              PID=$(GET_PID_BY_ALL_PORT)
           else
              echo "lion Server failed to start"
              echo "The port $HTTP_PORT doesn't open in ${START_WAIT_TIMEOUT} seconds!"
              echo "check logs/out.log to see the details"
              status
              exit -1
           fi
       done

      echo
      echo "The process of lion Server is started: pid=$PID"
      echo "===================================================================="
      echo "====       Please check logs/out.log and server.log             ===="
      echo "===================================================================="
      status
   fi
}

###################################
# (function) check port of java debug
###################################
checkJavaDebugPort() {
   PID=$(GET_PID_BY_DEBUG_PORT)

   if [ x"$PID" != x ];then
      echo "Warning: java debug port $JAVA_DEBUG_PORT is in use by process $PID!"
      echo
      echo "===================================================================="
      lsof -i :$JAVA_DEBUG_PORT
      echo "===================================================================="
      echo
      echo "failed to start, try to fix it before starting lion server:"
      echo "    |-- close the process $PID to free this port $JAVA_DEBUG_PORT."
      echo "    |-- Or change the JAVA_DEBUG_PORT (in this script) to another one."

      exit -1
   fi

   echo "=== Java debug enabled on port $JAVA_DEBUG_PORT ==="
}

###################################
# (function) stop process
###################################
stop() {
   PID=$(GET_PID_BY_ALL_PORT)

   if [ x"$PID" == x ];then
      echo "==================== Failed! ====================="
      echo "========    Can't find lion Server!    ========"
      echo "========           (by port=$HTTP_PORT)         ========"
      echo "=================================================="
      status
      return
   fi

   isThislion=`ps -ef | grep $PID | grep -v grep | grep "$APP_HOME"`
   if [ x"$isThislion" == x ]; then
      echo "==================== Failed! ====================="
      echo "=====   Another lion is using the port!   ====="
      echo "=====               (pid=$PID)              ====="
      echo "=================================================="
      echo "try: ps -ef | grep $PID | grep -v grep"
      status
      return
   fi

   echo "lion Server is running with port $HTTP_PORT: pid=$PID"
   echo "trying to stop lion Server (pid=$PID) ..."
   kill -15 $PID
   sleep 3
   PID=$(GET_PID_BY_ALL_PORT)
   while [ x"$PID" != x ]; do
      echo -n "."
      kill $PID
      sleep 1
      PID=$(GET_PID_BY_ALL_PORT)
   done

   echo
   echo "====================== OK ========================="
   echo "=====         lion Server stopped         ====="
   echo "==================================================="
   status
}

###################################
# (function) check running status of process
###################################
status() {
   PID=$(GET_PID_BY_ALL_PORT)

   echo ""
   echo ""------------------- status -----------------------""

   if [ x"$PID" != x ]; then
      islion=`ps -ef | grep $PID | grep -v grep`
      if [ x"$islion" != x ]; then
         isThislion=`ps -ef | grep $PID | grep -v grep | grep "$APP_HOME"`
         if [ x"$isThislion" != x ]; then
            echo "lion server (pid=$PID) is running and using ports:"
         else
            echo "Another lion server (pid=$PID) is running and using ports:"
         fi
      else
         echo "Another process (pid=$PID) is using ports:"
      fi
   else
      echo "Ports (${HTTP_PORT}) are NOT in use!"
   fi

        echo "    |"

   if [ x"$HTTP_PORT" != x ]; then
      PID=$(GET_PID_BY_HTTP_PORT)
      if [ x"$PID" != x ]; then
         echo "    |-- HTTP_PORT ${HTTP_PORT} is in use by process $PID"
      else
         echo "    |-- HTTP_PORT ${HTTP_PORT} is not in use"
      fi
   fi

   echo ""
}

###################################
# (function) print env variables
###################################
info() {
   echo
   echo "************* [OS] ***************"
   echo "OS Release: " `head -n 1 /etc/issue`
   echo "OS Infomation: " `uname -a`
   echo
   echo "*************  [JVM]  ***************"
   echo "JAVA_HOME: $JAVA_HOME"
   echo "JAVA_OPTS: $JAVA_OPTS"
   echo "JAVA_MEM_OPTS: $JAVA_MEM_OPTS"
   echo
   echo "*************  [CLASSPATH]  ***************"
   echo "CLASSPATH: $CLASSPATH"
   echo
   echo "*************  [APPLICATION]  ***************"
   echo "JAVA_MAIN_CLASS: $APP_MAIN_CLASS"
   echo "APP_HOME=$APP_HOME"
   echo "****************************"
}

###################################
# get the first argument of this script, then check it
# this argument should be one of : {start|stop|restart|status|info}
# if not, print help information
###################################
case "$1" in
   'start')
      start
      ;;
   'stop')
     stop
     ;;
   'status')
     status
     ;;
   'info')
     info
     ;;
   'restart')
     stop
     start
     ;;
  *)
     echo "Usage: $0 {start|stop|status|info}"
     exit 1
esac