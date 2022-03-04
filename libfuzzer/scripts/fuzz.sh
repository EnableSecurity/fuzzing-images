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

if [ "$1" != "sample" ] && [ "$1" != "min" ] && [ "$1" != "run" ] && [ "$1" != "bash" ] && [ "$1" != "compile" ] && [ "$1" != "dryrun" ];
then
    echo "allowed methods: sample, min, run, bash, compile, dryrun"
    exit
fi

. /test/build.sh

if [ "$1" == "compile" ];
then
    exit;
fi

# Create initial corpus ram disk
mkdir -p /mnt/ramdisk/corpus /mnt/ramdisk/dict
cp -rf /test/corpus/* /mnt/ramdisk/corpus
cp -rf /test/dict/* /mnt/ramdisk/dict

export LLVM_PROFILE_FILE="%p.profraw"
DATE="`date +"%Y-%m-%d_%H-%M-%S"`"

corpusmin() {
    echo "corpus minimization started"
    mkdir -p /mnt/ramdisk/corpus_min
    ./fuzzer /mnt/ramdisk/corpus_min /mnt/ramdisk/corpus -merge=1
    #  -close_fd_mask=3
    rm -rf /mnt/ramdisk/corpus
    mkdir -p /mnt/ramdisk/corpus
    mv /mnt/ramdisk/corpus_min/* /mnt/ramdisk/corpus
    tar czf /report/corpus.tar.gz /mnt/ramdisk/corpus
    echo "corpus minimization ready"
}

monitor() {
    while true;
    do
        if [ "`ls crash-* 2> /dev/null`" != "" ]; 
        then
            cp -f crash-* /report/${DATE}
        fi

        if [ "`ls leak-* 2> /dev/null`" != "" ]; 
        then
            cp -f leak-* /report/${DATE}
        fi

        if [ "`ls timeout-* 2> /dev/null`" != "" ]; 
        then
            cp -f timeout-* /report/${DATE}
        fi

        . /fuzzer/generatebt.sh /report/${DATE}
        sleep 5
    done
}

fuzz() {
    timepercycle=$1
    parallel=$2

    ./fuzzer /mnt/ramdisk/corpus -dict=/mnt/ramdisk/dict/dict.dict \
        -max_total_time=${timepercycle} -jobs=${parallel} -workers=${parallel} 
        # -close_fd_mask=3
}

coveragereport() {
    REPORTTAG=$1

    NOW="`date +"%Y-%m-%d_%H-%M-%S"`"

    printf "\n\ngenerating coverage report for ${REPORTTAG} at /report/${DATE}/${REPORTTAG}.${NOW}.linebyline-report.txt\n\n"

    llvm-profdata merge -sparse *.profraw -o prof.profdata
    llvm-cov show fuzzer -instr-profile=prof.profdata > /report/${DATE}/${REPORTTAG}.${NOW}.linebyline-report.txt
    llvm-cov show fuzzer -instr-profile=prof.profdata -format=html > /report/${DATE}/${REPORTTAG}.${NOW}.linebyline-report.html
    llvm-cov report fuzzer -instr-profile=prof.profdata > /report/${DATE}/${REPORTTAG}.${NOW}.sourcefiles-report.txt
    llvm-cov report fuzzer -show-functions=true -instr-profile=prof.profdata . > /report/${DATE}/${REPORTTAG}.${NOW}.functions-report.txt
    rm -f *.profraw *.profdata

    echo "${NOW}" >> /report/${DATE}/snapshots.txt
    python3 /fuzzer/process-linebyline-report.py /report/${DATE} /report/${DATE}/report/

    chown -R 1000:1000 /report/${DATE}
}

# If a minimized corpus exists, merge it with the current corpus on startup
if [ "$1" == "run" ] || [ "$1" == "min" ];
then
    if [ -f "/report/corpus.tar.gz" ];
    then
        mkdir -p /mnt/ramdisk/lastruncorpus
        pushd /mnt/ramdisk/lastruncorpus
        cp /report/corpus.tar.gz .
        tar xzf corpus.tar.gz
        mv -f mnt/ramdisk/corpus/* /mnt/ramdisk/corpus
        popd
    fi
fi

if [ "$1" != "compile" ] && [ "$1" != "bash" ] ;
then
    mkdir -p /report/${DATE}
fi

if [ "$1" == "compile" ];
then
    exit
elif [ "$1" == "bash" ];
then
    bash
    exit
elif [ "$1" == "dryrun" ];
then
    for f in `ls /mnt/ramdisk/corpus/`;
    do
        ./fuzzer /mnt/ramdisk/corpus/${f}
    done
    exit
elif [ "$1" == "sample" ];
then
    corpusmin
    fuzz 15 1
    coveragereport "sample"
    corpusmin
elif [ "$1" == "min" ];
then
    corpusmin
elif [ "$1" == "run" ];
then
    monitor &

    timepercycle="60"
    parallel="1"
    rounds="999999"

    if [ "$2" != "" ];
    then
        timepercycle="$2"
    fi

    if [ "$3" != "" ];
    then
        rounds="$3"
    fi

    if [ "$4" != "" ];
    then
        parallel="$4"
    fi

    for (( c=1; c<=${rounds}; c++ ))
    do
        corpusmin
        fuzz $timepercycle $parallel
        coveragereport "run"
    done
    corpusmin
fi

echo "waiting for 10 seconds..."
sleep 10
echo "ready!"