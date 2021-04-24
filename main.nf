#!/usr/bin/env nextflow
/*
========================================================================================
XCMS test workflow
========================================================================================
Analysis Pipeline doing XCMS mass trace detection.
----------------------------------------------------------------------------------------
*/

// Get mzML files
mzMLFiles=Channel.fromPath("/crex/proj/uppmax2021-2-3/metabolomics/mzMLData/*.mzML")

// Define a process process that does mass trace detection (files are run in parallel)
process process_masstrace_detection_pos_xcms{
  // Label the process
  label 'xcms'
  // Give name to the process showing what is running
  tag "$mzMLFile"
  // Define the output directory (results will be put here). $projectDir is main directory of the project
  publishDir "$projectDir/process_masstrace_detection_pos_xcms_noncentroided"
  // Input channel from the mzML files
  input:
  // It's a file type channel
  file mzMLFile from mzMLFiles
  // We create two output channel because process_collect_rdata_pos_xcms process needs an input from this process and  process_align_peaks_pos_xcms process needs another input from this process
  output:
  // Both of the channels are file type and they container the processed input file ".rdata" and the original files ".mzML"
  file "${mzMLFile.baseName}.rdata" into collect_rdata_pos_xcms
  file "${mzMLFile.baseName}.mzML" into rt_rdata_pos_xcms

  // Here we run the bash command (the command in this case is in a container)
  // I guess you realized that there is a backslash in front of $PWD. That is telling the nextflow that this specific variable ($PWD) is a bash environment variable not the groovy one!
  """
  /usr/bin/findPeaks.r input=\$PWD/$mzMLFile output=\$PWD/${mzMLFile.baseName}.rdata ppm=5 peakwidthLow=5 peakwidthHigh=10 \\
  noise=1000 polarity=positive realFileName=$mzMLFile sampleClass=sample
  """
}

// Define a process process that combines all the processed mzML files into a single Rdata file
process  process_collect_rdata_pos_xcms{
  label 'xcms'
  tag "A collection of files"
  publishDir "$projectDir/process_collect_rdata_pos_xcms"

  // A "normal" file channel emmits each file at the time but here we need all the files in one place (not one by one).
  // So we use .collect so all the files are emitted as list (not in parallel)
  input:
  file rdata_files from collect_rdata_pos_xcms.collect()
  // We only output only one file that is called "collection_pos"
  output:
  file "collection_pos.rdata" into align_rdata_pos_xcms

  // Our script in the bash section "/usr/local/bin/xcmsCollect.r" requires all the files to be concatenated and joint by comma. So here we just join the elements in the list by commma
  script:
  def inputs_aggregated = rdata_files.join(",")
  """
  nextFlowDIR=\$PWD
  /usr/bin/xcmsCollect.r input=$inputs_aggregated output=collection_pos.rdata
  """
}

// a process to fix the retention time drift
process  process_align_peaks_pos_xcms{
  label 'xcms'
  tag "$rdata_files"
  publishDir "$projectDir/process_align_peaks_pos_xcms"

  input:
  file rdata_files from align_rdata_pos_xcms
  file rd from rt_rdata_pos_xcms.collect()
  output:
  file "RTcorrected_pos.rdata" into group_peaks_pos_N1_xcms
  script:
  def inputs_aggregated = rd.join(",")
  """
  /usr/bin/retCor.r input=\$PWD/$rdata_files output=RTcorrected_pos.rdata method=obiwarp

  """
}

// a process to group the peaks (linking)
process  process_group_peaks_pos_N1_xcms{
  label 'xcms'
  tag "$rdata_files"
  publishDir "$projectDir/process_group_peaks_pos_N1_xcms"

  input:
  file rdata_files from group_peaks_pos_N1_xcms

  output:
  file "groupN1_pos.rdata" into finished

  """
  /usr/bin/group.r input=$rdata_files output=groupN1_pos.rdata bandwidth=3  mzwid=5
  """
}
