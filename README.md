<div align="center">

# Adaptive Compressive Tactile Subsampling: Enabling High Spatiotemporal Resolution in Scalable Robotic Skin

[[Paper](https://arxiv.org/abs/2410.13847)]

[Ariel Slepyan](https://scholar.google.com/citations?hl=en&user=8uVwi4UAAAAJ&view_op=list_works&sortby=pubdate)<sup>1</sup>†, 
[Dian Li (李典)](https://scholar.google.com/citations?view_op=list_works&hl=en&user=L_5PIfgAAAAJ)<sup>2</sup>†, 
[Aidan Aug]()<sup>2</sup>, 
[Sriramana Sankar]()<sup>2</sup>, 
[Trac Tran]()<sup>1</sup>, 
[Nitish Thakor](https://scholar.google.com/citations?user=SB_7Bi0AAAAJ&hl=en)<sup>1,2,3</sup>
<br />
<sup>1</sup> Department of Electrical and Computer Engineering, Johns Hopkins University, Baltimore, USA<br />
<sup>2</sup> Department of Biomedical Engineering, Johns Hopkins School of Medicine, Baltimore, USA<br />
<sup>3</sup> Department of Neurology, Johns Hopkins School of Medicine, Baltimore, USA<br />
†These authors contributed equally to this study.
</div>

## Usage
The codes for using our methods for tactile image data and realizing our results are explained below. Notice that you can access our data files through this 
[link](https://livejohnshopkins-my.sharepoint.com/:f:/g/personal/aslepya1_jh_edu/EjxrHBfSJDROho7Z2A9AB-YBlOvvXvdET3gtHFjB1QXo9g?e=V1dY6P). 
Some helper functions are not described here, but you can check the comments about their usage in the corresponding files. <br />
The folder `ksvdbox13` for training ksvd dictionary could be downloaded [here](https://csaws.cs.technion.ac.il/~ronrubin/software.html). This folder should be placed at `code\`.

### Data folders
Download each data folder and put it into the directory `data\`. Each data folder is explained below.
* `Subsampling_Data` is the folder for the data folders of the 30 daily objects;
* `Projectile_Data` is the data folder for the application of detecting the bouncing tennis ball (the projectile);
* `Deformation_Data` is the data folder for the application of detecting deformable objects;
* `Rotator_Data` is the data folder for the application of the rotator;
* `insole_data` is the data folder for the demo of the insole;
* `ricochet_angle_data` is the data folder for the demo of determining the angles of incidence of ricochet.

### Hardware
The PCB design files are located in the `PCB` folder. These files are designed in KiCAD and contain the schematic and layout for readout board (`PCB Files Readout Board`) and the 32x32 tactile sensor array (`PCB Files Tactile Sensor Array`).

### Subsampled Data Acquisition
If you want to collect some tactile data in a subsampling manner, use the folder `code\basics\`. To sample tactile data, upload `Subsampling.ino` to the sensor after adjusting the parameters. After that, run `SubsamplingControl.m` with desirable parameters to sample data using various methods.
* `Subsampling` contains the Arduino code used to enable the sensor to execute subsampling tactile data within a designated duration; The sampling process is initiated by touching;
* `Subsampling1` contains the Arduino code used to enable the sensor to execute subsampling tactile data within a designated duration; The sampling process is initiated by the `Enter` key;
* `SubsamplingControl.m` is the main function for subsampling in three different modes: regular, random, and binary;
* `downSamplingShift.m`, `randomSampling.m` and `binarySampling.m` are functions for regular, random and binary sampling methods, respectively; The sampling process is initiated by touching;
* `randomSampling1.m` and `binarySampling1.m` are functions for random and binary sampling methods, respectively; The sampling process is initiated by the `Enter` key;
* `SubsamplingDisplay.m` is used to visualize the subsampled tactile image;
* `downSamOrd.m` visulizes consecutive shifting down-sampling patterns;
* `binSamOrd` simulates and determines the order of binary sampling, given a number of sensors and a simple press image (where non-zero presses exist);
* `binSamOrd.m` visulizes a binary sampling pattern determined by params in `binSamOrd`;
* `M_fs_plot.m` plots the relation between the sampling rate and the measurement level;
* `forceR.m` determines the relationship between the force applied to the sensor and its measurement/resistance;
* `time_force.m` makes time-force plot.

### Training Data Collection
If you want to obtain training data, use the folder `code\dict_training\`. Run the section in `trainData.m` according to the training image you need. You can also run the last section to visualize the full raster training image you collected.
* `trainData.m` is responsible for collecting the training data and it also enables you to see the tactile image you collected.

### Tactile Dictionary Training
The folder `code\dict_training\` is also for the task of training dictionary, it allows to train three types of dictionary: learned dictionary, DCT dictionary and Haar dictionary (square and overcomplete). You can acquire all types of dictionaries by running the following MATLAB files. If you want to recover subsampled images as a whole,  run `dictCombine.m` to get the assembled dictionaries for the whole subsampled images.
* `dictTraining_ksvd.m` is for training the learned dictionary based on your training data;
* `dictTraining_DCT.m` is used to train the DCT dictionary;
* `dictTraining_Haar.m` is used to train the square Haar dictionary (i.e. the number of patch measurements equals to the dictionary size);
* `dictTraining_overcompleteHaar.m` is used to train the Haar dictionary with the desired dictionary size;
* `dictCombine.m` combines several patch dictionaries together to recover subsampled tactile images as a whole.

### Subsampled Image Recovery
The folder `code\reconstruction` is for the reconstruction of collected subsampled tactile data. First, recover the subsampled data using various methods (dictionaries or interpolation) by running the following MATLAB files. Then, you can check the reconstructed images using the file `recDataDisplay.m`. Last, run `reconAccPlot.m` to calculate the accuracies of the reconstructed images and plot some relevant figures shown in the paper.
* `dictRecovery1.m` is used to reconstruct the tactile image patch by patch by using various types of dictionaries;
* `dictRecovery2.m` is used to reconstruct the tactile image as a whole by using various types of dictionaries;
* `interpRecovery1.m` is used to reconstruct the tactile image by using linear interpolation;
* `recDataDisplay.m` is used to view the reconstructed subsampled image;
* `reconAccPlot.m` is used to calculate the accuracies of the reconstructed images and plot some relevant figures. Here, the objects used to do the subsampling have also been used to train the learned dictionary for subsampled image recovery.

### Subsampled Image Classification
The folder `code\classification` is for the classification of collected subsampled tactile data. Firstly, run `libTraining.m` to acquire the library for SRC. Then, run each section of `SRC.m` to conduct SRC, calculate accuracies or realize some figures in the paper. Besides, the code for the visualization of the library is also provided. Here, the objects used for subsampling have also been used to form the library for subsampled image classification.
* `libTraining.m` is used to construct a library for SRC;
* `libVis.m` visualizes the library;
* `SRC.m` is used to determine the classes the reconstructed images belong to, calculate the accuracies of the classification of different sampling modes and measurement levels, as well as plot some relevant figures.

### Real-time Full Raster Scan
The folder `code\realTimeFR\` is to visualize a real-time full raster scan of the sensor. First, upload `realTimeFR_32x32.ino` and then run `realTimeFR_32x32.m`.

## Applications
With the proposed sampling modes, reconstruction using a learned dictionary, and SRC, we have designed and conducted several experiments to investigate their feasibility and accuracy. Here, we explain the folders for these experiments.

### Projectile
The folder `code\projectile` is for the application of fast detection of a tennis ball (as a projectile) onto the sensor. Firstly, you can directly use our data, or you need to collect the tactile images of the bouncing tennis ball by using the file `SubsamplingControl.m` with the binary subsampling mode. Then, run each section of `projectileAnalysis.m` to process the projectile's subsampled data and plot the figures shown in the paper.
* The file `projectileAnalysis.m` analyzes the projectile's subsampled data and generates some figures.

### Deformation
The folder `code\deform` is for the application of roughly drawing the shape of deformable objects. Firstly, you can directly use our data, or you need to collect the tactile images of some deformable objects (e.g. deflated balloon or elastic objects) by using the file `SubsamplingControl.m` with the binary subsampling mode. Then, run each section of `deformAnalysis.m` to process the subsampled data of those deformable objects and draw their rough shape, as shown in the paper.
* The file `deformAnalysis.m` analyzes the subsampled data of deformable objects and generates a figure depicting their approximate shapes.

### Real-time Reconstruction and Classification
The folder `code\realTime` is for the application of real-time reconstruction or classification without any data processing outside the sensor.<br />
To realize the real-time reconstruction, firstly, you need to have a reasonably learned dictionary using the K-SVD method. After adjusting some parameters, you need to upload the `realTimeBinaryReconPBP.ino` to the sensor. Then, run the `helperMat.m` and `dict2Arduino_recon.m` to transfer the dictionary and its helper matrices to the sensor. Finally, you can visualize the real-time tactile images by using `realTimeVis.m`.<br />
For its simulation, you need to upload the file named `realTimeBinaryReconPBP.ino` and determine the accuracy by using the `realTimeSimu.m`, while all the remaining operations are the same as the real-time reconstruction.<br />
As for the real-time classification, first of all, you need get the library through `libTraining.m` as mentioned above. After adjusting some parameters, upload the `realTimeBinarySRC.ino` to the sensor. Then, run the `dict2Arduino_class.m` to transfer the library to the sensor. Last, visualize the real-time classification through the serial monitor in the Arduino.

* `realTimeBinaryReconPBP` contains the Arduino code to enable the sensor to sample the tactile data in real time by using the binary subsampling method, and to reconstruct the subsampled image by a learned dictionary patch by patch;
* `realTimeBinaryReconPBPSimu` contains the Arduino code to enable the sensor to sample and reconstruct the full raster tactile data, which has been sampled and stored. This simulation aims to determine the accuracy of the real-time reconstruction method by a learned dictionary patch by patch;
* `realTimeBinarySRC` contains the Arduino code to enable the sensor to sample the tactile data in real time using the binary subsampling method, and to classify the subsampled tactile image using the SRC method;
* `realTimeBinarySRCSimu` contains the Arduino code to enable the sensor to sample and classify the full raster tactile data, which has been sampled and stored. This simulation aims to determine the accuracy of the real-time classification by SRC;
* `dict2Arduino_recon.m` is used to transfer a learned dictionary and its corresponding helper matrices from MATLAB to the sensor;
* `dict2Arduino_class.m` is used to transfer a library used in the SRC from MATLAB to the sensor;
* `helperMat.m` is used to determine and store the helper matrices according to the learned dictionary which will be used in the real-time reconstruction later;
* `realTimeVis.m` is used to visualize the real-time reconstruction;
* `realTimeReconSimu.m` is used to determine the accuracy of reconstruction of full-raster tactile images in the simulation;
* `realTimeSRCSimu.m` is used to determine the accuracy of classification of full-raster tactile images in the simulation;
* `realTimePlot.m` is used to plot all relevant figures related to this application. 

### Rotator
The folder `code\rotator` is for the application of fast detection of the pressure of a hard rotator on the sensor in varied frequencies. Firstly, you can directly use our data, or you need to collect the tactile images of hard rotator by using the file `SubsamplingControl.m` with the binary subsampling mode. Then, run each section of `rot.m` to process the subsampled data of the rotator and plot the single-sided amplitude spectrums shown in the paper.
* The file `rot.m` analyzes the subsampled data of the rotator at different speeds (or frequencies) and generates the single-sided amplitude spectrums.

### Ricochet Angle
The folder `code\instant_angle` is for the demo of tracking the instant angle of incidence of a bouncing ball. You can directly run the file `instant_angle.m` to see the animation for tracking.
* `instant_angle.m` is the main code for this demo;
* `com.m` is a helper function that calculates the center of mass (COM) of the bouncing object;
* `nameTransfer.m` is a helper function that converts the names for visualization.

### Insole
The folder `code\insole` is for the demo of tactile images from an insole. You can check the subsampled and reconstructed images via `insoleVis.m`.

### Generalizability
The folder `code\reconstruction` is also for the application of reconstruction of collected subsampled tactile data from objects that are not used to train a learned dictionary. Firstly, collect some subsampled tactile images of your daily objects (e.g. keys or toothbrushes) by using the file `SubsamplingControl.m` explained above. Then, with the trained dictionary, recover the subsampled images using the above file `dictRecovery1.m`. Last, run `genReconAccPlot.m` to calculate the accuracies of the reconstructed images and plot some relevant figures shown in the paper. To prove the generalizability of our methods, the objects used to do the subsampling have NOT been used to train the learned dictionary for subsampled image recovery. Notice that the code responsible for the reconstruction of subsampled images allows the reconstruction of simulated images, which are raw subsampled images with horizontal or vertical locomotion.
* The file `genReconAccPlot.m` calculates the accuracies of the reconstructed images and plots some relevant figures.

## Citation
```
    @article{,
      author    = {Ariel Slepyan and Dian Li and Aidan Aug and Sriramana Sankar and Trac Tran and Nitish Thakor},
      title     = {Adaptive Subsampling and Learned Model Improve Spatiotemporal Resolution of Tactile Skin},
      journal   = {arXiv preprint arXiv:2410.13847},
      year      = {2024},
      url       = {https://arxiv.org/abs/2410.13847}
    }
```

## Acknowledgement
We sincerely appreciate Becca Greene, Prof. Jeremias Sulam and Prof. Jeremy Brown for their advice on this work. We also many many thanks Dr. Ron Rubinstein for his code for training the ksvd dictionary.

## Contact
If you have any questions or inquiries, please feel free to contact this [email](mailto:dli106@jhmi.edu).
