% This file is for sending the values of dictionary and its corresponding
% auxiliary matrices into the arduino file for the task of real-time
% reconstruction.
% Note: plz first upload the arduino code to the sensor.
clear; close all; clc;

crtpwd = pwd;
upperpwd = fileparts(crtpwd);

% load dictionary
fullpath_dict = fullfile(upperpwd, 'traningData', 'dictionary1.mat');
fullpath_mat = fullfile(upperpwd, 'traningData', 'dictHelperMat.mat');
disp('The dictionary and its auxiliary matrices are loading...');
load(fullpath_dict)
load(fullpath_mat)
disp('The dictionary and its auxiliary matrices are loaded successfully!');

% extract and process the dictionary
Psi=dictArr(2).data; % !!
thrDict=1e-2; % !!
Psi(abs(Psi)<thrDict)=0;

% connect the arduino and upload the data
clear s;
port = serialportlist;
s = serialport(port,12E6);
flush(s);
write(s, reshape(Psi', 1, []), 'single');
write(s, reshape(indConv', 1, []), 'uint8');
write(s, reshape(indConv1', 1, []), 'uint16');
write(s, reshape(repeatCount, 1, []), 'uint8');
clear s;

fprintf("\nUpload successfully!\nThe patch dictionary size is %d.\n",size(Psi,2));
