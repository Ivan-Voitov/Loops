function [Basis, Score, Class, PartitionedBasis] = discriminate2(Values,Labels,varargin)
Folds = 10;
Model = 'LDA';
Reg = 10^(-5);
Normalize = true;
BasisIn = [];
Equate = false;
MultiValue = [];
Balance = false;
Prior = false;

%% PASS CONTROL
for I=1:2:numel(varargin)
    eval([varargin{I} '= varargin{I+1};']);
end

if Equate
    Prior = [0.5 0.5];
end

%% INITIALIZE
% select usable labels
Values(:,isnan(Labels)) = [];
if ~isempty(MultiValue)
   MultiValue(:,isnan(Labels)) = []; 
end
Labels(isnan(Labels)) = [];
Labels = Labels - min(Labels);

% extract partitions
% make two randindexes, and interleave them
try
    RandIndex1 = find(Labels==1);
    RandIndex1 = RandIndex1(randperm(length(RandIndex1)));
    RandIndex2 = find(Labels==0);
    RandIndex2 = RandIndex2(randperm(length(RandIndex2)));
    RandIndex = nan(length(Labels),1);
    try
        RandIndex(1:2:end) = RandIndex1; RandIndex(2:2:end) = RandIndex2;
    catch
        RandIndex(1:2:end) = RandIndex2; RandIndex(2:2:end) = RandIndex1;
    end
    RandIndex = RandIndex';
    
catch % or if they are not matchable just do randperm...
    RandIndex = randperm(length(Labels));
end

%% bug location of L1O
clearvars Partition
if Folds == -1
    Folds = size(Values,2);
end

for P = 1:Folds
    Partition{P} = [(P-1).*(floor(size(Values,2)./Folds))+1:...
        P.*(floor(size(Values,2)./Folds))];
    Partition{P} = RandIndex(Partition{P});
end
% give last partition not used ones
Partition{end} = cat(2,Partition{end},RandIndex(P.*(floor(size(Values,2)./Folds))+1 : end));

% regularization
PartitionedScore = [];

%% take out the partition and then calculate the decision boundary
for P = 1:size(Partition,2)
    PartValues = Values;
    PartLabels = Labels;
    %
    %     if size(PartValues,2) == 1
    %        PartValues = PartValues';
    %     end
    
    if Folds ~= 1
        PartValues(:,Partition{P}) = [];
        PartLabels(Partition{P}) = [];
    end
    
    
    NotNaN = any(~isnan(PartValues(:,:))')';
    %     ~isnan(PartValues(:,1));
    % create decision boundary
    if ~isempty(BasisIn)
        if iscell(BasisIn)
            Basis{P} = BasisIn{P};
        else
            Basis{P} = nan(size(PartValues,1)+1,1);
            Basis{P}([true; NotNaN]) = BasisIn([true;NotNaN]);
%             Basis{P}(isnan(Basis{P})) = Reg; %what is this?
        end
    elseif strcmp(Model,'Means')
        Basis{P} = nan(size(PartValues,1)+1,1);
        Basis{P}([true; NotNaN]) = lda(PartValues(NotNaN,:)',-double(PartLabels+1),-1,Reg,Prior);
    elseif strcmp(Model,'LDA')
        Basis{P} = nan(size(PartValues,1)+1,1);
        Basis{P}([true; NotNaN]) = lda(PartValues(NotNaN,:)',-double(PartLabels+1),Normalize,Reg,Prior);
    elseif strcmp(Model,'Regression')
        Basis{P} = nan(size(PartValues,1)+1,1);
        Basis{P}([true; NotNaN]) = -mnrfit(PartValues(NotNaN,:)',PartLabels+1,'Model','hierarchical')';
        %         glmfit(PartValues(NotNaN,:)',PartLabels+1,'binomial')
    end
    if ~isempty(MultiValue)
        TempValues = MultiValue(:,Partition{P});
        NotNaN = and(NotNaN, any(~isnan(MultiValue(:,:))')');
    else
        TempValues = Values(:,Partition{P});
    end
    PartScore = -([ones(size(TempValues(NotNaN,:),2),1) TempValues(NotNaN,:)'] * Basis{P}([true; NotNaN]));
    
    PartitionedBasis(Partition{P},:) = repmat(Basis{P},[1 length(Partition{P})])';
    PartitionedScore(Partition{P},:) = PartScore;
end

%% for making the 'correct' classifier (i.e., the best)
% i need to split the trials down the line which takes the number of
% the respective IDs{1} into account (i.e., score cut is prctile of
% IDs{1}(1) ./ (2)...
% class is really, all correct over all trials
Threshold = 0;
%         Threshold = prctile(TempScore{R}(:),((sum(Labels==1) ./ length(Labels)).*100));

%     if length(TempScore{R}) > length(Labels)
%         TempScore{R}(end,:) = [];
%     end
%     if length(TempScore{R}) < length(Labels)
%         Labels(end) = [];
%         if exist('Contrast','var')
%             ContrastNames = fieldnames(Contrast);
%             for F = 1:length(ContrastNames)
%                 Contrast.(ContrastNames{F})(end) = [];
%             end
%         end
%     end
Score = PartitionedScore;

Labels(isnan(PartitionedScore)) = [];
PartitionedScore(isnan(PartitionedScore)) = []; % only needed for multivalue i think

Class = (sum(double(PartitionedScore(:) < Threshold) .* double(Labels)) ...
    + sum(double(PartitionedScore(:) >= Threshold) .* double(1 - Labels))) ...
    ./ size(Labels,1);

if Balance
    Class = ( (sum(double(PartitionedScore(:) < Threshold) .* double(Labels)) ./ sum(Labels==1)) + ...
        ((sum(double(PartitionedScore(:) >= Threshold) .* double(1 - Labels)) ./ sum(Labels==0))) ) ./2;
end
% Class
%     figure;
%     plot(TempScore{R})
%     hold on
%     line([1 length(TempScore{R})],[0 0],'color','k','LineWidth',2)
%     line([find(diff(Labels)~=0,1) find(diff(Labels)~=0,1)],[-5 5],'color','r','LineWidth',2)


