% This file is for determing the helper matrices ("indHelper", "indHelper1"
% and "repeatCount") for the real-time reconstruction according to the
% recovery style of patch dictionary.
clear; close all; clc;

crtpwd = pwd;
upperpwd = fileparts(crtpwd);

dictFileName = 'dictionary1.mat'; % !!
dictPath = fullfile('..\..\data\traningData', dictFileName);
load(dictPath);

nR=32; % num of row, !!
nC=32; % num of col, !!
numSensor = nR*nC;
idxHelper = reshape(1:numSensor,[nC,nR])';
repeatCount = zeros(numSensor,1);
Psi = zeros(numSensor,100000);
kk=1;
nPat = numel(dictArr);
% patch step size for each patch case, !!
patchStepSizeArr = [2,2;
    4,4;
    2,2;];

indConv = 65*ones(1024,200);
indConv1 = zeros(64,200);
jj=1;

for iPat=2%1:nPat % !!
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
            indConv(temp(k2),jj)=k2;
            indConv1(k2,jj)=temp(k2);
        end
        LL=kk:kk+dictSize-1;
        Psi(:,LL)=Psi1;
        kk=kk+dictSize;

        patchULCoord(2) = patchULCoord(2)+patchStepSize(2);
        if (patchULCoord(2)+patchLength(2)-1>nC)
            patchULCoord(2) = 1;
            patchULCoord(1) = patchULCoord(1)+patchStepSize(1);
        end
        jj=jj+1;
    end
end

indConv=indConv(:,1:jj-1); % 1-64
indConv=indConv-1; % 0-63
indConv1=indConv1(:,1:jj-1); % 1-1024
indConv1=indConv1-1; % 0-1023

% save the helper matrices "indConv", "indConv1" and "repeatCount"
dictFileName = 'dictHelperMat.mat'; % !!
dictPath = fullfile('..\..\data\traningData', dictFileName);
save(dictPath, "indConv", "indConv1", "repeatCount");
