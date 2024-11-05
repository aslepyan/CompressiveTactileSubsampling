%% dict training (no patch)
close all;
% clear;
clc;

crtpwd = pwd;

% load the training full image data
load(fullfile(pwd, 'traningData\traningData.mat'))

% load ksvdbox and ompbox.
ksvdFolderName = 'ksvdbox13';
ompFolderName = 'ompbox10';
dictPath = fullfile(crtpwd, ksvdFolderName);
addpath(dictPath);
dictPath = fullfile(crtpwd, ksvdFolderName, ompFolderName);
addpath(dictPath);

% total num of sensors
numSensor = 1024;

% num of (entire) frame per object for training
n1 = 10; % !!!

totalNumFrame = numObject*n1;
trainData = zeros(numSensor,totalNumFrame); % for storage of patch img data; colomn 1st indexing
k=1;

for dataNameIdx=20:30%1:numObject % !!
    savedFullRasterData = savedTrainData(dataNameIdx).data;
    numFrameTotal = size(savedFullRasterData,2);
    if n1>numFrameTotal
        error(['num of frame for the object ', savedTrainData(dataNameIdx).name,' are too small']);
    end

    for i=1:n1
        trainData(:,k)=savedFullRasterData(:,i);
        k=k+1;
    end
end

% dict training param
params.data = trainData;
params.Tdata = 10; % desired sparsity, !!!
params.dictsize = 100; % size of dictionary, !!!
tic
% dict training
disp('start training...');
[Dksvd,g,err] = ksvd(params,''); %Dksvd is dictionary by ksvd
disp('finish!');
toc
Psi=Dksvd;

% visualization of trained dict
dictimg = showdict(Psi,[32 32],round(sqrt(params.dictsize)),round(sqrt(params.dictsize)),'lines','highcontrast');
imagesc(dictimg)
title('Learned dictionary')

% save trained dict
trainDataFolder = 'traningData';
dictFileName = 'dictionary1.mat';
dictPath = fullfile(crtpwd, trainDataFolder, dictFileName);
save(dictPath, "Psi", "params");

%% dict training (patch) new 8/28
close all;
% clear;
clc;

crtpwd = pwd;

% load the training full image data
load(fullfile(pwd, 'traningData\traningData.mat'))

% load ksvdbox and ompbox.
ksvdFolderName = 'ksvdbox13';
ompFolderName = 'ompbox10';
dictPath = fullfile(crtpwd, ksvdFolderName);
addpath(dictPath);
dictPath = fullfile(crtpwd, ksvdFolderName, ompFolderName);
addpath(dictPath);

% total num of sensors
numSensor = 1024;

% num of (entire) frame per object for training
n1 = 1; % !!!

% patch param
patchLength = 32; % assume that patch is a square !!!

% patchData - storage of patch for training
numElemPatch = patchLength^2;
patchRange = 32-patchLength+1;
numPatchTot = patchRange^2;
numPatchFrame = round(1*numPatchTot); % !!
totalNumPatch = numObject*n1*numPatchFrame;
patchData = zeros(numElemPatch,totalNumPatch); % for storage of patch img data; colomn 1st indexing
k=1;

for dataNameIdx=1:numObject
    savedFullRasterData = savedTrainData(dataNameIdx).data;
    numFrameTotal = size(savedFullRasterData,2);
    if n1>numFrameTotal
        error(['num of frame for the object ', savedTrainData(dataNameIdx).name,' are too small']);
    end

    for i=1:n1
        img = savedFullRasterData(:,i);
        img = reshape(img,[32,32])';

        patchPosArr = randperm(numPatchTot,numPatchFrame);

        for ii=1:numPatchFrame
            patchULCoord = [ceil(patchPosArr(ii)/patchRange), mod(patchPosArr(ii),patchRange)+patchRange*(mod(patchPosArr(ii),patchRange)==0)]; % patch upper left coordinate
            patchLRCoord = patchULCoord+patchLength-1; % patch lower right coordinate

            temp = img(patchULCoord(1):patchLRCoord(1),patchULCoord(2):patchLRCoord(2))';

            if nnz(temp)>10 % !!!
                patchData(:,k) = temp(:);
                k=k+1;
            end
        end
    end
end

patchData = patchData(:,1:k-1);
patchData = patchData./vecnorm(patchData); % normalize each col of the matrix
%
% dict training param
params.data = patchData;
params.Tdata = round(0.2*numElemPatch); % desired sparsity, !!!
params.dictsize = 30; % size of dictionary, !!!

% dict training
disp('start training...');
[Dksvd,g,err] = ksvd(params,''); %Dksvd is dictionary by ksvd
disp('finish!');

% visualization of trained dict
dictimg = showdict(Dksvd,[patchLength,patchLength],round(sqrt(params.dictsize)),round(sqrt(params.dictsize)),'lines','highcontrast');
imagesc(dictimg)
title('Learned dictionary')

%%
% process D to combine to be used
patchStepSize = [4,4]; % !!!
Psi = [];
patchULCoord = [1,1]; % patch upper left coordinate
idxHelper = reshape(1:numSensor,[32,32])';
repeatCount = zeros(numSensor,1);
while(patchULCoord(1)+patchLength(1)-1<=32)
    Psi1 = zeros(numSensor,params.dictsize);

    patchLRCoord = patchULCoord+patchLength-1;

    % temp stores the corresponding indices of the current patch
    temp = idxHelper(patchULCoord(1):patchLRCoord(1),patchULCoord(2):patchLRCoord(2))';
    temp=temp(:);

    for k2 = 1:numel(temp)
        Psi1(temp(k2),:) = Dksvd(k2,:);
        repeatCount(temp(k2))=repeatCount(temp(k2))+1;
    end
    Psi=[Psi,Psi1];

    patchULCoord(2) = patchULCoord(2)+patchStepSize(2);

    if (patchULCoord(2)+patchLength-1>32)
        patchULCoord(2) = 1;
        patchULCoord(1) = patchULCoord(1)+patchStepSize(1);
    end
end

% Psi = Psi./repeatCount;

% save trained dict
trainDataFolder = 'traningData';
dictFileName = 'dictionary.mat';
dictPath = fullfile(crtpwd, trainDataFolder, dictFileName);
save(dictPath, "Psi", "params");

%% no patch but translationally move training data (draft
close all;
% clear;
% clc;

crtpwd = pwd;

% load the training full image data
load(fullfile(pwd, 'traningData\traningData.mat'))

% load ksvdbox and ompbox.
ksvdFolderName = 'ksvdbox13';
ompFolderName = 'ompbox10';
dictPath = fullfile(crtpwd, ksvdFolderName);
addpath(dictPath);
dictPath = fullfile(crtpwd, ksvdFolderName, ompFolderName);
addpath(dictPath);

% total num of sensors
numSensor = 1024;

% num of (entire) frame per object for training
n1 = 1; % !!!

totalNumFrame = numObject*n1;
trainData = zeros(numSensor,totalNumFrame); % for storage of patch img data; colomn 1st indexing
k=1;

for dataNameIdx=1:numObject
    savedFullRasterData = savedTrainData(dataNameIdx).data;
    numFrameTotal = size(savedFullRasterData,2);
    if n1>numFrameTotal
        error(['num of frame for the object ', savedTrainData(dataNameIdx).name,' are too small']);
    end
    img=savedFullRasterData(:,1);
    img=reshape(img,[32,32])';

    for i=1:4
        for rr=1:32
            for jj=1:32
                trainData(:,k)=reshape(img',[],1);
                k=k+1;
                img=circshift(img,[0,1]);
            end
            img=circshift(img,[1,0]);
        end
        img=rot90(img);
    end
end

% dict training param
params.data = trainData;
params.Tdata = 10; % desired sparsity, !!!
params.dictsize = 5000; % size of dictionary, !!!
tic
% dict training
disp('start training...');
[Dksvd,g,err] = ksvd(params,''); %Dksvd is dictionary by ksvd
disp('finish!');
toc
Psi=Dksvd;

% visualization of trained dict
dictimg = showdict(Psi,[32 32],round(sqrt(params.dictsize)),round(sqrt(params.dictsize)),'lines','highcontrast');
imagesc(dictimg)
title('Learned dictionary')

% save trained dict
trainDataFolder = 'traningData';
dictFileName = 'dictionary.mat';
dictPath = fullfile(crtpwd, trainDataFolder, dictFileName);
save(dictPath, "Psi", "params");

%% dict training (patch)
close all;
clear;
clc;

crtpwd = pwd;

% load the training full image data
load(fullfile(pwd, 'traningData\traningData.mat'))

% load ksvdbox and ompbox.
ksvdFolderName = 'ksvdbox13';
ompFolderName = 'ompbox10';
dictPath = fullfile(crtpwd, ksvdFolderName);
addpath(dictPath);
dictPath = fullfile(crtpwd, ksvdFolderName, ompFolderName);
addpath(dictPath);

% total num of sensors
numSensor = 1024;

% num of (entire) frame per object for training
n1 = 100; % !!!

% patch param
patchLength = [8,8]; % !!!
patchStepSize = [4,4]; % !!!

% patchData - storage of patch for training
numElemPatch = patchLength(1)*patchLength(2);
numPatchFrame = ceil((32-patchLength(1)+1)/patchStepSize(1))*ceil((32-patchLength(2)+1)/patchStepSize(2));
totalNumPatch = numObject*n1*numPatchFrame;
patchData = zeros(numElemPatch,totalNumPatch); % for storage of patch img data; colomn 1st indexing
k=1;

for dataNameIdx=1:numObject
    savedFullRasterData = savedTrainData(dataNameIdx).data;
    numFrameTotal = size(savedFullRasterData,2);
    if n1>numFrameTotal
        error(['num of frame for the object ', savedTrainData(dataNameIdx).name,' are too small']);
    end

    for i=1:n1
        patchULCoord = [1,1]; % patch upper left coordinate

        img = savedFullRasterData(:,i);
        img = reshape(img,[32,32])';

        while(patchULCoord(1)+patchLength(1)-1<=32)
            patchLRCoord = patchULCoord+patchLength-1; % patch lower right coordinate

            temp = img(patchULCoord(1):patchLRCoord(1),patchULCoord(2):patchLRCoord(2))';

            if nnz(temp)>20 % !!!
                patchData(:,k) = temp(:);
                k=k+1;
            end

            patchULCoord(2) = patchULCoord(2)+patchStepSize(2);

            if (patchULCoord(2)+patchLength(2)-1>32)
                patchULCoord(2) = 1;
                patchULCoord(1) = patchULCoord(1)+patchStepSize(1);
            end
        end
    end
end

patchData = patchData(:,1:k-1);

% dict training param
params.data = patchData;
params.Tdata = 20; % desired sparsity, !!!
params.dictsize = 1000; % size of dictionary, !!!
tic
% dict training
disp('start training...');
[Dksvd,g,err] = ksvd(params,''); %Dksvd is dictionary by ksvd
disp('finish!');
toc
% visualization of trained dict
dictimg = showdict(Dksvd,patchLength,round(sqrt(params.dictsize)),round(sqrt(params.dictsize)),'lines','highcontrast');
imagesc(dictimg)
title('Learned dictionary')

% process D to combine to be used
Psi = [];
patchULCoord = [1,1]; % patch upper left coordinate
idxHelper = reshape(1:numSensor,[32,32])';
repeatCount = zeros(numSensor,1);
while(patchULCoord(1)+patchLength(1)-1<=32)
    Psi1 = zeros(numSensor,params.dictsize);

    patchLRCoord = patchULCoord+patchLength-1;

    % temp stores the corresponding indices of the current patch
    temp = idxHelper(patchULCoord(1):patchLRCoord(1),patchULCoord(2):patchLRCoord(2))';
    temp=temp(:);

    for k2 = 1:numel(temp)
        Psi1(temp(k2),:) = Dksvd(k2,:);
        repeatCount(temp(k2))=repeatCount(temp(k2))+1;
    end
    Psi=[Psi,Psi1];

    patchULCoord(2) = patchULCoord(2)+patchStepSize(2);

    if (patchULCoord(2)+patchLength(2)-1>32)
        patchULCoord(2) = 1;
        patchULCoord(1) = patchULCoord(1)+patchStepSize(1);
    end
end

Psi = Psi./repeatCount;

% save trained dict
trainDataFolder = 'traningData';
dictFileName = 'dictionary.mat';
dictPath = fullfile(crtpwd, trainDataFolder, dictFileName);
save(dictPath, "Psi", "params");
