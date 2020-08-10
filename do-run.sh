#!/bin/bash

#---------------------------------------------------------
# This bit will need to be modified for your enviroment
module purge
# WEHI
module load python/3.7.0 samtools/1.9 bwa singularity/3.5.2
# spartan
#module load Python Singularity web_proxy Java
#---------------------------------------------------------
python --version

BATCH_SYSTEM=NONE
DATASET=NONE

while getopts 'b:d:' c
do
  case $c in
    b) BATCH_SYSTEM=${OPTARG,,} ;;
    d) DATASET=${OPTARG,,} ;;
  esac
done

if [[ "$DATASET" != "chr18" && "$DATASET" != "wgs" ]]; then
  echo dataset must be one of chr18 or wgs
  exit 1
fi

if [[ "$BATCH_SYSTEM" != "slurm" && "$BATCH_SYSTEM" != "pbs" ]]; then
  echo batch system must be one of none, slurm or PBS
  exit 1
fi

case $DATASET in
  wgs) HINT=90x ;;
  chr18) HINT=chromosome ;;
esac

. venv/bin/activate

time \
janis run \
  --hint-captureType ${HINT} \
  --no-store \
  --config janis-${BATCH_SYSTEM}.conf \
  --inputs inputs-${DATASET}.yaml \
  --inputs static-${DATASET}.yaml \
  WGSSomaticGATK
