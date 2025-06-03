# capstone_project: E. coli Read Trimming & SNP Calling
## Overview
This repository includes scripts to:
1. QC raw FASTQs (FastQC + MultiQC)  
2. Trim adapters (Trimmomatic)  
3. Align to the E. coli reference (BWA + Samtools)  
4. Call SNPs (bcftools)  
5. Summarize read/variant counts (`summary_stats.sh`)  
6. Produce a final report (`docs/report.Rmd` → PDF)

## Directory Layout
- **capstone_scripts/** – All pipeline scripts:
  - `01_qc_trim.sh`  
  - `02_align_and_snp_call.sbatch`  
  - `summary_stats.sh`
- **data/raw_fastq/** – Six raw FASTQ files + `NexteraPE-PE.fa`  
- **data/genome/** – Downloaded `ecoli_rel606.fna` (indexed by BWA)  
- **results/** – Pipeline outputs:
  - `fastqc_raw/` – FastQC & MultiQC on raw FASTQs  
  - `trimmed_fastq/` – Paired trimmed FASTQs  
  - `fastqc_trimmed/` – FastQC & MultiQC on trimmed FASTQs  
  - `sam/`, `bam/`, `bcf/`, `vcf/` – Alignment & variant files  
  - `summary_table.tsv` – Read/variant counts per sample

## How to Run
1. Copy yourr raw FASTQs and `NexteraPE-PE.fa` into `data/raw_fastq/`.  
2. Run QC + trimming:  
     sbatch capstone_scripts/01_qc_trim.sh
3. Run alignment + SNP calling:  
     sbatch capstone_scripts/02_align_and_snp_call.sh
5. Generate summary table:  
     sbatch capstone_scripts/summary_stats.sh
   - creates results/summary_table.tsv.

**Required Modules**
- FastQC/0.11.9  
- MultiQC/1.14  
- Trimmomatic/0.39 
- BWA/0.7.18  
- SAMtools/1.18  
- BCFtools/1.18

**Github**
https://github.com/AvosaMillie/capstone_project
