#!/bin/bash

DATASET=NONE

while getopts 'd:' c
do
  case $c in
    b) BATCH_SYSTEM=${OPTARG^^};;
  esac
done

if [ "$DATASET" != "CHR18" && "$DATASET" != "WGS" ]; then
  echo dataset must be one of chr18 or wgs
  exit 1
fi

# Setup janis
if [ ! -d venv ]; then
  echo
  echo Installing janis

  module unload python
  module load python/3.7.0

  virtualenv venv
  . venv/bin/activate
  pip install janis-pipelines
  pip install gsutil
  deactivate

  echo done
fi

# Download special cromwell
if [ ! -f data/cromwell-51.jar ]; then
  echo 
  echo Downloading 
  curl -o data/cromwell-51.jar https://github.com/broadinstitute/cromwell/releases/download/51/cromwell-51.jar
fi

. venv/bin/activate

# Download the FASTQs
mkdir -p data/fastqs
if [ "$DATASET" == "WXS" ]; then
  echo Downloading GiaB fastq files
  FASTQ_FILES="24385-12878-30-200_R1_001.fastq.gz 24385-12878-30-200_R2_001.fastq.gz 24385-200_AH5G7WCCXX_S4_L004_R1_001.fastq.gz 24385-200_AH5G7WCCXX_S4_L004_R2_001.fastq.gz"
  for fq in $FASTQ_FILES
  do
      wget -nc -O data/fastqs/${fq} https://ftp-trace.ncbi.nlm.nih.gov/giab/ftp/use_cases/mixtures/UMCUTRECHT_NA12878_NA24385_mixture_10052016/${fq}
  done
else
  echo Downloading chromosome 18
  files=(chr18_R1.normal.fastq.gz  chr18_R1.tumor.fastq.gz  chr18_R2.normal.fastq.gz  chr18_R2.tumor.fastq.gz)
  cloudstor_tokens=(ngpPa7ggxUpekon BP6ZsdyrZrbaz5Y HPrW2TiMl9egNlf jxtSxil4N0WpSSO)
  url="https://cloudstor.aarnet.edu.au/plus/s"
  for ((i=0;i<${#files[@]};++i)); do
    curl -O data/fastqs/${files[i]} url/${tokens[i]}/download
  done
fi
echo done

# Download the references
echo 
echo Downloading references and indexes from GCP
module load google-cloud-sdk
mkdir -p data/reference/
REF_FILES="1000G_phase1.snps.high_confidence.hg38.vcf.gz Homo_sapiens_assembly38.known_indels.vcf.gz Mills_and_1000G_gold_standard.indels.hg38.vcf.gz"
REF_FILES="$REF_FILES Mills_and_1000G_gold_standard.indels.hg38.vcf.gz.tbi 1000G_phase1.snps.high_confidence.hg38.vcf.gz.tbi Homo_sapiens_assembly38.known_indels.vcf.gz.tbi"
REF_FILES="$REF_FILE Homo_sapiens_assembly38.fasta Homo_sapiens_assembly38.fasta.amb Homo_sapiens_assembly38.fasta.ann  Homo_sapiens_assembly38.fasta.bwt Homo_sapiens_assembly38.fasta.fai Homo_sapiens_assembly38.fasta.pac Homo_sapiens_assembly38.fasta.sa"
for gf in $REF_FILES
do
  gsutil cp -n gs://genomics-public-data/references/hg38/v0/${gf} data/reference/
done
if [ ! -f "data/reference/Homo_sapiens_assembly38.dbsnp138.vcf.gz" ]; then
  gsutil -o GSUtil:check_hashes=never cp -n gs://genomics-public-data/references/hg38/v0/Homo_sapiens_assembly38.dbsnp138.vcf data/reference/
  bgzip data/reference/Homo_sapiens_assembly38.dbsnp138.vcf
fi

