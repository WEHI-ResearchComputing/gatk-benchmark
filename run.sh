#!/bin/bash

BATCH_SYSTEM=NONE
DATASET=NONE
QUEUE=NONE

while getopts 'b:d:q:' c
do
  case $c in
    b) BATCH_SYSTEM=${OPTARG,,} ;;
    d) DATASET=${OPTARG,,} ;;
    q) QUEUE=${OPTARG}
  esac
done

if [[ "$BATCH_SYSTEM" != "slurm" && "$BATCH_SYSTEM" != "pbs" ]]; then
  echo batch system must be one of none, slurm or PBS
  exit 1
fi

if [[ "$DATASET" != "chr18" && "$DATASET" != "wgs" ]]; then
  echo dataset must be one of chr18 or wgs
  exit 1
fi


CMD="./do-run.sh -d $DATASET -b $BATCH_SYSTEM"
case $BATCH_SYSTEM in
  slurm)
    if [ -z "$QUEUE" ]; then
	partition="--partition $QUEUE"
    fi
    SUB_CMD="sbatch --job-name GATK-run-benchmark --cpus-per-task=2 --mem=4G --nodes=1 ${partition} --time=100:00:00 -A punim0930"
    ;;

  pbs)
    if [ -z "$QUEUE" ]; then
        queue="-q $QUEUE"
    fi
    SUB_CMD="qsub -l nodes=1:ppn=2,mem=4gb,walltime=240:00:00 -j oe -N GATK-run-benchmark ${queue}"
    ;;
esac

$SUB_CMD << EOF
#!/bin/bash

if [ ! -z "\$PBS_O_WORKDIR" ]; then
  cd \$PBS_O_WORKDIR
fi
hostname

$CMD
EOF
