% https://ieeexplore.ieee.org/abstract/document/8556009
function [xhat] = FastOMP(A,y,S)
% A = sensing matrix
% y = measurements
% S = sparsity level
% xhat = reconstructed sparse x

% add small offset to y to eliminate NaNs
% y = y + 1e-4;

[M,N] = size(A);
xhat = zeros(N,1);
r = y;
s = zeros(S,1);
Q = zeros(M,S);
R = zeros(S,S);

for i = 1 : S
    [~,idx_max]=max(abs(r'*A));
    s(i) = idx_max;
    w = A(:,s(i));
    for j = 1 : i-1
        R(j,i) = Q(:,j)' * w;
        w = w - R(j,i)*Q(:,j)/R(j,j);
    end
    R(i,i) = (norm(w).^2+1e-4);
    Q(:,i) = w;
    r = r - Q(:,i)' * r * Q(:,i) / R(i,i);
end
v = Q' * y;
for i = 1 : S
    xhat(s(S-i+1)) = (v(S-i+1) - R(S-i+1,:)*xhat(s)) / R(S-i+1,S-i+1);
end

end