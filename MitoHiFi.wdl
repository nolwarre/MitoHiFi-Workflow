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
    File reads
    File ref_fasta
    File ref_genbank
    Int organism_code
    String docker_image
    Int RAM = 2
    Int threadCount = 1
  }

  #define command to execute when this task runs
  command <<<
    cd /usr/src/MitoHiFi/exampleFiles/
    
    /usr/src/MitoHiFi/exampleFiles/run_MitoHiFi.sh \
    -c ~{reads} \
    -f ~{ref_fasta} \
    -g ~{ref_genbank} \
    -t ~{threadCount} \
    -o ~{organism_code}

    second_coord=$(grep -B 2 "tRNA-Phe" ~{ref_genbank} | head -n 1 | tr -s '.' | cut -d"." -f2)
    grep "tRNA-Phe" /usr/src/MitoHiFi/exampleFiles/mitogenome.annotation/mitogenome.annotation_MitoFinder_mitfi_Final_Results/mitogenome.annotation_mtDNA_contig.gff | head -n 1 > first
    first_coord=$(awk '{print $4}' $first)
    num_rotation = $first_coord + $second_coord

    python /usr/src/MitoHiFi/exampleFiles/scripts/rotate.py \
    -i /usr/src/MitoHiFi/exampleFiles/mitogenome.annotation/mitogenome.annotation_MitoFinder_mitfi_Final_Results/mitogenome.annotation_mtDNA_contig.fasta \
    -r $num_rotation > mitogenome.rotated.fa
  >>>
  #specify the output(s) of this task so cromwell will keep track of them
  output {
    File outFile = "mitogenome.rotated.fa"
  }
  Int runtimeThreadcount = threadCount + 2
  runtime {
    docker: docker_image
    memory: RAM + "GB"
    cpus: runtimeThreadcount
  }
}
