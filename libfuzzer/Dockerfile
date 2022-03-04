FROM ghcr.io/enablesecurity/fuzzing-images/clang12:latest

WORKDIR /fuzzer

COPY scripts/fuzz.sh fuzz.sh
COPY scripts/generatebt.sh generatebt.sh
COPY scripts/process-linebyline-report.py process-linebyline-report.py

ENTRYPOINT [ "./fuzz.sh" ]
