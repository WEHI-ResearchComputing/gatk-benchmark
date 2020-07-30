# GATK WGS Somatic benchmark
This runs prepares and runs the GATK WGS Somatic pipeline. The primary use case is as probe benchmark for testing
HPCs. The workflow implementation used is this one: [WGS Somatic (GATK only)](https://janis.readthedocs.io/en/latest/pipelines/wgssomaticgatk.html). The WGS data are from [ SAMN03492678 study of NA12878 of the Genome in a Bottle](https://www.ncbi.nlm.nih.gov/Traces/study/?acc=SAMN03492678).


## Initialisation
The script `init.sh` initialises the environment. Run it at the prompt or submit it to your batch system, it takes several hours to run.


* internet access
* python
* samtools tabix bgzip bwa

Modify the `do-init.sh` script to ensure all software is in the path.

Run as
```
./init.sh -d wgs|chr18 -b slurm|pbs
```

The options mean:

* `-d`: dataset which can be either `chr18` for chromosome 18 or `wgs` for whole genome
* `-b`: batch system can `slurm`, `pbs` or left off in which case the script runs inline

The script performs the following steps:

1. It creates a python virtual environment and installs [janis](https://janis.readthedocs.io/en/latest/index.html), a workflow tool and Google cloud utilities to do the downloads from Google cloud.
2. Downloads [Cromwell](https://cromwell.readthedocs.io/en/stable/), a workflow engine
3. Downloads the fastq files from NCBI or just chr18 from cloudstor (derived from the NBCI dataset)
4. Downloads references from Google cloud
5. Builds indexes for the references (the Google ones didn't work for me).

The script makes an attempt to restart efficiently but is by no means robust.

## Running the pipeline
Running the pipeline requires:

* python
* internet access for pulling docker images
* docker or singularity (only tested with singularity)
* Torque/PBS or SLURM. In principal, it could be run inline with `cwltool` but `cwltool` does not parallelise steps and has not been tested.

Modify the `do-run.sh` to ensure all software is in the path. It may be necessary to modify the submit options in the `run.sh` script. It may be necessary to modify the `*.conf` files, refer to the [janis documentation](https://janis.readthedocs.io/en/latest/index.html).


```
./run.sh -d wgs|chr18 -b slurm|pbs
```

Options are as for `init.sh` except that a batch system is required.

Good luck!