##############################################################################################
# run workflow:
#   dockstore workflow launch --local-entry MitoHiFi.wdl --json MitoHiFi.json
###############################################################################################
#set wdl version
version 1.0

#add and name a workflow block
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
    String dockerImage
    Int RAM = 2
    Int threadCount = 1
  }

  #define command to execute when this task runs
  String mitoOut = basename(contigsFasta,".fa") + ".chrM.fa"
  command <<<
    # Set the exit code of a pipeline to that of the rightmost command
    # to exit with a non-zero status, or zero if all commands of the pipeline exit
    set -o pipefail
    # cause a bash script to exit immediately when a command fails
    set -e
    # cause the bash shell to treat unset variables as an error and exit immediately
    set -u
    # echo each line of the script to stdout so we can see what is happening
    # to turn off echo do 'set +o xtrace'
    set -o xtrace

    # create a link to the folder in order to run in entry directory
    ln -s /opt/MitoHiFi/scripts
    ln -s /opt/MitoHiFi/run_MitoHiFi.sh

    # localize fasta input to working directory
    mv ~{contigsFasta} localContigs

    # run main MitoHiFi using parameters
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
    firstCoord=$(grep "tRNA-Phe" $assembledMitoGFF | head -n 1 | awk '{print $4}')
    secondCoord=$(grep -B 2 "tRNA-Phe" ~{chrMRefGenbank} | head -n 1 | tr -s '.' | cut -d"." -f2)
    numRotation=$(expr $firstCoord + $secondCoord)

    # rotate mitogenome by number of bases and location of tRNA-Phe
    python ./scripts/rotate.py \
      -i $assembledMitoFasta \
      -r $numRotation > ~{mitoOut}
  >>>
  #specify the output(s) of this task so cromwell will keep track of them
  output {
    File outFile = glob("*.chrM.fa")[0]
  }
  runtime {
    docker: dockerImage
    memory: RAM + "GB"
    cpus: threadCount
  }
}
