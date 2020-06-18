#!/bin/bash

#PBS -l nodes=1:ppn=2,mem=16gb,walltime=24:00:00
#PBS -j oe
#PBS -N GATK-init-benchmark

if [ ! -z "$PBS_O_WORKDIR" ]; then
    cd $PBS_O_WORKDIR
    hostname
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
echo Downloading fastq files
mkdir -p data/fastqs
FASTQ_FILES="24385-12878-30-200_R1_001.fastq.gz 24385-12878-30-200_R2_001.fastq.gz 24385-200_AH5G7WCCXX_S4_L004_R1_001.fastq.gz 24385-200_AH5G7WCCXX_S4_L004_R2_001.fastq.gz"
for fq in $FASTQ_FILES
do
    wget -nc -O data/fastqs/${fq} https://ftp-trace.ncbi.nlm.nih.gov/giab/ftp/use_cases/mixtures/UMCUTRECHT_NA12878_NA24385_mixture_10052016/${fq}
done
echo done

# Download the references
echo 
echo Downloading references
module load google-cloud-sdk
mkdir -p data/reference/
REF_FILES="Homo_sapiens_assembly38.fasta 1000G_phase1.snps.high_confidence.hg38.vcf.gz Homo_sapiens_assembly38.known_indels.vcf.gz Mills_and_1000G_gold_standard.indels.hg38.vcf.gz"
for gf in $REF_FILES
do
   gsutil cp -n gs://genomics-public-data/references/hg38/v0/${gf} data/reference/
done
if [ ! -f "data/reference/Homo_sapiens_assembly38.dbsnp138.vcf.gz" ]; then
   gsutil -o GSUtil:check_hashes=never cp -n gs://genomics-public-data/references/hg38/v0/Homo_sapiens_assembly38.dbsnp138.vcf data/reference/
   bgzip data/reference/Homo_sapiens_assembly38.dbsnp138.vcf
fi
echo done

# Build indexes
if [ ! -f "data/reference/Homo_sapiens_assembly38.fasta.amb" ]; then
    echo
    echo Building reference indexes
    janis run --config janis-local.conf -o data/reference IndexFasta --reference data/reference/Homo_sapiens_assembly38.fasta
    mv data/reference/reference.fasta.amb data/reference/Homo_sapiens_assembly38.fasta.amb
    mv data/reference/reference.fasta.ann data/reference/Homo_sapiens_assembly38.fasta.ann
    mv data/reference/reference.fasta.bwt data/reference/Homo_sapiens_assembly38.fasta.bwt
    mv data/reference/reference.fasta.fai data/reference/Homo_sapiens_assembly38.fasta.fai
    mv data/reference/reference.fasta.pac data/reference/Homo_sapiens_assembly38.fasta.pac
    mv data/reference/reference.fasta.sa data/reference/Homo_sapiens_assembly38.fasta.sa
    mv data/reference/reference.dict data/reference/Homo_sapiens_assembly38.dict
    echo done
fi
for vcf in data/reference/*.vcf.gz
do
    if [ ! -f "${vcf}.tbi" ]; then
        echo
        echo Building tabix index for ${vcf}
        janis run --config janis-local.conf -o data/reference tabix --inp ${vcf}
        rm -f data/reference/out.vcf.gz
        mv data/reference/out.vcf.gz.tbi ${vcf}.tbi
        echo done
    fi
done
