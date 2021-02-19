##############################################################################################
# run workflow:
#   dockstore workflow launch --local-entry MitoHiFi.wdl --json MitoHiFi.json
###############################################################################################
#set wdl version
version 1.0

workflow mitoHiFiWorkflow {
   call mito
   output { File mitogenome = mito.outFile}
}

#define the 'mito' task
task mito {
  input {
    File contigsFasta
    File chrMRefFasta
    File chrMRefGenbank
    Int organismCode
    # runtime config
    String dockerImage = "docker.io/nolwarre/mito:optimize"
    Int RAM = 2
    Int threadCount = 1
    Int preemptipleCount = 1
  }

  #define command to execute when this task runs
  command <<<
    # Set the exit code of a pipeline to that of the rightmost command
    # to exit with a non-zero status, or zero if all commands of the pipeline exit
    set -eux -o pipefail

    # create a link to the folder in order to run in entry directory
    ln -s /opt/MitoHiFi/scripts
    ln -s /opt/MitoHiFi/run_MitoHiFi.sh

    # name for sample
    PREFIX=$(basename ~{contigsFasta} | sed 's/.gz$//' | sed 's/.fa\(sta\)*$//' | sed 's/.[pm]at$//')

    # localize fasta input and/or uncompress to working directory
    FILENAME=$(basename -- "~{contigsFasta}")
    if [[ $FILENAME =~ \.gz$ ]]; then
        cp ~{contigsFasta} .
        gzip -d $FILENAME
        mv ${FILENAME%\.gz} localContigs
    else
        mv ~{contigsFasta} localContigs
    fi

    # Re-assemble mito contig from raw assembly input
    ./run_MitoHiFi.sh \
      -c ./localContigs \
      -f ~{chrMRefFasta} \
      -g ~{chrMRefGenbank} \
      -t ~{threadCount} \
      -o ~{organismCode}

    # var for assembled mitogenome from MitoHiFi
    assembledMitoGFF=(./mitogenome.annotation/mitogenome.annotation_MitoFinder_mitfi_Final_Results/mitogenome.annotation_mtDNA_contig.gff)
    assembledMitoFasta=(./mitogenome.annotation/mitogenome.annotation_MitoFinder_mitfi_Final_Results/mitogenome.annotation_mtDNA_contig.fasta)

    # finds the number of bases to rotate the mitogenome to correctly align
    # find initial coordinate of tRNA-Phe from the assembled mito contig
    firstCoord=$(grep "tRNA-Phe" $assembledMitoGFF | head -n 1 | awk '{print $4}')
    # find end coordinate of tRNA-Phe from the reference mitogenome
    secondCoord=$(grep -B 2 "tRNA-Phe" ~{chrMRefGenbank} | head -n 1 | tr -s '.' | cut -d"." -f2)
    # add the intital coordinate and end coordinate of tRNA-phe for combined distance
    numRotation=$(expr $firstCoord + $secondCoord)

    # rotate mitogenome by number of bases and location of tRNA-Phe
    python ./scripts/rotate.py \
      -i $assembledMitoFasta \
      -r $numRotation > $PREFIX.chrM.fa
  >>>
  output {
    File outFile = glob("*.chrM.fa")[0]
  }
  runtime {
    docker: dockerImage
    memory: RAM + "GB"
    cpus: threadCount
    preemptible: preemptipleCount
  }
}
