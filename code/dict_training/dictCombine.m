% This file is for the combination of the patch dictionary for
% reconstruction of tactile image as a whole
crtpwd = pwd;
upperpwd = fileparts(crtpwd);

% load the patch dictionary, !!
load(fullfile(upperpwd, 'traningData\dictionary_haar.mat'))

nR=32; % num of row, !!
nC=32; % num of col, !!
numSensor = nR*nC;
idxHelper = reshape(1:numSensor,[nR,nC]);
repeatCount = zeros(numSensor,1);
Psi = zeros(numSensor,1000000);
kk=1;
nPat = numel(dictArr);
% patch step size for each patch case, !!
patchStepSizeArr = [8,8;
    2,2;
    2,2;];

for iPat=1%1:nPat % !!
    patchULCoord = [1,1]; % patch upper left coordinate
    patchLength = dictArr(iPat).patchDim;
    patchStepSize = patchStepSizeArr(iPat,:);
    dictSize = size(dictArr(iPat).data,2);
    while(patchULCoord(1)+patchLength(1)-1<=nR)
        Psi1 = zeros(numSensor,dictSize);

        patchLRCoord = patchULCoord+patchLength-1;

        % temp stores the corresponding indices of the current patch
        temp = idxHelper(patchULCoord(1):patchLRCoord(1),patchULCoord(2):patchLRCoord(2));
        temp=temp(:);

        for k2 = 1:numel(temp)
            Psi1(temp(k2),:) = dictArr(iPat).data(k2,:);
            repeatCount(temp(k2))=repeatCount(temp(k2))+1;
        end
        LL=kk:kk+dictSize-1;
        Psi(:,LL)=Psi1; % col first
        kk=kk+dictSize;

        patchULCoord(2) = patchULCoord(2)+patchStepSize(2);
        if (patchULCoord(2)+patchLength(2)-1>nC)
            patchULCoord(2) = 1;
            patchULCoord(1) = patchULCoord(1)+patchStepSize(1);
        end
    end
end

Psi = Psi(:,1:kk-1);
% Psi = Psi./repeatCount;
% Psi = Psi./vecnorm(Psi);
figure;
imagesc(Psi);

% save trained dict
trainDataFolder = 'traningData';
dictFileName = 'dictionary1.mat'; % !!
dictPath = fullfile(upperpwd, trainDataFolder, dictFileName);
save(dictPath, "Psi",'-v7.3');
