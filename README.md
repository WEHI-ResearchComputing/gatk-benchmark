# GATK WGS Somatic benchmark
This runs prepares and runs the GATK WGS Somatic pipeline. The primary use case is as probe benchmark for testing
your HPC. The workflow implementation used is this one: [WGS Somatic (GATK only)](https://janis.readthedocs.io/en/latest/pipelines/wgssomaticgatk.html). The WGS data are from [ SAMN03492678 study of NA12878 of the Genome in a Bottle](https://www.ncbi.nlm.nih.gov/Traces/study/?acc=SAMN03492678).

***NOTE:*** This is not fully tested

## Initialisation
The script `init.sh` initialises the environment. Run it at the prompt or submit it to your batch system, it takes several hours to run.
It needs:

* internet access
* python `virtualenv` and has only been tested with python 3.7

The script performs the following steps:

1. It creates a python virtual environment and installs [janis](https://janis.readthedocs.io/en/latest/index.html), a workflow tool and Google 
cloud utilities to do the downloads from Google cloud.
2. Downloads [Cromwell](https://cromwell.readthedocs.io/en/stable/), a workflow engine
3. Downloads the fastq files from NCBI
4. Downloads references from Google cloud
5. Builds indexes for the references.

The script makes an attempt to restart effeciently but is by no means robust.

## Running the pipeline
There is currently one script for running in the WEHI PBS system, `run-pbs.sh`.

```
qsub run-pbs.sh
```

Good luck.