% This file is for calculating the learned ksvd dictionary; can be multiscale
crtpwd = pwd;
upperpwd = fileparts(crtpwd);

% load ksvdbox and ompbox.
ksvdFolderName = 'ksvdbox13';
ompFolderName = 'ompbox10';
dictPath = fullfile(upperpwd, ksvdFolderName);
addpath(dictPath);
dictPath = fullfile(upperpwd, ksvdFolderName, ompFolderName);
addpath(dictPath);

% load the training data, !!
load(fullfile(upperpwd, 'traningData\traningData_balloon.mat'))
% load(fullfile(upperpwd, 'traningData\traningData_foot.mat'))

% param
nR=32; % num of row, !!
nC=32; % num of col, !!
% num of (entire) frame per object for training, !!
n1 = size(savedTrainData(2).data,2);

% dim (or size) of patch, !!
patDim = [4,4;
    8,8;
    16,16;];
nPat = size(patDim,1);
% ratio of possiable loactions of patches for taking to train dict
ratioPat = [0.2,1,1]; % !!
% thr for num of non-zero elems per patch
thrNNZ = [10,20,60]; % !!
% max num of train data for each type of patch (or dict)
maxNumTrain = [60000,60000,60000]; % !!
spasityRatioArr = [0.2,0.2,0.2]; % !!
dictSizeArr = [100,1000,100]; % !!
iterNumArr = [10,10,10]; % !!

dictArr(nPat) = struct('data',[],'err',[],'patchDim',[]);

figure('Position', [50, 300, 1800, 500])
for iPat=2%1:nPat % !!
    numElemPatch = prod(patDim(iPat,:));

    % for storage of patch img data for training; colomn 1st indexing
    patchData = zeros(numElemPatch,maxNumTrain(iPat));
    k=1;

    for dataNameIdx=2%21:30%1:numObject % !!
        savedFullRasterData = savedTrainData(dataNameIdx).data;
        numFrameTotal = size(savedFullRasterData,2);
        if n1>numFrameTotal
            error(['num of frame for the object ', savedTrainData(dataNameIdx).name,' are too small']);
        end

        for i=1:n1 % !!
            im = savedFullRasterData(:,i);
            im = reshape(im,[nR,nC])'; % !! transpose?
            im = fliplr(im);
            % imagesc(im); axis equal;

            % imshow(im/1023)
            patchRange = size(im)-patDim(iPat,:)+1;
            numPatchTot = prod(patchRange);
            numPatchFrame = round(ratioPat(iPat)*numPatchTot);

            patchPosArr = randperm(numPatchTot,numPatchFrame);

            for ii=1:numPatchFrame
                rr = mod(patchPosArr(ii),patchRange(1))+patchRange(1)*(mod(patchPosArr(ii),patchRange(1))==0);
                cc = ceil(patchPosArr(ii)/patchRange(1));
                patchULCoord = [rr,cc]; % patch upper left coordinate
                patchLRCoord = patchULCoord+patDim(iPat,:)-1; % patch lower right coordinate

                temp = im(patchULCoord(1):patchLRCoord(1),patchULCoord(2):patchLRCoord(2));

                if nnz(temp)>thrNNZ(iPat)
                    patchData(:,k) = temp(:);
                    k=k+1;
                end
                if k>maxNumTrain(iPat)
                    break;
                end
            end
            if k>maxNumTrain(iPat)
                break;
            end
        end
    end

    % training data post-processing
    patchData = patchData(:,1:k-1);
    patchData = patchData./vecnorm(patchData); % normalize each col of the matrix

    % dict training param
    params.data = patchData;
    params.Tdata = round(spasityRatioArr(iPat)*numElemPatch); % sparsity for training
    params.dictsize = dictSizeArr(iPat); % size of dictionary
    params.iternum = iterNumArr(iPat); % iter for training

    % dict training
    disp('start training...');
    [Dksvd,Gamma,err] = ksvd(params,'');
    disp('finish!');

    % str the trained results
    dictArr(iPat).data = Dksvd;
    dictArr(iPat).spaCoding = Gamma;
    dictArr(iPat).err = err(end);
    dictArr(iPat).patchDim = patDim(iPat,:);

    % visualization of trained dict
    subplot(1,nPat,iPat)
    dictimg = showdict(Dksvd,patDim(iPat,:),round(sqrt(params.dictsize)),round(sqrt(params.dictsize)),'lines');
    imagesc(dictimg)
    colorbar;
    colormap gray;
    axis equal;
    title(sprintf('Patch dim: %dx%d | Dict size: %d',patDim(iPat,1),patDim(iPat,2),dictSizeArr(iPat)));
end
sgtitle(sprintf('Learned dictionaries'));

% save trained dict
trainDataFolder = 'traningData';
dictFileName = 'dictionary_balloon.mat'; % !!
dictPath = fullfile(upperpwd, trainDataFolder, dictFileName);
save(dictPath, "dictArr");
