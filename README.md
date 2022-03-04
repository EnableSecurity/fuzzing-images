## Description

This repository consists of a set of Docker images whose purpose is to help in fuzzing source code using libfuzzer, AFL, etc.

The base image that contains the installation of clang built from source can be created manually via the workflow `build-clang12.yml`. This image will not change frequently and therefore it is a waste of time to build it on every commit.

