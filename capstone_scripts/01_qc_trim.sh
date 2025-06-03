#!/bin/bash
#SBATCH --job-name=QC_Trim                                                                # Job name
#SBATCH --partition=batch                                                                 # Partition (queue) name
#SBATCH --ntasks=1                                                                        # Single task job
#SBATCH --cpus-per-task=1                                                                 # Number of cores per task
#SBATCH --mem=8gb                                                                         # Total memory for job
#SBATCH --time=02:00:00                                                                   # Time limit hrs:min:sec
#SBATCH --output=/scratch/moa46586/capstone_project/QC_Trim_log.%j                        # Log file location
#SBATCH --mail-user=moa46586@uga.edu                                                      # Email for notifications
#SBATCH --mail-type=BEGIN,END,FAIL                                                        # Mail events (BEGIN, END, FAIL)


#########################
# 1) Paths
#########################
PROJECT_ROOT="/scratch/moa46586/capstone_project" # Path to my project directory
SOURCE_RAW="/scratch/moa46586/ecoli_variation/data/raw_fastq" # Source location of raw FASTQs (on /scratch)
RAW_DIR="${PROJECT_ROOT}/data/raw_fastq" # Destination for raw FASTQs in your project
QC_RAW_DIR="${PROJECT_ROOT}/results/fastqc_raw" # Output directory for rawqc
TRIM_DIR="${PROJECT_ROOT}/results/trimmed_fastq" # Output directory for trimmed data after QC
QC_TRIM_DIR="${PROJECT_ROOT}/results/fastqc_trimmed" # Output directory for the QC of the trimmed data
ADAPTERS="${RAW_DIR}/NexteraPE-PE.fa" # Adapter file for Trimmomatic


#########################
# 2) Creating the directories
#########################
mkdir -p "$RAW_DIR"
mkdir -p "$QC_RAW_DIR"
mkdir -p "$TRIM_DIR"
mkdir -p "$QC_TRIM_DIR"

#########################
# 3) Copy raw fastqc and Nextera PE
#########################
echo "=== STEP 1: Copying raw FASTQ files and Nextera adapter ==="
cp "${SOURCE_RAW}"/*.fastq.gz "${RAW_DIR}/"
cp "/scratch/moa46586/ecoli_variation/data/NexteraPE-PE.fa" "${RAW_DIR}/"
echo "Copied FASTQs and NexteraPE-PE.fa into ${RAW_DIR}"

######################
# 4) Load the packages
######################
module load FastQC/0.11.9-Java-11
module load MultiQC/1.14-foss-2022a
module load Trimmomatic/0.39-Java-13

TRIMMOMATIC_JAR="${EBROOTTRIMMOMATIC}/trimmomatic-0.39.jar"
if [ ! -f "$TRIMMOMATIC_JAR" ]; then
  echo "ERROR: Cannot find Trimmomatic JAR at $TRIMMOMATIC_JAR"
  exit 1
fi
echo "Using TRIMMOMATIC_JAR = $TRIMMOMATIC_JAR"

#########################
# 5) QC on raw reads
#########################
echo "=== STEP 2: FastQC on raw FASTQs ==="
fastqc -o "$QC_RAW_DIR" "${RAW_DIR}"/*.fastq.gz
multiqc -o "$QC_RAW_DIR" "$QC_RAW_DIR"
echo "Raw‐read QC complete. Reports in: $QC_RAW_DIR"

#########################
# 5) TRIMMING WITH TRIMMOMATIC
#########################
echo "=== STEP 3: Trimming raw reads with Trimmomatic ==="

for fwd in "${RAW_DIR}"/*_1.fastq.gz; do
    [ -e "$fwd" ] || continue
    sample="$(basename "$fwd" _1.fastq.gz)"
    echo "→ Trimming sample: $sample"

    out_p1="${TRIM_DIR}/${sample}_1.paired.fastq.gz"
    out_u1="${TRIM_DIR}/${sample}_1.unpaired.fastq.gz"
    out_p2="${TRIM_DIR}/${sample}_2.paired.fastq.gz"
    out_u2="${TRIM_DIR}/${sample}_2.unpaired.fastq.gz"

    java -jar $TRIMMOMATIC_JAR PE \
      "${RAW_DIR}/${sample}_1.fastq.gz" "${RAW_DIR}/${sample}_2.fastq.gz" \
      "$out_p1" "$out_u1" \
      "$out_p2" "$out_u2" \
      ILLUMINACLIP:"$ADAPTERS":2:30:10:5:True SLIDINGWINDOW:4:20

done    
echo "Trimming complete. Paired FASTQs are in: $TRIM_DIR"

#########################
# 6) QC ON TRIMMED READS
#########################
echo "=== STEP 4: FastQC on trimmed (paired) FASTQs ==="
module load FastQC/0.11.9-Java-11
module load MultiQC/1.14-foss-2022a

fastqc -o "$QC_TRIM_DIR" "${TRIM_DIR}"/*_*.paired.fastq.gz
multiqc -o "$QC_TRIM_DIR" "$QC_TRIM_DIR"
echo "Trimmed‐read QC complete. Reports in: $QC_TRIM_DIR"

echo "=== ALL STEPS FINISHED ==="

