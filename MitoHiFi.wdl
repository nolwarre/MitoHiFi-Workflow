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
    cd /usr/src/MitoHiFi/exampleFiles/

    # run main MitoHiFi using parameters
    /usr/src/MitoHiFi/exampleFiles/run_MitoHiFi.sh \
      -c ~{contigsFasta} \
      -f ~{chrMRefFasta} \
      -g ~{chrMRefGenbank} \
      -t ~{threadCount} \
      -o ~{organismCode}

    # var for assembled mitogenome from MitoHiFi
    assembledMitoGFF=/usr/src/MitoHiFi/exampleFiles/mitogenome.annotation/mitogenome.annotation_MitoFinder_mitfi_Final_Results/mitogenome.annotation_mtDNA_contig.gff
    assembledMitoFasta=/usr/src/MitoHiFi/exampleFiles/mitogenome.annotation/mitogenome.annotation_MitoFinder_mitfi_Final_Results/mitogenome.annotation_mtDNA_contig.fasta

    # finds the number of bases to rotate the mitogenome to correctly align
    grep "tRNA-Phe" $assembledMitoGFF | head -n 1 > first
    firstCoord=$(awk '{print $4}' $first)
    secondCoord=$(grep -B 2 "tRNA-Phe" ~{chrMRefGenbank} | head -n 1 | tr -s '.' | cut -d"." -f2)
    numRotation=$first_coord + $second_coord

    # rotate mitogenome by number of bases and location of tRNA-Phe
    python /usr/src/MitoHiFi/exampleFiles/scripts/rotate.py \
    -i $assembledMitoFasta \
    -r $num_rotation > ~{sampleID}.chrM.fa
  >>>
  #specify the output(s) of this task so cromwell will keep track of them
  output {
    File outFile = sampleID + ".chrM.fa"
  }
  Int runtimeThreadcount = threadCount + 2
  runtime {
    docker: dockerImage
    memory: RAM + "GB"
    cpus: runtimeThreadcount
  }
}
