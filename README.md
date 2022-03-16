
# Nextflow lab


# Set up the environment

You need to do this every time you start the lap…

First ssh to Uppmax

```bash
ssh -AX youusername@rackham.uppmax.uu.se
```

Make a directory in your userspace

```bash
mkdir -p /crex/proj/uppmax2022-2-10/nobackup/$USER/nextflow_lab
```

Navigate to the folder you have created

```bash
cd /crex/proj/uppmax2022-2-10/nobackup/$USER/nextflow_lab
```

Load Nexflow

```bash
module load bioinfo-tools
```

```bash
module load Nextflow/20.10.0
```

Fix some environmental variables:

```
export NXF_SINGULARITY_CACHEDIR=/crex/proj/uppmax2022-2-10/metabolomics/singularity
```

You are now ready to start!

**The container for both of the following parts is “metaboigniter/course_docker:v5” and we want to use SLURM to run the jobs. **

**IMPORTANT: DO NOT remove, change, add anything here and in its subfolders: ** /crex/proj/uppmax2022-2-10/metabolomics


# For part 1, you should send us the modified main.nf and nextflow.config. For part 2, you will have to send us a main.nf, nextflow.config and a PCA plot!


# Part 1

In this part, we will run a small pipeline together. The pipeline is already in a folder that you need to copy to your personal space. We assume that you are now in “nextflow_lab”

Copy the pipeline and the configuration file

```bash
cp -r /crex/proj/uppmax20212-2-10/metabolomics/xcms_pipeline .
```

Now you have all the required files in your folder. Try to run the pipeline

```bash
cd xcms_pipeline 
```

```bash
nextflow main.nf -profile uppmax --project "uppmax2021-2-3" --clusterOptions "-M snowy"
```

You can open another terminal window and ssh to Uppmax and use jobinfo to see whether your jobs are running or not! If you realized that won’t run for some steps, it might be because of RAM, CPU, or running time. In the nextflow.config, I have commented out the memory, CPU, and time requirement of the processes. You can uncomment them!

Please remember that there is a high chance that Uppmax becomes very slow because the jobs are heavy. So Please consider canceling your jobs if you already know and have a feeling about how Uppmax runs your jobs

```bash
scancel -u $USER -M snowy
```


*   Exercise one: There are some hardcoded parameters part of the pipeline:
    *   If process process_masstrace_detection_pos_xcms we have the following parameters:

        peakwidthLow=5


        peakwidthHigh=10


        noise=1000


        polarity=positive


**Can you change the config file so the value of these parameters is set there and fetched here? How can the user pass these parameters to the pipeline? Show the command!**

Tip: Your task is to modify the config file (nextflow.config) so that for example **peakwidthLow=5** can be replaced by **peakwidthLow=$params.peakwidthLow **and** **the value of **peakwidthLow** is set in the config file!

Help me: [params scope](https://www.nextflow.io/docs/latest/config.html#scope-params)


# Part 2

As talked before the pipeline in the part 1 does mass spectrometry data pre-processing using XCMS software suite. In this part of the exercise, you will need to build a pipeline from scratch that does the same thing using OpenMS. You can of course use the pipeline in part 1 as a template and try to modify it to do that. 


## Assignment 1 (Build an OpenMS pipeline)

This is what you need to do



1. You will need an input channel that read *.mzML **files** from “/crex/proj/uppmax2021-2-3/metabolomics/mzMLData”
2. Since the process in this specific pipeline need a separate parameter file you will need three additional **file** channels
    1. The first one is used in the feature detection process and is located here: “/crex/proj/uppmax2021-2-3/metabolomics/openms_params/FeatureFinder.ini”
    2. The second one is for the alignment process and is located here: “/crex/proj/uppmax2021-2-3/metabolomics/openms_params/featureAlignment.ini”
    3. The third one is for the linker process and is located here: “/crex/proj/uppmax2021-2-3/metabolomics/openms_params/featureLinker.ini”

_Help me: [File channels](https://www.nextflow.io/docs/latest/process.html#input-of-files), [How to create file channels](https://www.nextflow.io/docs/latest/channel.html#frompath)_

Now that we have our channels up and running, time to create four processes:



1. Let’s name the first process “process_masstrace_detection_pos_OpenMS”
    1. This process has two inputs:
        1. The first input is from the mzML files
        2. The second one is from** **the** feature detection** parameter file. Please remember that The second input should be a type of input that repeats for **each** of the mzML file emitted by the first channel
    2. The output for this process has the same **baseName **as input but it has “.featureXML” extension. The name of the output channel must be alignmentProcess
    3. And finally, the command needed to run is 

FeatureFinderMetabo -in inputVariable -out inputBaseName.featureXML -ini settingFIleVariable

Please note that you need to change inputVariable, inputBaseName and settingFIleVariable! Please also note that the inputs to this tool are given by -in, the outputs by -out and settings by -ini.

Help me: [processes](https://www.nextflow.io/docs/latest/process.html), [input each (file)](https://www.nextflow.io/docs/latest/process.html#input-repeaters), [bash command](https://www.nextflow.io/docs/latest/process.html#script)



2. The second process is called “process_masstrace_alignment_pos_OpenMS”
    4. Similar to the previous process it will get two inputs:
        3. The first one is the output of “process_masstrace_detection_pos_OpenMS”
        4. The second one is from the alignment parameter file. Similar to the previous one this input is also repeating!
    5. The output for this process has the same baseName as input but it has “.featureXML” extension. However, these files are in a different folder (let’s call it “out”). The output channel must be named LinkerProcess
    6. The command needed is a bit different from the previous one:

This command accepts ALL the mzML files at **the same time** (look at collect!) and outputs the same number of files. The inputs must be separated by space (remember the join operation?). The output is the same as input however you need to put the output in a different folder within the process! Think about a simple bash script. You create a folder and join the files in a way that they are written in a separate folder!  

Given three samples, x.mzML, y.mzML and z.mzML, an example of the command is like

mkdir out

MapAlignerPoseClustering -in x.mzML y.mzML z.mzML -out out/x.mzML out/y.mzML out/z.mzML -ini setting.ini

**Please remember the code above is just an example of a command you run in bash You will have to implement this using Nextflow!**

Please also note that the inputs to this tool are given by -in, the outputs by -out and settings by -ini.

Finally, this process needs quite a bit of RAM to go forward. Set the memory for this to probably around 10 GB or even more!

Help me: [collect](https://www.nextflow.io/docs/latest/operator.html#collect), [joining in the process!](https://groups.google.com/g/nextflow/c/V7kKJzyZs98), [memory](https://www.nextflow.io/docs/latest/process.html#memory)



3. The third process is called process_masstrace_linker_pos_OpenMS and is used to link (merge) multiple files into a single file
    7. It will get two inputs:
        5. The output from the alignment
        6. The parameter file
    8. The output of this process is a single file and must be named “Aggregated.consensusXML” it will be sent over to a channel called “textExport”
    9. And the command:

    This is similar to the previous step. You need to gather all the inputs separated by space (collect and join!). However, it will only output one file. Given the same three files above an example of the command would be:


FeatureLinkerUnlabeledQT -in x.mzML y.mzML z.mzML -out Aggregated.consensusXML -ini setting.ini

Please also note that the inputs to this tool are given by -in, the outputs by -out and settings by -ini.

Finally, this process needs quite a bit of RAM to go forward. Set the memory for this to probably around 10 GB or even more!



4. Finally the last step which takes the xml formatted output from the previous step and convert it into a csv file. Let’s call this process “process_masstrace_exporter_pos_OpenMS”
    10. The input to the process is the output from the previous step
    11. The output is a single file and must be called “Aggregated_clean.csv” and sent over to a channel called “out”
    12. To run the command: This process will run two commands the first one does the conversion and the second one the cleaning. We will only need the last output (Aggregated_clean.csv)

TextExporter -in input -consensus:features Aggregated.csv

/usr/bin/readOpenMS.r input=Aggregated.csv output=Aggregated_clean.csv

Please also note that the inputs to this tool are given by -in, the outputs by -consensus:features.

Remember that this process should publish its result to a specific directory (your choice). It does that by symlink! Change the mode to copy if you want!

Help me: [publish the results](https://www.nextflow.io/docs/latest/process.html#publishdir)


## Assignment 2

Given the output from the last step of the pipeline, do a PCA on the data. The output of the last step is a csv file (comma separated) and the first column is the header. The missing values are designated by NA. 


## Assignment 3 (optional, gives extra points)

Can you add your script (PCA) as an extra node part of the pipeline? You don’t have to use containers, you can use conda or whatever you like! There are R and Python already available in the container, you can also use [conda](https://www.nextflow.io/docs/latest/process.html#conda) or [modules](https://www.nextflow.io/docs/latest/process.html#module)

If you don’t know what PCA is or how to do it, please let us know!


## Assignment 4 (optional but with a reward!)

One of the major problems with these pipelines is that when you run them, they will go from start to end! However, there are some tricks that you can think of to “pause” the pipeline. Why do we want to do that? Because some steps generate some data that is going to the next step and the parameters for the next step have to be tuned with respect to the incoming data. It would be cool to pause the pipeline, tune the parameters and go forward. You can think about a bash script continuously checking a single or even one of the channels (watchPath) that check for the files. This means the pipeline pauses and checks for a file to be modified to be available and then continues! Try to play around! You don’t have to do that. Ping us if you need more hints!

**IMPORTANT: some time Uppmax file system might cause some of the processes to fail, if this happens, rerun the workflow with -resume option. This might actually pass the step that was previously shown as failed!**

**If you encounter issues with Uppmax being way too slow or does not do anything, please let up know!**
