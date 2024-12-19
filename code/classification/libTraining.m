% This file is for constructing a library used for SRC of subsampled
% tactile images.
clear

% load the training data
load('..\..\data\traningData\traningData.mat') % !! make sure the training data is correct

numTrainObj = 1; % num of training data (or columns in lib) per object, !!
numSensor = 1024;

% initialize the 'library'
lib = zeros(numSensor,numTrainObj*numObject);
libSize = size(lib,2);

% build the 'library', 'identity library'
for idxObject=1:numObject
    temp=savedTrainData(idxObject).data;
    L = (idxObject-1)*numTrainObj+1:idxObject*numTrainObj;
    lib(:,L)=temp(:,1:numTrainObj);
end

% normalize each column of the 'library'
normTheta=zeros(1,libSize);
for k=1:libSize
    normTheta(k) = norm(lib(:,k));
    lib(:,k) = lib(:,k)/normTheta(k);
end

% save trained lib
Psi=lib;
trainDataFolder = 'traningData';
dictFileName = 'lib.mat';
dictPath = fullfile('..\..\data\traningData', dictFileName);
save(dictPath, "Psi", "numTrainObj", "libSize"); % !!

%% Visualize the 'library'
load("..\..\data\traningData\lib.mat");

figure;
for k=1:libSize % !!!
    img=reshape(Psi(:,k),[32,32])';
    imagesc(img);
    title(sprintf('Column No. %d|Object No. %d',k,ceil(k/numTrainObj)));
    pause(0.1)
    drawnow;
end
