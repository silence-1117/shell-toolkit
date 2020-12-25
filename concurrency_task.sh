#!/bin/bash

THREAD_NUM=10

##File marking time
START_TIME=`date +%Y%m%d%H%M%S`

##Normal, keep the same
QUE_FILE_NAME="/tmp/.$$_fd"

##Normal, keep the same
RESULT_FILE="/tmp/result$START_TIME"

##Calculate task processing time
START_TIME_SEC=`date +%s`

##init job queue
function init_que()
{
    if [[ $# -ne 1 ]];then
        echo "init_que() need to pass one parameter. exit "
        exit 0
    fi

    [ -e $QUE_FILE_NAME ] || mkfifo $QUE_FILE_NAME
    exec 8<>$QUE_FILE_NAME
    rm $QUE_FILE_NAME

    for((i=1; i<=$1; i++))
    do
        echo >&8
    done
}

##clear queue info
function close_que()
{
    exec 8<&-
    exec 8>&-
}


##Task implementation
function task()
{
	if [[ $# -ne 1 ]];then
        echo "You need to pass one parameter..."
        exit 0
    fi

    echo 'test'$1
}

##Task execution result status processing
## $1 : task status
## $2 : The task results need to be output to the log
function task_exec_status_processing()
{
    if [[ $# -ne 2 ]];then
        echo "task_exec_status_processing() need to pass two parameter..."
        exit 0
    fi
    local sts=$1
    local log_time="[`date +"%Y-%m-%d %H:%M:%S"`]"
    case $sts in
        0 )
            echo "$log_time [info] $2 exec success" >> $RESULT_FILE
            ;;
        1 )
            echo -e "$log_time \033[31m[error]\033[0m $2 exec failed" >> $RESULT_FILE
            ;;
        * )
            echo "$log_time Unknow ERROR,please check parameter...." >> $RESULT_FILE
            ;;
    esac
}

##concurrency execution of tasks
function concurrency_task()
{
    for((i=1; i<=50; i++))
    do
        read -u8
        {
            ##exec task
            $1 $i

            ## task status 
            local run_status=$?

            ## Output execution status to result log,Pass in the task information to be printed
            task_exec_status_processing $run_status 'test'$i
            ## Test Print
            echo 'success'$i
            echo >&8
        } &
    done
    wait
}


function main()
{
    echo "[`date +"%Y-%m-%d %H:%M:%S"`] Task exec start...." >> $RESULT_FILE
    echo "[`date +"%Y-%m-%d %H:%M:%S"`] Task exec start...."

    ##Init que
    init_que $THREAD_NUM

    ##Pass the task implementation function name
    concurrency_task task
    
    STOP_TIME=`date +%Y%m%d%H%M%S`
    STOP_TIME_SEC=`date +%s`
    
    echo "[`date +"%Y-%m-%d %H:%M:%S"`]Task exec end...." >> $RESULT_FILE
    echo "$STOP_TIME Task exec end...."

    echo "[`date +"%Y-%m-%d %H:%M:%S"`]  cost time(second):`expr $STOP_TIME - $START_TIME`" >> $RESULT_FILE
    echo "[`date +"%Y-%m-%d %H:%M:%S"`]  cost time(second):`expr $STOP_TIME - $START_TIME`"

    close_que
}

main
