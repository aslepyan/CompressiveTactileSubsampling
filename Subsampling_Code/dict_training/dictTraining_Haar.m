% This file is for calculating the square haar wavelet dictionary
function dictTraining_Haar()
crtpwd = pwd;
upperpwd = fileparts(crtpwd);

dictArr = struct('data',[],'patchDim',[]);

% dict params
patDim=[8,8];
numElemPatch = prod(patDim);

% calculate dict
[h,~,~,~] = wfilters('haar'); W = WavMat(h, numElemPatch); W=W';

% store dict and its params
dictArr.data=W;
dictArr.patchDim=patDim;

% show the haar wavelet dictionary
figure;
dictimg = showdict(W,patDim,round(sqrt(numElemPatch)),round(sqrt(numElemPatch)),'lines','highcontrast');
imagesc(dictimg);
folder = '..\..\paperFig\figS_Haar\';
filePath = fullfile(folder, 'Haar.fig');
saveas(gcf, filePath);

% save trained dict
trainDataFolder = 'traningData';
dictFileName = 'dictionary_haar.mat';
dictPath = fullfile(upperpwd, trainDataFolder, dictFileName);
save(dictPath, "dictArr");
