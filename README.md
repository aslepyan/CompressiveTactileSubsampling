<div align="center">

# Compressive Subsampling Improves Spatiotemporal Resolution of Tactile Skin through Embedded Software

[[Paper]()]

[Dian Li](), [Ariel Slapyan]()<br />
Johns Hopkins University

</div>

> Here, we use the dictionary method to recover the subsampled tactile image. And do some applications such as real-time, projectile. The method shows good result.

<div align="center">
    <img src="assets/overview.png" width="2000">
</div>

---
# Principle

# Usage

Notes:
1. you will need to contact the authors to get permission to access our data files.
2. Some helper functions are not explained here, but you can check the comments about their usage in the corresponding files;
3. 

## Subsampled Data Acquisition
If you want to collect some tactile data in a subsampling manner, use the folder `Subsampling_Code\Subsampling_Basics\`.
* `SubsamplingControl.m` is the main function for subsampling in three different modes: regular, random and binary.
* `SubsamplingDisplay.m` is used to visualize the subsampled tactile image.
* `downSamplingShift.m`, `randomSampling.m` and `binarySampling.m` are functions for regular, random and binary sampling methods, respectively.
* `Subsampling` contains the Arduino code used to enable the sensor to execute subsampling tactile data within a designated duration.

## Training Data Collection
If you want to obtain training data, use the folder `Subsampling_Code\dict_training\`.
* `trainData.m` is responsible for collecting the training data and it also enables you to see the tactile image you collected.

## Tactile Dictionary Training
The folder `Subsampling_Code\dict_training\` is also for the task of training dictionary, it allows to train three types of dictionary: learned dictionary, DCT dictionary and Haar dictionary (square and overcomplete).
* `dictTraining_ksvd.m` is for training the learned dictionary based on your training data.
* `dictTraining_DCT.m` is used to train the DCT dictionary.
* `dictTraining_Haar.m` is used to train the square Haar dictionary (i.e. the number of patch measurements equals to the dictionary size).
* `dictTraining_overcompleteHaar.m` is used to train the Haar dictionary with the desired dictionary size.
* `dictCombine.m` combines several patch dictionaries together to recover subsampled tactile images as a whole.

## Subsampled Image Recovery
The folder `Subsampling_Code\reconstruction` is for the reconstruction of collected subsampled tactile data.
* `dictRecovery1.m` is used to reconstruct the tactile image patch by patch by using various types of dictionaries.
* `dictRecovery2.m` is used to reconstruct the tactile image as a whole by using various types of dictionaries.
* `interpRecovery1.m` is used to reconstruct the tactile image by using linear interpolation.
* `recDataDisplay.m` is used to view the reconstructed subsampled image.
* `reconAccPlot.m` is used to calculate the accuracies of the reconstructed images and plot some relevant figures. Here, the objects used to do the subsampling have also been used to train the learned dictionary for subsampled image recovery.

## Subsampled Image Classification
The folder `Subsampling_Code\classification` is for the classification of collected subsampled tactile data. Here, the objects used to do the subsampling have also been used to form the library for subsampled image classification.
* `SRC.m` is used to determine the classes the reconstructed images belong to, calculate the accuracies of the classification of different methods and sampling modes, as well as plot some relevant figures.

# Applications
With the proposed sampling modes, reconstruction by using a learned dictionary, and SRC, we have designed and conducted several experiments to investigate the feasibility and accuracy of those methods.

## Generalizability
The folder `Subsampling_Code\reconstruction` is also for the application of reconstruction of collected subsampled tactile data from objects which are not used to train a learned dictionary.
* The file `genReconAccPlot.m` is used to calculate the accuracies of the reconstructed images and plot some relevant figures. Here, the objects used to do the subsampling have also been used to train the learned dictionary for subsampled image recovery.

## Projectile
The folder `Subsampling_Code\projectile` is for the application of fast detection of a tennis ball (as a projectile) onto the sensor.
* The file `projectileAnalysis.m` analyzes the projectile's subsampled data and generates some figures.

## Deformation
The folder `Subsampling_Code\deform` is for the application of roughly drawing the shape of deformable objects.
* The file `deformAnalysis` analyzes the subsampled data of deformable objects and generates a figure depicting their approximate shapes.

## Real-time Reconstruction and Classification
The folder `Subsampling_Code\realTime` is for the application of real-time reconstruction or classification without any data processing outside the sensor (e.g. MATLAB).<br />
To realize this the real-time reconstruction, firstly, the user is expected to have a reasonable learned dictionary using K-SVD method. After adjusting some parameters, the user needs to upload the `realTimeBinaryReconPBP.ino` to the sensor. Then, they run the `helperMat.m` and `dict2Arduino_recon.m` to transfer the dictionary and its helper matrices to the sensor. Finally, the user can visualize the real-time tactile images by using `realTimeVis.m`.<br />
For its simulation, the user needs to upload the file named `realTimeBinaryReconPBP.ino` and determine the accuracy by using the `realTimeSimu.m`, while all the remaining operations are the same as the real-time reconstruction.<br />
As for the real-time classification, first of all, the user is required to get the library (a matrix with the flattened full-raster images as its columns) through `SRC.m` as mentioned above. After adjusting some parameters, the user needs to upload the `realTimeBinarySRC.ino` to the sensor. Then, they run the `dict2Arduino_class.m` to transfer the library to the sensor. Last, they can visualize the real-time classification through the serial monitor in the Arduino.

* `realTimeBinaryReconPBP` contains the Arduino code to enable the sensor to sample the tactile data in real-time by using the binary subsampling method, and to reconstruct the subsampled image by a learned dictionary patch by patch.
* `realTimeBinaryReconPBPSimu` contains the Arduino code to enable the sensor to sample and reconstruct the full raster tactile data, which has been sampled and stored. This simulation aims to determine the accuracy of the real-time reconstruction method by a learned dictionary patch by patch.
* `realTimeBinarySRC` contains the Arduino code to enable the sensor to sample the tactile data in real-time using the binary subsampling method, and to classify the subsampled tactile image using the SRC method.
* `dict2Arduino_recon.m` is used to transfer a learned dictionary and its corresponding helper matrices from MATLAB to the sensor.
* `dict2Arduino_class.m` is used to transfer a library used in the SRC from MATLAB to the sensor.
* `helperMat.m` is used to determine and store the helper matrices according to the learned dictionary which will be used in the real-time reconstruction later.
* `realTimeVis.m` is used to visualize the real-time reconstruction.
* `realTimeSimu.m` is used to determine the accuracy of reconstruction of full-raster tactile images in the simulation.
* `realTimePlot.m` is used to plot some relevant figures related to this application. 

## Rotation
The folder `Subsampling_Code\rotator` is for the application of fast detection of the pressure of a hard rotator on the sensor in varied frequencies.
* The file `rot.m` analyzes the subsampled data of the rotator at different speeds (or frequencies) and generates a figure showing the single-sided amplitude spectrums.

# References




