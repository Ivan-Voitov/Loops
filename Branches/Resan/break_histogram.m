function break_histogram(Index,varargin)
Bases = [];
Window = [-1200 3200];
Threshold = 0;
FPS = 22.39;
Equate = false;
Tasks = {'Discrimination';'Memory'};
Colours;
Colour = {Blue;Red};
Z = false;
Ratio = false;
BinWidth= 0.05;
for I = 1:2:numel(varargin)
    if ~exist(varargin{I},'var')
        sprintf('Warning: one of the ParseArgs did not exist \r');
    end
    eval([varargin{I} '= varargin{I+1};']);
end

if iscell(Index)
    DFFs = Index{1}; Trials = Index{2};
else
    [DFFs,Trials] = rip(Index,'Super','DeNaN','Active','DelayResponsive');
end
clearvars Index

if Z
    for K = 1:length(DFFs)
        DFFs{K} = (zscore(DFFs{K}',[],'omitnan'))';
    end
end
%% extract
rng(100);
for Task = 1:length(Tasks)
    try
        clearvars ShuffleDifference
        TempTrial1 = selector(Trials,'NoLight',Tasks{Task});
        TempTrial2 = selector(Trials,'Light',Tasks{Task});
        TempDFFs = DFFs;
        
        % remove unexistent
        Remove = false(length(TempTrial2),1);
        for I = 1:length(TempTrial2)
            if isempty(TempTrial2{I})
                Remove(I) = true;
            end
        end
        TempTrial2(Remove) = [];
        TempTrial1(Remove) = [];
        TempDFFs(Remove) = [];
        
        % real effects
        Off{Task} = nanmean(avg_triggered(TempDFFs,TempTrial1,1,'Window',Window,'FPS',FPS,'DePre',false),2);
        On{Task} = nanmean(avg_triggered(TempDFFs,TempTrial2,1,'Window',Window,'FPS',FPS,'DePre',false),2);
        
        if ~Ratio
            Difference{Task} =  (Off{Task} - On{Task});
        else
            Difference{Task} =  (On{Task} ./ Off{Task});
        end
        
        % shuffle control
        for Shuff = 1:50
            for S = 1:length(TempTrial1)
                Ind = datasample(1:length(TempTrial1{S}),length(TempTrial2{S}),'Replace',true);
                ShuffleTrial{S} = TempTrial1{S}(Ind);
            end
            
            ShuffleOn = nanmean(avg_triggered(TempDFFs,ShuffleTrial,1,'Window',Window,'FPS',FPS,'DePre',false),2);
            if ~Ratio
                ShuffleDifference(:,Shuff) =  (Off{Task} - ShuffleOn);
            else
                ShuffleDifference(:,Shuff) =  (ShuffleOn ./ Off{Task});
            end
        end
        
        Low = prctile(ShuffleDifference',2.5)';
        High = prctile(ShuffleDifference',97.5)';
        
        % statistics
        Sig{Task} = or(Difference{Task}<Low,Difference{Task}>High);
    end
end

%% plot

for Task = 1:length(Tasks)
    try
        figure;
        histogram(Difference{Task},50,'BinWidth',BinWidth,'Normalization','count'...
            ,'FaceColor',Grey,'EdgeColor','none');
        hold on;
        histogram(Difference{Task}(Sig{Task}),50,'BinWidth',BinWidth,'Normalization','count'...
            ,'FaceColor',Colour{Task},'EdgeColor','none');
        Ax{Task} = gca;
        if ~Z
            Ax{Task}.XLim = [-5.5 5.5];
            Ax{Task}.XTick = [-5.5 0 5.5];
        else
            Ax{Task}.XLim = [-2 2];
            Ax{Task}.XTick = [-2 0 2];
        end
        text(-1.5,50,num2str(sum(Sig{Task})/length(Sig{Task})));
    end
end

if length(Tasks)==2
    Ax{1}.YLim = [0 200];%max(Ax{1}.YLim,Ax{2}.YLim);
    Ax{2}.YLim = [0 200];%max(Ax{1}.YLim,Ax{2}.YLim);
    Ax{1}.YTick = [0 200];
    Ax{2}.YTick = [0 200];
end

%     histogram(ToPlot{2}{2},50,'BinWidth',0.04,'Normalization','count'...
%         ,'FaceColor','none','EdgeColor',Black,'LineWidth',2,'DisplayStyle','stairs');
%
%     hold on;
%     histogram(ToPlot{2}{2},50,'BinWidth',0.04,'Normalization','count'...
%         ,'FaceColor',Grey,'EdgeColor','none');


% end
