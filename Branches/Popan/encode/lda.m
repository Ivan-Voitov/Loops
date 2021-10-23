%% multi-class LDA
% Data is a cells * trials matrix.
% Labels is the identity of each trial.
% (optional) Normalize should be set to 1 for LDA.
% (optional) Regularize should be set to 0 or a very small number if code errors or the L2 regularization parameters.
% (optional) Priors is a vector of label probabilities (if not empirical)

function [DB] = lda(Data,Labels,Normalize,Regularize,Priors)
%% Set
if ~exist('Regularize','var')
    Regularize = 0;
end
if ~exist('Normalize','var')
    Normalize = 1;
end

if size(Data,1) > size(Data,2)
    Data = Data';
end
[Cells, Trials] = size(Data);

% Number of labels
ClassLabel = unique(Labels);
NumLabels = length(ClassLabel);

% Initialize
GroupCounts = NaN(NumLabels,1);
GroupMeans = NaN(NumLabels,Cells);
PooledCovariance = zeros(Cells,Cells);
Weights = NaN(NumLabels,Cells+1);

for I = 1:NumLabels
    GroupCounts(I) = sum(double((Labels == ClassLabel(I))));
    GroupMeans(I,:) = mean(Data(:,(Labels == ClassLabel(I)))');
    PooledCovariance = PooledCovariance + ((GroupCounts(I) - 1) / (Trials - NumLabels)).* cov(Data(:,(Labels == ClassLabel(I)))');
end

% Calculate prior probabilities
if (nargin >= 5)
    PriorProb = Priors;
else
    PriorProb = GroupCounts / Trials;
end

% Get coefficients
for I = 1:NumLabels
    if Normalize == 1% lda
        Temp = GroupMeans(I,:) / (PooledCovariance + diag(repmat(Regularize,[size(PooledCovariance,1) 1])));
        
        % Constant
        Weights(I,1) = -0.5 * Temp * GroupMeans(I,:)' + log(PriorProb(I));
    elseif Normalize == 0 % only diagonal normalization
        Temp = GroupMeans(I,:) / (diag(diag(PooledCovariance)) +  diag(repmat(Regularize,[size(PooledCovariance,1) 1])));%diag(repmat(Reg,[size(PooledCov,1) 1]));
        Weights(I,1) = -0.5 * Temp * GroupMeans(I,:)' + log(PriorProb(I));
    elseif Normalize == -1 % mean diff
        Temp = GroupMeans(I,:) ;
        % Constant
        Weights(I,1) = -0.5;
    end
    
    % Coeffs
    Weights(I,2:end) = Temp;
end

DB = Weights(1,:) - Weights(2,:);

if ~Control
    DB = Weights(1,:) - Weights(2,:);
else
    DB = Weights(1,:) + Weights(2,:);
end