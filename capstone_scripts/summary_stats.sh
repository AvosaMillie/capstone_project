#!/bin/bash
#SBATCH --job-name=summary_stats                                                          # Job name
#SBATCH --partition=batch                                                                 # Partition (queue) name
#SBATCH --ntasks=1                                                                        # Single task job
#SBATCH --cpus-per-task=1                                                                 # Number of cores per task
#SBATCH --mem=2gb                                                                         # Total memory for job
#SBATCH --time=02:00:00                                                                   # Time limit hrs:min:sec
#SBATCH --output=/scratch/moa46586/capstone_project/summary_stats_log.%j                        # Log file location
#SBATCH --mail-user=moa46586@uga.edu                                                      # Email for notifications
#SBATCH --mail-type=BEGIN,END,FAIL

# Counts, for each sample:
#   1) # raw reads
#   2) # trimmed reads (paired only)
#   3) # aligned reads (samtools view -F 0x4)
#   4) # variant sites
#
# Produces a tab-delimited table where each row contains the sample name, raw‐read count, trimmed‐read count, aligned‐read count, and variant count
#
# Usage: cd /scratch/moa46586/capstone_project
#        bash capstone_scripts/summary_stats.sh > summary_table.tsv
#

set -euo pipefail

# Load required modules
module load SAMtools/1.18-GCC-12.3.0

# Directories
RAW_DIR="/scratch/moa46586/capstone_project/data/raw_fastq"
TRIM_DIR="/scratch/moa46586/capstone_project/results/trimmed_fastq"
BAM_DIR="/scratch/moa46586/capstone_project/results/bam"
VCF_DIR="/scratch/moa46586/capstone_project/results/vcf"
OUTFILE="/scratch/moa46586/capstone_project/results/summary_table.tsv"

# Output header
echo -e "sample\traw_reads\ttrimmed_reads\taligned_reads\tvariant_sites" > "$OUTFILE"

# Loop over samples by looking for raw _1.fastq.gz (one per sample)
for fwd in "${RAW_DIR}"/*_1.fastq.gz; do
  # Get sample name (strip _1.fastq.gz)
  sample=$(basename "$fwd" _1.fastq.gz)

  # 1) Count raw reads:
  #    Each FASTQ entry is 4 lines, so number of reads = total lines / 4.
  #    Use zcat to stream‐decompress and wc -l to count lines.
  raw_lines=$(zcat "${RAW_DIR}/${sample}_1.fastq.gz" | wc -l)
  raw_reads=$(( raw_lines / 4 ))

  # 2) Count trimmed reads (paired only). 
  #    The paired output is ${sample}_1.paired.fastq.gz.
  #    Again each read = 4 lines.
  trimmed_fwd="${TRIM_DIR}/${sample}_1.paired.fastq.gz"
  if [ -f "$trimmed_fwd" ]; then
    trimmed_lines=$(zcat "$trimmed_fwd" | wc -l)
    trimmed_reads=$(( trimmed_lines / 4 ))
  else
    trimmed_reads=0
  fi

  # 3) Count aligned reads (BAM). 
  #    `samtools view -F 0x4` filters out all reads that are UNMAPPED.
  #    So “-F 0x4” means: “only show reads with flag 0x4 (unmapped) turned off = i.e. mapped reads.”
  bam="${BAM_DIR}/${sample}.sorted.bam"
  if [ -f "$bam" ]; then
    aligned_reads=$(samtools view -F 0x4 "$bam" | wc -l)
  else
    aligned_reads=0
  fi

  # 4) Count variant sites: 
  #    Count lines in the VCF excluding the header (lines that start with “#”).
  #    My VCF is uncompressed (.vcf), use grep/vcftools; if compressed (.vcf.gz), use zgrep,
vcf="${VCF_DIR}/${sample}.vcf"
if [ -f "$vcf" ]; then
  # Count non‐header lines directly
  variant_sites=$(grep -v '^#' "$vcf" | wc -l)
else
  variant_sites=0
fi

  # Print a single line for this sample:
  echo -e "${sample}\t${raw_reads}\t${trimmed_reads}\t${aligned_reads}\t${variant_sites}" \
    >> "$OUTFILE"
 
done

