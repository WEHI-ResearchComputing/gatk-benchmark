#!/bin/bash

BATCH_SYSTEM=NONE
DATASET=NONE

while getopts 'b:d:' c
do
  case $c in
    b) BATCH_SYSTEM=${OPTARG^^} ;;
    d) DATASET=${OPTARG^^} ;;
  esac
done

if [[ "$BATCH_SYSTEM" != "NONE" && "$BATCH_SYSTEM" != "SLURM" && "$BATCH_SYSTEM" != "PBS" ]]; then
  echo batch system must be one of none, slurm or PBS
  exit 1
fi

if [[ "$DATASET" != "CHR18" && "$DATASET" != "WGS" ]]; then
  echo dataset must be one of chr18 or wgs
  exit 1
fi

CMD="./do-init.sh -d $DATASET"
case $BATCH_SYSTEM in
  NONE)
    $CMD
    exit $?
    ;;

  SLURM)
    SUB_CMD="sbatch --job-name GATK-init-benchmark --cpus-per-task=2 --mem=4G --nodes=1 --time=24:00:00"
    ;;

  PBS)
    SUB_CMD="qsub -l nodes=1:ppn=2,mem=4gb,walltime=24:00:00 -j oe -N GATK-init-benchmark"
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
