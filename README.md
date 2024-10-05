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
Note: you will need to contact the authors to get permission to access our data files.

## Subsampled Data Acquisition
If you want to collect some tactile data in a subsampling manner, use the folder `Subsampling_Code\Subsampling_Basics\`.
* `SubsamplingControl.m` is the main function for subsampling in three different modes: regular, random and binary.
* `SubsamplingDisplay.m` is used to visualize the subsampled tactile image.
* `downSamplingShift.m`, `randomSampling.m` and `binarySampling.m` are functions for regular, random and binary sampling methods, respectively.

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
* `reconAccPlot` is used to calculate the accuracies of the reconstructed images and plot some relevant figures.

## Subsampled Image Classification
The folder `classification` is for the classification of collected subsampled tactile data.
* `SRC.m` is used to determine the classes the reconstructed images belong to, calculate the accuracies of the classification of different methods and sampling modes, as well as plot some relevant figures.

# Applications
## Generalizability
* `genReconAccPlot.m` is used to

## Projectile


## Deformation


## Real-time Reconstruction/Classification


## Rotation


# References




