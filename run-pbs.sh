#!/bin/bash

#PBS -l nodes=2:ppn=1,mem=4gb,walltime=100:00:00
#PBS -j oe
#PBS -N GATK-run-benchmark

if [ ! -z "$PBS_O_WORKDIR" ]; then
    cd $PBS_O_WORKDIR
fi

hostname

. venv/bin/activate

#time \
#janis run \
#  --hint-captureType chromosome \
#  --no-store \
#  --config janis-pbs.conf \
#  --inputs inputs-chr18.yaml \
#  --inputs static-chr18.yaml \
#  WGSSomaticGATK

time \
janis run \
  --hint-captureType 90x \
  --no-store \
  --config janis-pbs.conf \
  --inputs inputs-full.yaml \
  --inputs static-full.yaml \
  WGSSomaticGATK
