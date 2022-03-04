#!/bin/bash

if [ ! -d /test ];
then
    echo "/test not mounted, aborting"
    exit
fi

if [ ! -f /test/build.sh ];
then
    echo "missing /test/build.sh, aborting"
    exit
fi

if [ ! -d /report ];
then
    echo "/report not mounted, aborting"
    exit
fi

echo core >/proc/sys/kernel/core_pattern
pushd /sys/devices/system/cpu
echo performance | tee cpu*/cpufreq/scaling_governor
popd

# Create initial corpus ram disk
mkdir -p /mnt/ramdisk/corpus /mnt/ramdisk/dict
cp -rf /test/corpus/* /mnt/ramdisk/corpus
cp -rf /test/dict/* /mnt/ramdisk/dict

DATE="`date +"%Y-%m-%d_%H-%M-%S"`"
mkdir -p /report/${DATE}

monitor() {
    monitorpath="$1"
    while true;
    do
        if [ "`ls /mnt/ramdisk/results/${monitorpath}/crashes/* 2> /dev/null`" != "" ]; 
        then
            cp -f /mnt/ramdisk/results/${monitorpath}/crashes/* /report/${DATE}
        fi
        sleep 5
    done
}

crashanalysis() {
    while true;
    do
        for f in `ls /report/${DATE}/id:*`;
        do
            filename=$(basename -- "$f")
            extension="${filename##*.}"

            if [ "$extension" != "trace" ];
            then
                if [ ! -f "${f}.trace" ];
                then
                    ./fuzzer < $f 2> ${f}.trace
                fi
            fi
        done
        sleep 5
    done
}

if [ "$1" != "run" ] && [ "$1" != "bash" ] && [ "$1" != "compile" ];
then
    echo "allowed methods: run, bash or compile"
    exit
fi

. /test/build.sh

if [ "$1" == "compile" ];
then
    exit;
fi

if [ "$1" == "bash" ];
then
    bash
    exit
fi

duration="99999"
parallel="1"

if [ "$2" != "" ];
then
    duration="$2"
fi

if [ "$3" != "" ];
then
    parallel="$3"
fi

durationhandler() {
    sleep ${duration}
    killall afl-fuzz
    touch /tmp/killswitch
}
durationhandler &

# bash
mkdir -p /mnt/ramdisk/results
if [ "$parallel" == "1" ];
then
    monitor fuzzer01 &
    crashanalysis 2> /dev/null &
    afl-fuzz -i /mnt/ramdisk/corpus -o /mnt/ramdisk/results -M fuzzer01 -m none ./fuzzer
else
    monitor fuzzer1 &
    crashanalysis 2> /dev/null &
    afl-fuzz -i /mnt/ramdisk/corpus -o /mnt/ramdisk/results -M fuzzer1 -m none ./fuzzer > /dev/null &
    for i in $(eval echo {2..$parallel});
    do
        monitor fuzzer$i &
        afl-fuzz -i /mnt/ramdisk/corpus -o /mnt/ramdisk/results -S fuzzer$i -m none ./fuzzer > /dev/null &
    done

    while true;
    do
        afl-whatsup /mnt/ramdisk/results | tee /report/${DATE}/status.log
        if [ -f "/tmp/killswitch" ];
        then
            exit
        fi
        sleep 5
    done
fi

