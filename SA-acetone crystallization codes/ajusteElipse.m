% this is the function to extract the parameters needed to build the
% elliptical mask
function params = ajusteElipse(x, y)
    A = [x.^2, x.*y, y.^2, x, y, ones(length(x),1)];
    [U, S, V] = svd(A, 'econ');
    params = V(:,end); 
    norm_factor = params(1) + params(3);
    params = params / norm_factor;
end
