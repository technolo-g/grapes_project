#!/bin/bash -el

docker run --rm --gpus all -v $(pwd):/root/work -ti grapey bash
