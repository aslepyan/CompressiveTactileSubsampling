<div align="center">

# Adaptive Compressive Tactile Subsampling: Enabling High Spatiotemporal Resolution in Scalable Robotic Skin

[[Paper](https://arxiv.org/abs/2410.13847)]

[Ariel Slepyan](https://scholar.google.com/citations?hl=en&user=8uVwi4UAAAAJ&view_op=list_works&sortby=pubdate)<sup>1</sup>†, 
[Dian Li (李典)](https://scholar.google.com/citations?view_op=list_works&hl=en&user=L_5PIfgAAAAJ)<sup>2</sup>†, 
[Aidan Aug](https://www.researchgate.net/profile/Aidan_Aug)<sup>2</sup>, 
[Sriramana Sankar](https://scholar.google.com/citations?user=SCZ0ibcAAAAJ&hl=en)<sup>2</sup>, 
[Trac Tran](https://scholar.google.com/citations?user=RyRjA0cAAAAJ&hl=en)<sup>1</sup>, 
[Nitish Thakor](https://scholar.google.com/citations?user=SB_7Bi0AAAAJ&hl=en)<sup>1,2,3</sup>
<br />
<sup>1</sup> Department of Electrical and Computer Engineering, Johns Hopkins University, Baltimore, USA<br />
<sup>2</sup> Department of Biomedical Engineering, Johns Hopkins School of Medicine, Baltimore, USA<br />
<sup>3</sup> Department of Neurology, Johns Hopkins School of Medicine, Baltimore, USA<br />
†These authors contributed equally to this study.
</div>

## Usage
The codes for using our methods for tactile image data and realizing our results are explained below. Notice that you can access our data files through this 
[link](https://livejohnshopkins-my.sharepoint.com/:f:/g/personal/aslepya1_jh_edu/EjxrHBfSJDROho7Z2A9AB-YBggjp6DtikdrMtPDEytMRLw?e=0MTquj). 
Some helper functions are not described here, but you can check the comments about their usage in the corresponding files. <br />
The folder `ksvdbox13` for training ksvd dictionary could be downloaded [here](https://csaws.cs.technion.ac.il/~ronrubin/software.html). This folder should be placed at `code\`.

### Data folders
Download each data folder and put it into the directory `data\`. Each data folder is explained below.
* `Subsampling_Data` is for 30 daily objects;
* `Projectile_Data` is for the application of detecting a bouncing tennis ball;
* `ricochet_angle_data` stores data of a bouncing tennis ball with specific incidence angles.
* `Deformation_Data` is for the application of detecting deformable objects;
* `manikin_data` stores data for slashing, shooting, and punching a manikin;
* `robot_data` stores data for slashing and pulling a UR5 robot arm;
* `insole_data` is for recording jumping;
* `arm_data` is for tapping on an arm;
* `chest_data` is for touching a chest;
* `helmet_data` is for the impact of foam bullet on a helmet;
* `leg_data` is for bouncing a ball on a leg;
* `glove_data` is for catching and throwing a tennis ball with a hand worn by a glove;
* `Rotator_Data` is for the application of the rotator;
* `Demo_Data` stores data for the video demonstration;
* `archieveData` is used to store useful data files for subsequent data analysis, such as accuracy determination of reconstruction and sparse representation classification (SRC);
* `traningData` is used to store various dictionaries and their auxiliary data, training data sets, and an SRC library.

### Hardware
The PCB design files are located in the `PCB` folder. These files are designed in KiCAD and contain the schematic and layout for readout board (`PCB Files Readout Board`) and the 32x32 tactile sensor array (`PCB Files Tactile Sensor Array`).

### Subsampled Data Acquisition
If you want to collect some tactile data in a subsampling manner, use the folder `code\data_collection\`. To sample tactile data, upload `Subsampling.ino` to the sensor after adjusting the parameters. After that, run `SubsamplingControl.m` with desirable parameters to sample data using various methods.
* `Subsampling` contains the Arduino code used to enable the sensor to execute subsampling tactile data within a designated duration; The sampling process is initiated by touching;
* `Subsampling1` contains the Arduino code used to enable the sensor to execute subsampling tactile data within a designated duration; The sampling process is initiated by the `Enter` key;
* `SubsamplingControl.m` is the main function for subsampling in three different modes: regular, random, and binary;
* `downSamplingShift.m`, `randomSampling.m` and `binarySampling.m` are functions for regular, random, and binary sampling methods, respectively; The sampling process is initiated by touching;
* `randomSampling1.m` and `binarySampling1.m` are functions for random and binary sampling methods, respectively; The sampling process is initiated by the `Enter` key;
* `SubsamplingDisplay.m` is used to visualize the subsampled tactile image;
* `M_fs_plot.m` plots the relation between the sampling rate and the measurement level;
* `time_force.m` makes a time-force plot.

### Tactile Dictionary Training
The folder `code\dict_training\` is for the task of training dictionary, it allows to train three types of dictionary: learned dictionary, DCT dictionary and Haar dictionary (square and overcomplete). You can acquire all types of dictionaries by running the following corresponding files. If you want to recover subsampled images as a whole,  run `dictCombine.m` to get the assembled dictionaries for the whole subsampled images.
* `trainData.m` is responsible for collecting the training data and its last section is to visualize the full raster tactile image you collected.
* `dictTraining_ksvd.m` is for training the learned dictionary based on your training data;
* `dictTraining_DCT.m` is used to train the DCT dictionary;
* `dictTraining_overcompleteHaar.m` is used to train the Haar dictionary;
* `dictCombine.m` combines several patch dictionaries together to recover subsampled tactile images as a whole.

### Subsampled Image Recovery
The folder `code\reconstruction` is for the reconstruction of collected subsampled tactile data. First, recover the subsampled data using various methods (dictionaries or interpolation) by running the following MATLAB files. Then, you can check the reconstructed images using the file `recDataDisplay.m`. Last, run `reconAccPlot.m` to calculate the accuracies of the reconstructed images and plot some relevant figures shown in the paper.
* `dictRecovery.m` is used to reconstruct the tactile image patch by patch by using various types of dictionaries;
* `interpRecovery.m` is used to reconstruct the tactile image by using linear interpolation;
* `recDataDisplay.m` is used to view the reconstructed subsampled image;
* `reconAccPlot.m` is used to calculate the accuracies of the reconstructed images and plot some relevant figures. Here, the objects used to do the subsampling have also been used to train the learned dictionary for subsampled image recovery.

### Subsampled Image Classification
The folder `code\classification` is for the classification of collected subsampled tactile data. Firstly, run `libTraining.m` to acquire the library for SRC. Then, run each section of `SRC.m` to conduct SRC, calculate accuracies or realize some figures in the paper. Besides, the code for the visualization of the library is also provided. Here, the objects used for subsampling have also been used to form the library for subsampled image classification.
* `libTraining.m` is used to construct a library for SRC and visualize the library;
* `SRC.m` is used to determine the classes the reconstructed images belong to, calculate the accuracies of the classification of different sampling modes and measurement levels, and plot some relevant figures.

### Real-time Full Raster Scan
The folder `code\realTimeFR\` is to visualize a real-time full raster scan of the sensor. First, upload `realTimeFR_32x32.ino` and then run `realTimeFR_32x32.m`.

## Applications
With the proposed sampling modes, reconstruction using a learned dictionary, and SRC, we have designed and conducted several experiments to investigate their feasibility and accuracy. Here, we explain the folders and files for these experiments.

### Projectile
The folder `code\projectile` is for the application of fast detection of a tennis ball (as a projectile) onto the sensor. Firstly, you can directly use our data, or you need to collect the tactile images of the bouncing tennis ball by using the file `SubsamplingControl.m` with the binary subsampling mode. Then, run each section of `projectileAnalysis.m` and `instant_angle.m` to process the projectile's subsampled data and plot the figures shown in the paper.
* `projectileAnalysis.m` analyzes the projectile's subsampled data and generates some figures;
* `instant_angle.m` is the main code for this demo of tracking the instant angle of incidence of a bouncing ball.

### Deformation
The folder `code\deform` is for the application of roughly drawing the shape of deformable objects. Firstly, you can directly use our data, or you need to collect the tactile images of some deformable objects (e.g. deflated balloon or elastic objects) by using the file `SubsamplingControl.m` with the binary subsampling mode. Then, run each section of `deformAnalysis.m` to process the subsampled data of those deformable objects and draw their rough shape, as shown in the paper.
* `deformAnalysis.m` analyzes the subsampled data of deformable objects and generates a figure depicting their approximate shapes.

### Full-Body Tactile Sensing
* `code\reconstruction\recDataDisplay.m` could also be used to check the subsampled and reconstructed tactile data collected from insole, chest, helmet, glove, leg, and arm.

### Real-time Reconstruction and Classification
The folder `code\realTime` is for the application of real-time reconstruction or classification without any data processing outside the sensor.<br />
To realize the real-time reconstruction, firstly, you need to have a reasonably learned dictionary using the K-SVD method. After adjusting some parameters, you need to upload the `realTimeBinaryReconPBP.ino` to the sensor. Then, run the `helperMat.m` and `dict2Arduino_recon.m` to transfer the dictionary and its helper matrices to the sensor. Finally, you can visualize the real-time tactile images by using `realTimeVis.m`.<br />
For its simulation, you need to upload the file named `realTimeBinaryReconPBP.ino` and determine the accuracy by using the `realTimeSimu.m`, while all the remaining operations are the same as the real-time reconstruction.<br />
As for the real-time classification, first of all, you need get the library through `libTraining.m` as mentioned above. After adjusting some parameters, upload the `realTimeBinarySRC.ino` to the sensor. Then, run the `dict2Arduino_class.m` to transfer the library to the sensor. Last, visualize the real-time classification through the serial monitor in the Arduino.
* `realTimeBinaryReconPBP` contains the Arduino code to enable the sensor to sample the tactile data in real-time by using the binary subsampling method, and to reconstruct the subsampled image by a learned dictionary patch by patch;
* `realTimeBinaryReconPBPSimu` contains the Arduino code to enable the sensor to sample and reconstruct the full raster tactile data, which has been sampled and stored. This simulation aims to determine the accuracy of the real-time reconstruction method by a learned dictionary patch by patch;
* `realTimeBinarySRC` contains the Arduino code to enable the sensor to sample the tactile data in real-time using the binary subsampling method, and to classify the subsampled tactile image using the SRC method;
* `realTimeBinarySRCSimu` contains the Arduino code to enable the sensor to sample and classify the full raster tactile data, which has been sampled and stored. This simulation aims to determine the accuracy of the real-time classification by SRC;
* `dict2Arduino_recon.m` is used to transfer a learned dictionary and its corresponding helper matrices from MATLAB to the sensor;
* `dict2Arduino_class.m` is used to transfer a library used in the SRC from MATLAB to the sensor;
* `helperMat.m` is used to determine and store the helper matrices according to the learned dictionary which will be used in the real-time reconstruction later;
* `realTimeVis.m` is used to visualize the real-time reconstruction;
* `realTimeReconSimu.m` is used to determine the accuracy of reconstruction of full-raster tactile images in the simulation;
* `realTimeSRCSimu.m` is used to determine the accuracy of classification of full-raster tactile images in the simulation;
* `realTimePlot.m` is used to plot all relevant figures related to this application. 

## Supplements
The folder `code\supplements` contains the file that generates some results shown in the supplementary file.
* `rot.m` analyzes the subsampled data of a hard rotator at different speeds (or frequencies) and generates the single-sided amplitude spectrums.
* `forceR.m` determines the relationship between the force applied to the sensor and its measurement/resistance;
* `downSamOrd.m` visualizes consecutive shifting down-sampling patterns;
* `binSamOrd` simulates and determines the order of binary sampling, given a number of sensors and a simple press image (where non-zero presses exist);
* `binSamOrd.m` visualizes a binary sampling pattern determined by params in `binSamOrd`;
* `genReconAccPlot.m` calculates the accuracies of the reconstructed images from objects that are not used to train a learned dictionary and plots some relevant figures shown in the paper.

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
We sincerely appreciate Prof. Jeremy Brown for his advice on this work. We also many many thanks Dr. Ron Rubinstein for his code for training the ksvd dictionary.

## Contact
If you have any questions or inquiries, please feel free to contact this [email](mailto:dli106@jhmi.edu).
