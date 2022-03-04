#!/bin/bash

for crash in `ls $1/crash-* 2> /dev/null`;
do
    if [[ ${crash} != *".bt"* ]]; then
        if [ ! -f ${crash}.bt ]; then
            ./fuzzer $crash &> ${crash}.bt
        fi
    fi
done
