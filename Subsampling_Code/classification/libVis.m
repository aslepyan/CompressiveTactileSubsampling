%% Visualize the 'library'
load("..\traningData\lib.mat");

figure;
for k=1:libSize % !!!
    img=reshape(Psi(:,k),[32,32])';
    imagesc(img);
    title(sprintf('Column No. %d|Object No. %d',k,ceil(k/numTrainObj)));
    pause(0.1)
    drawnow;
end
