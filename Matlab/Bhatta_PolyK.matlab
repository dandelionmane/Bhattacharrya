% Starting parameters
n1 = 15;
n2 = 15;
n = 30;
d = 5;
sigma = .5;
z = 1;
r=5;

% Random identical dataset
X1 = randn(n1,d);
X2 = randn(n2,d);
%X2 = X1 + .001 * rand(n1,d);
X = [X1; X2];

% Non-kernelized Bhattacharrya
nk_mu1 = sum(X1)/n1; % results in a 1xd row vector
nk_mu2 = sum(X2)/n2;
nk_X1c = X1 - repmat(nk_mu1,n1,1);
nk_X2c = X2 - repmat(nk_mu2,n2,1);

nk_S1 = nk_X1c'*nk_X1c / n1;
nk_S2 = nk_X2c'*nk_X2c / n2;

nk_invS1 = inv(nk_S1);
nk_invS2 = inv(nk_S2);

nk_mu3 = .5* (nk_invS1 * nk_mu1' + nk_invS2 * nk_mu2')';
nk_S3 = 2 * inv(nk_invS1 + nk_invS2);

nk_det = det(nk_S1)^(-1/4) * det(nk_S2)^(-1/4)*det(nk_S3)^(1/2);
nk_a = -.25* nk_mu1 * nk_invS1 * nk_mu1';
nk_b = -.25* nk_mu2 * nk_invS2 * nk_mu2';
nk_c = .5*   nk_mu3 * nk_S3 * nk_mu3';
nk_exp = exp(nk_a + nk_b + nk_c);
nk_bhatta = nk_det * nk_exp;
nk_components = [nk_det, nk_exp, nk_bhatta]


% Compute general kernel bhattacharrya components
% K - n x n matrix where K_ij = <x_i | x_j>
K=zeros(n,n); %K(i,j) = <x_i | x_j>
for i=1:n
    for j=1:i
        %K(i,j) = exp(-norm(X(i,:)-X(j,:))^2 / (2*sigma^2));
        K(i,j) = dot(X(i,:),(X(j,:)))^3;
        % Polynomial kernel - corresponds to a known RKHS
        K(j,i) = K(i,j);
    end;
end;

%U1_i = <mu_1 | xi>

U1 = sum(K(1:n1,:),1)/n1;
U2 = sum(K(n1+1:n,:),1)/n2;
U=[repmat(U1,n1,1);repmat(U2,n2,1)];

m1m1 = sum(sum(K(1:n1,   1:n1  ))) / (n1*n1);
m1m2 = sum(sum(K(1:n1,   n1+1:n))) / (n1*n2);
m2m2 = sum(sum(K(n1+1:n, n1+1:n))) / (n2*n2);

mumu = zeros(n,n);
mumu(1:n1,   1:n1  ) = m1m1;
mumu(1:n1,   n1+1:n) = m1m2;
mumu(n1+1:n, 1:n1  ) = m1m2;
mumu(n1+1:n, n1+1:n) = m2m2;

Kcu = K - U; % <Centered | Uncentered>
%Kcu(i,j) = <x*i | xj>
Kuc = Kcu';
%Kuc(i,j) = <xi | x*j> = <x*j | xi>
%Kcu(i,j) = <X*i | Xj>
Kc = K - U - U' + mumu; % <Centered | Centered>
%Kc(i,j) = <X*i | X*j>
% All of this verified with linear & poly kernel

%%

%P(Phi): Actual RKHS for polynomial kernel (degree 3)
%P(i,:) = Phi(X(i,:))
P = zeros(n,35);
for row=1:n
    a = X(row,1);
    b = X(row,2);
    c = X(row,3);
    d = X(row,4);
    e = X(row,5);
    P(row,:) = [a^3, 3^.5*a^2*b, 3^.5*a*b*b, b^3, 3^.5*a*a*c, 6^.5*a*b*c, ...
        3^.5*b*b*c, 3^.5*a*c*c, 3^.5*b*c*c, c^3, 3^.5*a*a*d, 6^.5*a*b*d, 3^.5*b*b*d,...
        6^.5*a*c*d, 6^.5*b*c*d, 3^.5*c*c*d, 3^.5*a*d*d, 3^.5*b*d*d, 3^.5*c*d*d, d^3,...
        3^.5*a*a*e, 6^.5*a*b*e, 3^.5*b*b*e, 6^.5*a*c*e, 6^.5*b*c*e, 3^.5*c*c*e, ...
        6^.5*a*d*e, 6^.5*b*d*e, 6^.5*c*d*e, 3^.5*d*d*e, 3^.5*a*e*e, 3^.5*b*e*e, 3^.5*c*e*e, ...
        3^.5*d*e*e, e^3];
end

P1 = P(1:n1,   :);
P2 = P(n1+1:n, :);
P_mu1 = sum(P1,1)/n1;
P_mu2 = sum(P2,1)/n2;
P1c = P1 - repmat(P_mu1,n1,1);
P2c = P2 - repmat(P_mu2,n2,1);
Pc = [P1c; P2c];

% Verification of correctness for P: K_P = K, Kc_P = Kc
Kc_P = zeros(n,n);
K_P = zeros(n,n);
for i=1:n
    for j=1:i
        Kc_P(i,j) = dot(Pc(i,:),Pc(j,:));
        Kc_P(j,i) = Kc_P(i,j);
        K_P(i,j) = dot(P(i,:),P(j,:));
        K_P(j,i) = K_P(i,j);
    end
end


% Compute kernelized bhattacharrya in closed form
P_S1 = eye(35)*z + P1c' * P1c / n1;
P_S2 = eye(35)*z + P2c' * P2c / n2;

P_mu3 = .5 * (inv(P_S1) * P_mu1' + inv(P_S2) * P_mu2')';
P_S3 = 2 * inv(inv(P_S1) + inv(P_S1));

p_det1 = det(P_S1)^(-.25);
p_det2 = det(P_S2)^(-.25);
p_det3 = det(P_S3)^(.5);

P_det = p_det1*p_det2*p_det3;
P_a = -.25*P_mu1*inv(P_S1)*P_mu1';
P_b = -.25*P_mu2*inv(P_S2)*P_mu2';
P_c = .5*P_mu3 * P_S3 * P_mu3';
P_exp = exp(P_a + P_b + P_c);

P_bhatta = P_det * P_exp

% Now we pivot to computing the kernelized bhattacharrya using a
% GS-basis

G = eye(n);
G(:,n) = [];
G(:,n1)= [];
% We get rid of two dimensions because the centering process reduces
% the dimensionality of the data
for ell=1:n-2
    for i=1:ell-1
        GKG = G'*Kc*G;
        G(:,ell) = G(:,ell) - GKG(ell,i) * G(:,i);
    end
    GKG = G'*Kc*G;
    G(:,ell) = G(:,ell) / (GKG(ell,ell))^(.5);
end

GP = G'*Pc; % The RKHS representation of |g>
% GP(i,:) = |gi>

mu1 = sum(Kuc(1:n1,:)  *G,1)/n1;
mu2 = sum(Kuc(n1+1:n,:)*G,1)/n2;

e_mu1 = mu1;
e_mu2 = mu2;
pca_mu1 = mu1;
pca_mu2 = mu2;

%% Empirical Bhatta - no PCA / eigendecomposition
e_S1 = eye(n-2)*z + (G'*Kc(:,1:n1)  *Kc(1:n1,:)  *G)/n1;
e_S2 = eye(n-2)*z + (G'*Kc(:,1+n1:n)*Kc(n1+1:n,:)*G)/n2;

%e_invS1=inv(e_S1);
%e_invS2=inv(e_S2);

e_mu3 = (inv(e_S1) * e_mu1' + inv(e_S2) * e_mu2')'/2;
%e_S3w = 2 * inv(e_invS1 + e_invS2);
e_S3 = 2 * inv(inv(e_S1) + inv(e_S1));


e_det1 = det(e_S1)^(-1/4);
e_det2 = det(e_S2)^(-1/4);
e_det3 = det(e_S3)^(1/2);

e_exp1 = -e_mu1 * inv(e_S1) * e_mu1' /4;
e_exp2 = -e_mu2 * inv(e_S2) * e_mu2' /4;
e_exp3 =  e_mu3 * e_S3    * e_mu3' /2;

e_det = e_det1 * e_det2 * e_det3;
e_exp = exp(e_exp1 + e_exp2 + e_exp3);

e_bhatta = e_det * e_exp
e_bhatta_components = [e_det, e_exp, e_bhatta];


Kc1 = Kc(1:n1, 1:n1);
Kc2 = Kc(n1+1:n, n1+1:n);
    
% Eigendecomposition of centered kernel matrix - for PCA kernel
[alpha1, lam1] = eigs(Kc1,r);
[alpha2, lam2] = eigs(Kc2,r);
lam1 = lam1 / n1; 
lam2 = lam2 / n2;


%Beta1, Beta2 hold normalized eigenvector coefficients so that 
% <v_i | v_i> = 1. Note <v_i| = \sum_j beta(j,i) <x*_j|
% Note we also shift Beta2 down to the bottom portion of the matrix
% Because Beta2 is composed of vectors from set X2, i.e. |x*_i> for
% i in n1+1 : n
Beta1 = zeros(n,r);
Beta2 = zeros(n,r);

for i=1:r
    Beta1(1:n1  ,i) = alpha1(:,i) / (n1 * lam1(i,i))^(.5);
    Beta2(n1+1:n,i) = alpha2(:,i) / (n2 * lam2(i,i))^(.5);
end

%% PCA Bhatta - eigendecomposition
pca_S1 = eye(n-2) * z + (G'*Kc*Beta1 * lam1 * (G'*Kc*Beta1)');
pca_S2 = eye(n-2) * z + (G'*Kc*Beta2 * lam2 * (G'*Kc*Beta2)');

pca_S3 = 2 * inv( inv(pca_S1) + inv(pca_S2) );
pca_mu3 = .5 * (inv(pca_S1) * pca_mu1' + inv(pca_S2) * pca_mu2')';

raw_det1 = (prod(diag(lam1)+z) * z^(n-r))^-.25;% - To my surprise, using these determinants didn't work
raw_det2 = (prod(diag(lam2)+z) * z^(n-r))^-.25;
pca_det1 = det(pca_S1)^-.25;
pca_det2 = det(pca_S2)^-.25;
pca_det3 = det(pca_S3)^.5;

pca_exp1 = -(pca_mu1 * inv(pca_S1) * pca_mu1')/4;
pca_exp2 = -(pca_mu2 * inv(pca_S2) * pca_mu2')/4;
pca_exp3 = (pca_mu3  * pca_S3      * pca_mu3')/2;

pca_det = pca_det1*pca_det2*pca_det3;
pca_exp = exp(pca_exp1 + pca_exp2 + pca_exp3);

pca_bhatta = pca_exp * pca_det
pca_bhata_components = [pca_det, pca_exp, pca_bhatta];

nk_P_e_pca = [nk_bhatta, P_bhatta, e_bhatta, pca_bhatta];