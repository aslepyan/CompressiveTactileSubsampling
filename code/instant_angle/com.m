% This function calculate the center of mass (COM) of a given 2D object/image.
function [rowInd,colInd]=com(obj)
% obj is represented as a image
% rowInd - COM in the row coordinate
% colInd - COM in the column coordinate

obj_sz=size(obj);
[colIndMat,rowIndMat]=meshgrid(1:obj_sz(2),1:obj_sz(1));
m_tot=sum(obj,"all");
rowInd=sum(obj.*rowIndMat,'all')/m_tot;
colInd=sum(obj.*colIndMat,'all')/m_tot;
