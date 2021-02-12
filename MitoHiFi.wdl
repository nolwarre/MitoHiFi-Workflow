##############################################################################################
# run workflow:
#   dockstore workflow launch --local-entry MitoHiFi.wdl --json MitoHiFi.json
###############################################################################################
#set wdl version
version 1.0

#add and name a workflow block
workflow mitoHiFiWorkflow {
   call mito
   output { File assembly = mito.outFile}
}

#define the 'mito' task
task mito {
  input {
    File contigsFasta
    File chrMRefFasta
    File chrMRefGenbank
    String sampleID
    Int organismCode
    String dockerImage
    Int RAM = 2
    Int threadCount = 1
  }

  #define command to execute when this task runs
  command <<<
    # go to work directory
    cd /opt/MitoHiFi/exampleFiles/

    # run main MitoHiFi using parameters
    /opt/MitoHiFi/exampleFiles/run_MitoHiFi.sh \
      -c ~{contigsFasta} \
      -f ~{chrMRefFasta} \
      -g ~{chrMRefGenbank} \
      -t ~{threadCount} \
      -o ~{organismCode}

    # var for assembled mitogenome from MitoHiFi
    assembledMitoGFF=/opt/MitoHiFi/exampleFiles/mitogenome.annotation/mitogenome.annotation_MitoFinder_mitfi_Final_Results/mitogenome.annotation_mtDNA_contig.gff
    assembledMitoFasta=/opt/MitoHiFi/exampleFiles/mitogenome.annotation/mitogenome.annotation_MitoFinder_mitfi_Final_Results/mitogenome.annotation_mtDNA_contig.fasta

    # finds the number of bases to rotate the mitogenome to correctly align
    grep "tRNA-Phe" $assembledMitoGFF | head -n 1 > first
    firstCoord=$(awk '{print $4}' $first)
    secondCoord=$(grep -B 2 "tRNA-Phe" ~{chrMRefGenbank} | head -n 1 | tr -s '.' | cut -d"." -f2)
    numRotation=$(expr $firstCoord + $secondCoord)

    # rotate mitogenome by number of bases and location of tRNA-Phe
    python /opt/MitoHiFi/exampleFiles/scripts/rotate.py \
    -i $assembledMitoFasta \
    -r $numRotation > /data/~{sampleID}.chrM.fa
  >>>
  #specify the output(s) of this task so cromwell will keep track of them
  output {
    File outFile = "/data/~{sampleID}.chrM.fa"
  }
  runtime {
    docker: dockerImage
    memory: RAM + "GB"
    cpus: threadCount
  }
}
