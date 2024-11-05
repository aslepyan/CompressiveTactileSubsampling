% This file is for calculating the DCT dictionary
function dictTraining_DCT()
addpath ..\ksvdbox13\
crtpwd = pwd;
upperpwd = fileparts(crtpwd);

dictArr = struct('data',[],'patchDim',[]);

% dict params
patDim=[8,8];
numElemPatch = prod(patDim);
dict_size=1000;

% calculate dict
% Psi = dct(eye(numElemPatch));
Psi=odctdict(numElemPatch,dict_size);

% store dict and its params
dictArr.data=Psi;
dictArr.patchDim=patDim;

% show the haar wavelet dictionary
figure;
dictimg = showdict(Psi,patDim,round(sqrt(dict_size)),round(sqrt(dict_size)),'lines','highcontrast');
imagesc(dictimg);
folder = '..\..\paperFig\figS_otherDict\';
filePath = fullfile(folder, 'DCT.fig');
saveas(gcf, filePath);

% save trained dict
trainDataFolder = 'traningData';
dictFileName = 'dictionary_DCT.mat';
dictPath = fullfile(upperpwd, trainDataFolder, dictFileName);
save(dictPath, "dictArr");
