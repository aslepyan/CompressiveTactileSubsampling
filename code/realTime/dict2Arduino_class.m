% This file is for sending the values of library into the arduino file for
% the task of real-time classification.
% Note: plz first upload the arduino code to the sensor.
clear; close all; clc;

crtpwd = pwd;
upperpwd = fileparts(crtpwd);

% load the library
fullpath = fullfile(upperpwd, 'traningData', 'lib.mat');
disp('The library is loading...');
load(fullpath)
disp('The library is loaded successfully!');

% process the library
thrDict=1e-2; % !!
Psi(abs(Psi)<thrDict)=0;

% connect the arduino and upload the data
clear s;
port = serialportlist;
s = serialport(port(1),12E6);
flush(s);
write(s, reshape(Psi', 1, []), 'single');
clear s;

fprintf("\nUpload successfully!\nThe library size is %d.\n",size(Psi,2));
