%% test dct and haar and ksvd; test faces
close all
% clear
clc

crtpwd = pwd;

pathstr = fileparts(which('ksvdTestmy.m'));
dirname = fullfile(pathstr, 'ksvdbox13','images', '*');
imglist = dir(dirname);

imnum=3;
imgname = fullfile(pathstr, 'ksvdbox13','images', imglist(imnum).name);

im = imread(imgname);
im = im2gray(im);
im = double(im);
im = imresize(im,0.1);

figure
subplot(1,3,1)
imshow(im/255);

subplot(1,3,2)
deim=im;
deRatio = 0.9; % !!
deim(randperm(numel(deim),round(deRatio*numel(deim))))=0;
imshow(deim/255);

% patch method
lenImg = size(deim);
patchLength = [8,8];
numElemPatch = patchLength(1)*patchLength(2);
patchStepSize = [2,2]; % !!!
patchULCoord = [1,1]; % patch upper left coordinate
idxHelper = reshape(1:numel(deim),size(deim));
% [h,~,~,~] = wfilters('haar'); W = WavMat(h, numElemPatch); Psi=W;
% Psi = dct(eye(numElemPatch));
Psi = Dksvd;
recim1 = 0*deim;
repeatCount = 0*deim;

while(patchULCoord(1)+patchLength(1)-1<=lenImg(1))
    patchLRCoord = patchULCoord+patchLength-1;

    % temp stores the corresponding indices of the current patch
    temp = idxHelper(patchULCoord(1):patchLRCoord(1),patchULCoord(2):patchLRCoord(2));

    for kk=1:numel(temp)
        repeatCount(temp(kk))=repeatCount(temp(kk))+1;
    end

    patchImg=deim(temp);

    yvec=patchImg(patchImg~=0);
    Amat=zeros(numel(yvec),numElemPatch);
    ii=1;
    for kk=1:numElemPatch
        if patchImg(kk)==0
            continue;
        end
        Amat(ii,kk)=1;
        ii=ii+1;
    end

    sparsity = round(0.2*ii); % !!
    xs=FastOMP(Amat*Psi,yvec,sparsity);

    x=Psi*xs;

    recim1(temp)=recim1(temp)+reshape(x,[8,8]);

    patchULCoord(2) = patchULCoord(2)+patchStepSize(2);

    if (patchULCoord(2)+patchLength-1>lenImg(2))
        patchULCoord(2) = 1;
        patchULCoord(1) = patchULCoord(1)+patchStepSize(1);
    end
end

subplot(1,3,3)
recim1(isnan(recim1))=0;
recim1=recim1./repeatCount;

imshow(recim1/255);

%% training data for ksvd method; test faces
% sourses: https://faces.mpdl.mpg.de/imeji/
close all
clear
clc

crtpwd = pwd;
% load ksvdbox and ompbox.
ksvdFolderName = 'ksvdbox13';
ompFolderName = 'ompbox10';
dictPath = fullfile(crtpwd, ksvdFolderName);
addpath(dictPath);
dictPath = fullfile(crtpwd, ksvdFolderName, ompFolderName);
addpath(dictPath);


pathstr = fileparts(which('ksvdTestmy.m'));
dirname = fullfile(pathstr, 'ksvdbox13','images\faces', '*.jpg');
imglist = dir(dirname);
numImg = numel(imglist);

% patch param
patDim = [8,8]; % assume that patch is a square !!!

% patchData - storage of patch for training
numElemPatch = prod(patDim);
maxNumTrain = 11000;
patchData = zeros(numElemPatch,maxNumTrain); % for storage of patch img data; colomn 1st indexing
k=1;

for imnum = 1:numImg
    imgname = fullfile(pathstr, 'ksvdbox13','images\faces', imglist(imnum).name);

    im = imread(imgname);
    im = im2gray(im);
    im = double(im);
    im = imresize(im,0.1);

    % imshow(im/255)
    patchRange = size(im)-patDim+1;
    numPatchTot = prod(patchRange);
    numPatchFrame = round(0.02*numPatchTot); % !!

    patchPosArr = randperm(numPatchTot,numPatchFrame);

    for ii=1:numPatchFrame
        rr = mod(patchPosArr(ii),patchRange(1))+patchRange(1)*(mod(patchPosArr(ii),patchRange(1))==0);
        cc = ceil(patchPosArr(ii)/patchRange(1));
        patchULCoord = [rr,cc]; % patch upper left coordinate
        patchLRCoord = patchULCoord+patDim-1; % patch lower right coordinate

        temp = im(patchULCoord(1):patchLRCoord(1),patchULCoord(2):patchLRCoord(2));

        if nnz(temp)>0 && nnz(255-temp)>0 % !!!
            patchData(:,k) = temp(:);
            k=k+1;
        end
        if k>maxNumTrain
            break;
        end
    end
    if k>maxNumTrain
        break;
    end
end

patchData = patchData./vecnorm(patchData); % normalize each col of the matrix
%
% dict training param
params.data = patchData;
params.Tdata = round(0.1*numElemPatch); % desired sparsity, !!!
params.dictsize = 500; % size of dictionary, !!!

% dict training
disp('start training...');
[Dksvd,g,err] = ksvd(params,''); %Dksvd is dictionary by ksvd
disp('finish!');

% visualization of trained dict
dictimg = showdict(Dksvd,patDim,round(sqrt(params.dictsize)),round(sqrt(params.dictsize)),'lines','highcontrast');
imagesc(dictimg)
colormap gray;
title('Learned dictionary')

%% test dct and haar and ksvd; test tactile data, patch by patch (PBP) recovery
%%%%%%%%%%%%% basic param %%%%%%%%%%%%%
nR=64; % num of row, !!
nC=16; % num of col, !!
numSensor = nR*nC;
pressThreshold = 50; % !!

%%%%%%%%%%%%% original FR image %%%%%%%%%%%%%
iobj = 1; %!!
savedFullRasterData = savedTrainData(iobj).data;
im = savedFullRasterData(:,500); % !!
im = reshape(im,[nR,nC]); % transpose?, !!
% im = circshift(im,1,1); % !!, move the tactile image vertically
% im = circshift(im,10,2); % !!, move the tactile image horizontally
% im = flip(im); % !!, flip and rotate image
im = imresize(im,1); % !!, resize the tactile image

%%%%%%%%%%%%% random sampling simulation %%%%%%%%%%%%%
deim=im;
deRatio = 0.9; % !!
dePos = randperm(numel(deim),round(deRatio*numel(deim)));
deim(dePos)=-10;

%%%%%%%%%%%%% dict learning (patch by patch (PBP)) %%%%%%%%%%%%%
% patch params
lenImg = size(deim);
patchLength = [16,8]; % !!
numElemPatch = prod(patchLength);
patchStepSize = [1,1]; % !!
patchULCoord = [1,1]; % patch upper left coordinate
idxHelper = reshape(1:numel(deim),size(deim));
% [h,~,~,~] = wfilters('haar'); W = WavMat(h, numElemPatch); Psi=W;
% dct_basis = dct(eye(numElemPatch)); Psi=dct_basis;
Psi = dictArr(2).data; % !!
sparRat = 0.5; % !!
recim1 = 0*deim;
repeatCount = 0*deim;

while(patchULCoord(1)+patchLength(1)-1<=lenImg(1))
    patchLRCoord = patchULCoord+patchLength-1;

    % temp stores the corresponding indices of the current patch
    temp = idxHelper(patchULCoord(1):patchLRCoord(1),patchULCoord(2):patchLRCoord(2));

    for kk=1:numel(temp)
        repeatCount(temp(kk))=repeatCount(temp(kk))+1;
    end

    patchImg=deim(temp);

    yvec=patchImg(~(patchImg<0));
    Amat=zeros(numel(yvec),numElemPatch);
    ii=1;
    for kk=1:numElemPatch
        if patchImg(kk)<0
            continue;
        end
        Amat(ii,kk)=1;
        ii=ii+1;
    end

    sparsity = round(0.5*ii);
    xs=FastOMP(Amat*Psi,yvec,sparsity);

    x=Psi*xs;

    if (any(isnan(x)))
        error(sprintf('x has NaN value!'));
    end

    recim1(temp)=recim1(temp)+reshape(x,patchLength);

    patchULCoord(2) = patchULCoord(2)+patchStepSize(2);
    if (patchULCoord(2)+patchLength(2)-1>lenImg(2))
        patchULCoord(2) = 1;
        patchULCoord(1) = patchULCoord(1)+patchStepSize(1);
    end
end
recim1=recim1./repeatCount;
recim1(recim1<pressThreshold)=0;
recim1(recim1>1023)=1023;

supAcc1 = supportAcc(im,recim1,pressThreshold);
mae1 = immae(im,recim1);
mse1 = immse(im,recim1);

%%%%%%%%%%%%% linear interp %%%%%%%%%%%%%
recim2=zeros(nR,nC);
% initialize the interpolation method
myInterp = scatteredInterpolant;
myInterp.Method = 'linear';
myInterp.ExtrapolationMethod = 'linear';
msrNum = numSensor-numel(dePos);
% array for storage of coordinate of scattered data for
% interpolation
interpData = zeros(msrNum,2);
y = zeros(msrNum,1);
kk=1;

for k=1:numSensor
    if ~ismember(k,dePos)
        interpData(kk,1)=ceil(k/nR); % 1-nC
        interpData(kk,2)=mod(k,nR)+nR*(mod(k,nR)==0); % 1-nR
        y(kk)=deim(k)*(deim(k)>0);
        kk=kk+1;
    end
end

myInterp.Points=interpData;
myInterp.Values=y;

for i=1:nC
    for j=1:nR
        recim2(j,i)=myInterp(i,j);
    end
end

recim2(isnan(recim2))=0;
recim2(recim2<pressThreshold)=0;
recim2(recim2>1023)=1023;

supAcc2 = supportAcc(im,recim2,pressThreshold);
mae2 = immae(im,recim2);
mse2 = immse(im,recim2);

%%%%%%%%%%%%% visualization %%%%%%%%%%%%%
figure('Position', [500, 300, 600, 600])
valMin = -10; valMax = 1023;
cmap = colormap;
new_cmap = [0 0 0; cmap];
subplot(2,2,1)
imagesc(im); axis equal;
clim([valMin valMax]);

subplot(2,2,2)
imagesc(deim); axis equal;
clim([valMin valMax]);
colormap(new_cmap);

subplot(2,2,3)
imagesc(recim1); axis equal;
title(sprintf('dict learning\nsupport: %d\nMAE: %d\nMSE: %d',supAcc1,mae1,mse1));
clim([valMin valMax]);

subplot(2,2,4)
imagesc(recim2); axis equal;
title(sprintf('inear interp\nsupport: %d\nMAE: %d\nMSE: %d',supAcc2,mae2,mse2));
clim([valMin valMax]);

sgtitle(sprintf('M=%d',msrNum));

%% test dct and haar and ksvd; test tactile data, (dict as a whole)
% close all
% clear
% clc

numSensor = 1024;
pressThreshold = 50; % !!

iobj = 1; %!!
savedFullRasterData = savedTrainData(iobj).data;

im = savedFullRasterData(:,1); %!!
im = reshape(im,[32,32])';
% im = circshift(im,5,1); % !!, move the tactile image vertically
% im = circshift(im,5,2); % !!, move the tactile image horizontally
% im = flip(im); % !!, flip and rotate image
im = imresize(im,1); % !!, resize the tactile image

% imshow(im/1023)

figure('Position', [500, 300, 600, 600])
valMin = 0; valMax = 1023;
subplot(2,2,1)
imagesc(im);
clim([valMin valMax]);

subplot(2,2,2)
deim=im;
deRatio = 0.5; % !!
dePos = randperm(numel(deim),round(deRatio*numel(deim)));
deim(dePos)=-10;
imagesc(deim);
clim([valMin valMax]);

%%%%%%%%%%%% dict learning (patch) %%%%%%%%%%%%
tic
patchImg=deim;
yvec=patchImg(~(patchImg<0));
M=numel(yvec);
Amat=zeros(M,numSensor);
ii=1;
for kk=1:numSensor
    if patchImg(kk)<0
        continue;
    end
    Amat(ii,kk)=1;
    ii=ii+1;
end

sparsity = round(0.25*M); % !!
xs=FastOMP(Amat*Psi,yvec,sparsity);
x=Psi*xs;

recim1=reshape(x,size(deim));

recim1(recim1<=pressThreshold)=0;
recim1(recim1>1023)=1023;
toc
% psnr1 = psnr(recim1,im)+10*log10(max(im,[],'all')^2);
% psnrTest = 10*log10(1023^2/immse(im,recim1));
% disp(psnrTest);
subplot(2,2,3)
supAcc1 = supportAcc(im,recim1,pressThreshold);
mae1 = immae(im,recim1);
imagesc(recim1);
title(sprintf('dict learning|support: %d|\nMAE: %d',supAcc1,mae1));
clim([valMin valMax]);

%%%%%%%%%%%%%%%% linear interp %%%%%%%%%%%%%%%%
recim2=zeros(32);
% initialize the interpolation method
myInterp = scatteredInterpolant;
myInterp.Method = 'linear';
myInterp.ExtrapolationMethod = 'linear';
msrNum = 1024-numel(dePos);
% array for storage of coordinate of scattered data for
% interpolation
interpData = zeros(msrNum,2);
y = zeros(msrNum,1);
kk=1;

for k=1:1024
    if ~ismember(k,dePos)
        interpData(kk,1)=ceil(k/32); % 1-32
        interpData(kk,2)=mod(k,32)+32*(mod(k,32)==0); % 1-32
        y(kk)=deim(k)*(deim(k)>0);
        kk=kk+1;
    end
end

myInterp.Points=interpData;
myInterp.Values=y;

for i=1:32
    for j=1:32
        recim2(j,i)=myInterp(i,j);
    end
end

recim2(recim2<=pressThreshold)=0;
recim2(recim2>1023)=1023;
subplot(2,2,4)
% psnr2 = psnr(recim2,im)+10*log10(max(im,[],'all')^2);
supAcc2 = supportAcc(im,recim2,pressThreshold);
mae2 = immae(im,recim2);
imagesc(recim2);
title(sprintf('linear interp|support: %d|\nMAE: %d',supAcc2,mae2));
clim([valMin valMax]);

%% dict test
Dksvd=dictArr(iPat).data;
dictSize = dictSizeArr(iPat);
numTrain = size(patchData,2);

% update gamma
Gamma=zeros(dictSize,numTrain);
for kk=1:numTrain
    xs=FastOMP(Dksvd,patchData(:,kk),13);
    Gamma(:,kk)=xs;
end

% popularity of each dictionary atom
pop=sum(full(Gamma)>0.01,2);

% error of each training data
dataErr=vecnorm(patchData-Dksvd*full(Gamma));

% closeness
cloMat = zeros(dictSize);
for i=1:dictSize
    for j=1:dictSize
        cloMat(i,j)=abs(dot(Dksvd(:,i),Dksvd(:,j)));
    end
end

figure('Position', [0, 300, 1920, 500]);
subplot(1,3,1)
plot(pop,'.');
title(sprintf('popularity of each dictionary atom'));
subplot(1,3,2)
plot(dataErr,'.')
ylim([0 1])
title(sprintf('error of each training data'));
subplot(1,3,3)
imagesc(cloMat)
colorbar;
title(sprintf('mutual coherence of dict'));

%% patch dict post-pocessing
popThreshold = 35;
for iPat=2%1:nPat % !!
    Dksvd=dictArr(iPat).data;
    Gamma=dictArr(iPat).spaCoding;

    dataErr=vecnorm(patchData-Dksvd*full(Gamma));

    [~, tempind]=sort(dataErr,'descend');

    % replace non-popular element
    pop=sum(full(Gamma)>0.01,2); % num of times for eachb atom has been used for sparse codinng

    kk=1; % kk is for trained data set
    for ii=1:dictSizeArr(iPat) % ii is for trained dict
        if pop(ii)<popThreshold
            if kk>round(dictSizeArr(iPat)*0.3) % !!
                % case where num of atom which originate from training data
                % set exceeds a thr
                break;
            end
            Dksvd(:,ii)=patchData(:,tempind(kk));
            kk=kk+1;
        end
    end

    % new dict
    dictArr(iPat).data=Dksvd;
end
