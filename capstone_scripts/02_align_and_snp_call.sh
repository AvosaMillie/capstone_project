#!/bin/bash
#SBATCH --job-name=align_snp_call                                                         # Job name
#SBATCH --partition=batch                                                                 # Partition (queue) name
#SBATCH --ntasks=1                                                                        # Single task job
#SBATCH --cpus-per-task=1                                                                 # Number of cores per task
#SBATCH --mem=8gb                                                                         # Total memory for job
#SBATCH --time=02:00:00                                                                   # Time limit hrs:min:sec
#SBATCH --output=/scratch/moa46586/capstone_project/align_snp_call_log.%j                 # Log file location
#SBATCH --mail-user=moa46586@uga.edu                                                      # Email for notifications
#SBATCH --mail-type=BEGIN,END,FAIL                                                        # Mail events (BEGIN, END, FAIL)

################################################################################
# 02_align_and_snp_call.sh
#
# 1) Download & index reference genome
# 2) Align each trimmed paired FASTQ in results/trimmed_fastq to the reference
# 3) Convert SAM → sorted BAM (samtools)
# 4) Call SNPs (bcftools mpileup + bcftools call)
# 5) Write compressed VCFs to results/vcf/
#
# Usage:
#   sbatch capstone_scripts/02_align_and_snp_call.sh
################################################################################

#########################
# 1) Paths
#########################
PROJECT_ROOT="/scratch/moa46586/capstone_project"

# Reference genome details
GENOME_URL="ftp://ftp.ncbi.nlm.nih.gov/genomes/all/GCA/000/017/985/GCA_000017985.1_ASM1798v1/GCA_000017985.1_ASM1798v1_genomic.fna.gz"
GENOME_DIR="${PROJECT_ROOT}/data/genome"
REF_FA="${GENOME_DIR}/ecoli_rel606.fna"

# Trimmed paired reads
TRIM_DIR="${PROJECT_ROOT}/results/trimmed_fastq"

# Output directories for alignment & variant-calling
SAM_DIR="${PROJECT_ROOT}/results/sam"
BAM_DIR="${PROJECT_ROOT}/results/bam"
BCF_DIR="${PROJECT_ROOT}/results/bcf"
VCF_DIR="${PROJECT_ROOT}/results/vcf"

#########################
# 2) Create output directories
#########################
mkdir -p "$GENOME_DIR"
mkdir -p "$SAM_DIR" "$BAM_DIR" "$BCF_DIR" "$VCF_DIR"

#########################
# 3) Load required modules
#########################
module load BWA/0.7.18-GCCcore-13.3.0
module load SAMtools/1.18-GCC-12.3.0
module load BCFtools/1.18-GCC-12.3.0

#########################
# 4) Download and index the reference genome
#########################
echo "=== Downloading and indexing E. coli reference genome ==="
wget -O "${GENOME_DIR}/ecoli_rel606.fna.gz" "$GENOME_URL"
gunzip -f "${GENOME_DIR}/ecoli_rel606.fna.gz"

echo "Indexing reference genome for BWA"
bwa index "${GENOME_DIR}/ecoli_rel606.fna"
echo "Reference is ready."

#########################
# 5) Align and snp call loop
#########################
echo "=== STEP: Aligning trimmed reads and calling SNPs ==="

for fwd in "${TRIM_DIR}"/*_1.paired.fastq.gz; do
  sample=$(basename "$fwd" _1.paired.fastq.gz)
  echo "Aligning $sample"
  rev="${TRIM_DIR}/${sample}_2.paired.fastq.gz"
  bwa mem "$REF_FA" "$fwd" "$rev" > "${SAM_DIR}/${sample}.sam"

  echo "Converting SAM → BAM and sorting"
  samtools view -S -b "${SAM_DIR}/${sample}.sam" > "${BAM_DIR}/${sample}.bam"
  samtools sort -o "${BAM_DIR}/${sample}.sorted.bam" "${BAM_DIR}/${sample}.bam"

  echo "Calling variants in $sample"
  bcftools mpileup -O b -o "${BCF_DIR}/${sample}.bcf" -f "$REF_FA" "${BAM_DIR}/${sample}.sorted.bam"
  bcftools call --ploidy 1 -m -v -o "${VCF_DIR}/${sample}.vcf" "${BCF_DIR}/${sample}.bcf"
done

echo "Alignment & SNP calling complete. Check results in: $SAM_DIR, $BAM_DIR, $VCF_DIR"
