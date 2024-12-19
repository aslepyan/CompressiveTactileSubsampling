% This file is for calculating the overcomplete haar wavelet dictionary
clear

addpath("..\ksvdbox13")

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
dictFileName = 'dictionary_haar.mat';
dictPath = fullfile('..\..\data\traningData\', dictFileName);
save(dictPath, "dictArr");

function W = WavMat(h, N, k0, shift)
% WavMat -- Transformation Matrix of FWT_PO
%  Usage
%    W = WavMat(h, N, k0, shift)
%  Inputs
%    h      low-pass filter corresponding to orthogonal WT
%    N      size of matrix/length of data. Should be power of 2.
%
%    k0     depth of transformation. Ranges from 1 to J=log2(N).
%           Default is J.
%    shift  the matrix is not unique an any integer shift gives
%           a valid transformation. Default is 2.
%  Outputs
%    W      N x N transformation matrix
%
%  Description
%    For a quadrature mirror filter h (low pass) the wavelet
%    matrix is formed. The algorithm is described in
%    [BV99] Vidakovic, B. (1999). Statistical Modeling By Wavelets, Wiley,
%    on pages 115-116.
%    Any shift is valid.  Size N=1024 is still managable on a standard PC.
%
%  Usage
%    We will mimic the example 4.3.1 from [BV99] page 112.
%   > dat=[1 0 -3 2 1 0 1 2];
%   > W = WavMat(MakeONFilter('Haar',99),2^3,3,2);
%   > wt = W * dat' %should be [sqrt(2)  |  -sqrt(2) |   1 -1  | ...
%              %  1/sqrt(2) -5/sqrt(2) 1/sqrt(2) - 1/sqrt(2) ]
%   > data = W' * wt % should return you to the 'dat'
%
%  See Also
%    FWT_PO, IWT_PO, MakeONFilter
%
if nargin==3
    shift = 2;
end
J = log2(N);
if nargin==2
    shift = 2;
    k0 = J;
end
%--make QM filter G
h=h(:)';  g = fliplr(conj(h).* (-1).^(1:length(h)));
if (J ~= floor(J) )
    error('N has to be a power of 2.')
end
h=[h,zeros(1,N)]; %extend filter H by 0's to sample by modulus
g=[g,zeros(1,N)]; %extend filter G by 0's to sample by modulus
oldmat = eye(2^(J-k0));
for k= k0:-1:1
    clear gmat; clear hmat;
    ubJk = 2^(J-k); ubJk1 = 2^(J-k+1);
    for  jj= 1:ubJk
        for ii=1:ubJk1
            modulus = mod(N+ii-2*jj+shift,ubJk1);
            modulus = modulus + (modulus == 0)*ubJk1;
            hmat(ii,jj) = h(modulus);
            gmat(ii,jj) = g(modulus);
        end
    end
    W = [oldmat * hmat'; gmat' ];
    oldmat = W;
end
%
%
% Copyright (c) 2004. Brani Vidakovic
%
%
% ver 1.0 Built 8/24/04; ver 1.2 Built 12/1/2004
% This is Copyrighted Material
% Comments? e-mail brani@isye.gatech.edu
end
