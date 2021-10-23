function shuffle_basis_light(Index)


%%
for I=1:2:numel(varargin)
    eval([varargin{I} '= varargin{I+1};']);
end

%% get shuffled bases and traces
OutLDA = encode({DFFs;Trials},'CCD',true,'Window',[-1000 3200],'OnlyCorrect',false,'Equate',false,'DePre',true,'Clever',false,'Iterate',1,...
    'NormalizeLDA',1,'FPS',22.39,'Folds',1,'AverageProjection',false,'Regularization',1); % no iteration needed because equate not true
OutLDAL1O = encode({DFFs;Trials},'CCD',true,'Window',[-1000 3200],'OnlyCorrect',true,'Equate',false,'DePre',true,'Clever',false,'Iterate',1,...
    'NormalizeLDA',1,'FPS',22.39,'Folds',-1,'AverageProjection',false,'Regularization',1); % no iteration needed because leave one out can only be done one way

AvgTraces = OutLDA{7};
CueTraces = OutLDA{6};
CueTracesL1O = OutLDAL1O{6};


for S = 1:length(Index)
    Basis{S} = Index(S).Basis;
    
    
end