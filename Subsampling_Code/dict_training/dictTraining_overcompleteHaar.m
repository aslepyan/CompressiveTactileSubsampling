% This file is for calculating the overcomplete haar wavelet dictionary
function dictTraining_overcompleteHaar()
crtpwd = pwd;
upperpwd = fileparts(crtpwd);

dictArr = struct('data',[],'patchDim',[]);

% dict params
patDim=[8,8];
numElemPatch=prod(patDim);
maxlevel = log2(numElemPatch);
numshifts = 30;

[h,~,~,~] = wfilters('haar'); 
D = [];
for i = 1:maxlevel
    for j = 1:numshifts
        W = WavMat(h, numElemPatch, i, j);
        D = [D, W'];
    end
end

D = normc(D)';
coherence = D*D' - eye(max(size(D)));
% any repeating columns?
max(max(coherence)) %yes,

coherenceT = triu(coherence);
[v,h] = find(coherenceT>=1); %repeating column
u = unique(v);
D = D(setdiff(1:length(D(:,1)),u),:);

% any repeating columns?
max(max(D*D' - eye(max(size(D)))))

D=D';
dict_size=size(D,2);

% store dict and its params
dictArr.data=D;
dictArr.patchDim=patDim;

% show the haar wavelet dictionary
figure;
dictimg = showdict(D,[8,8],round(sqrt(dict_size)),round(sqrt(dict_size)),'lines','highcontrast');
imagesc(dictimg);
folder = '..\..\paperFig\figS_otherDict\';
filePath = fullfile(folder, 'Haar.fig');
saveas(gcf, filePath);

% save trained dict
trainDataFolder = 'traningData';
dictFileName = 'dictionary_haar.mat';
dictPath = fullfile(upperpwd, trainDataFolder, dictFileName);
save(dictPath, "dictArr");
