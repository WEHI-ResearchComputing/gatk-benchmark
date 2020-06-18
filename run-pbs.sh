#!/bin/bash

#PBS -l nodes=2:ppn=1,mem=4gb,walltime=40:00:00
#PBS -j oe
#PBS -N GATK-run-benchmark

if [ ! -z "$PBS_O_WORKDIR" ]; then
    cd $PBS_O_WORKDIR
fi

hostname

. venv/bin/activate

janis run \
  --no-store \
  --config janis-pbs.conf \
  --inputs inputs.yaml \
  --inputs static.yaml \
  WGSSomaticGATK
