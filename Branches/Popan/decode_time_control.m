function [Out] = decode_time_control(Index,varargin)


% shift it around
try
Index = Index([12 1:11 13:length(Index)]);
%
end
Colours;

[Traces] = rip(Index,'DeNaN','Trace','Zcore');
for Session = 1:length(Index)
    Loaded = load(Index(Session).Name,'Trial');
    AllTrial{Session} = Loaded.Trial;
    [Trials{Session},Sel{Session}] = selector(Loaded.Trial,Index(Session).Combobulation,'NoReset','HasFrames','Post','Nignore','NoLight');
end



% [Scores1,Classes1] = decode_time(Traces,Trials,false,'Folds',5);
% [Scores2,Classes2] = decode_time(Traces,Trials,false,'Folds',5,'Equate',true);
% [Scores3,Classes3] = decode_time(Traces,Trials,false,'Folds',5,'Trim',true);
[~,Classes] = decode_time(Traces,Trials,false,'Folds',5,'Trim',true,'Equate',true);
[Scores,~] = decode_time(Traces,Trials,false,'Folds',5);

for I = 1:100
    [ShuffledScores{I},ShuffledClasses(:,:,I)] = decode_time(Traces,Trials,true,'Folds',5,'Trim',true,'Equate',true);
end

for Session = 1:length(Scores)
    Noise(Session,:) = [prctile(squeeze(cat(3,ShuffledClasses(Session,1,:),ShuffledClasses(Session,2,:))),2.5) ...
        prctile(squeeze(cat(3,ShuffledClasses(Session,1,:),ShuffledClasses(Session,2,:))),97.5)];
end

%% 

%% example plot
% Scores = Scores4;
for Session = 1:length(Scores)
    for Task = 1:2
        SeldScores{Session,Task} = nan(length(Sel{Session}),1);
        SeldScores{Session,Task}(Sel{Session}) = Scores{Session,Task};
    end
end

S= 1;

figure;
subplot(2,2,1:2); hold on;
line([1 length(AllTrial{S})],[0 0],'color',Grey,'LineWidth',3); hold on;
% X = find(diff(destruct(AllTrial{S},'Task'))~=0);
% for L = 1:length(X)
%     line([X(L) X(L)],[-500000000000000 500000000000000],'color','k','LineWidth',2)
% end
plot(find(destruct(AllTrial{S},'Task')==2),Index(S).Score(destruct(AllTrial{S},'Task')==2),...
    'LineStyle','none','Marker','o','MarkerEdgeColor','none','MarkerFaceColor',Blue,'MarkerSize',3);
plot(find(destruct(AllTrial{S},'Task')==1),Index(S).Score(destruct(AllTrial{S},'Task')==1),...
    'LineStyle','none','Marker','o','MarkerEdgeColor','none','MarkerFaceColor',Red,'MarkerSize',3);
Ax = gca; Ax.YTick = []; Ax.XLim = [1 length(AllTrial{S})]; Ax.XTick = [1 length(AllTrial{S})];
Ax.YLim = [min(Index(S).Score(destruct(AllTrial{S},'Task')==1)) max(Index(S).Score(destruct(AllTrial{S},'Task')==2))];

subplot(2,2,3);
line([1 sum(~isnan(SeldScores{S,1}))],[0 0],'color',Grey,'LineWidth',3); hold on;
TempToPlot = SeldScores{S,1}(~isnan(SeldScores{S,1}));
plot(TempToPlot(1:round(length(TempToPlot)/2)),'LineStyle','none','Marker','s','MarkerEdgeColor','none','MarkerFaceColor',Red,'MarkerSize',3);
plot(round(length(TempToPlot)/2)+1:length(TempToPlot),TempToPlot(round(length(TempToPlot)/2)+1:end),'LineStyle','none','Marker','d','MarkerEdgeColor','none','MarkerFaceColor',Red,'MarkerSize',3);
Ax = gca; Ax.YTick = []; Ax.XTick = [1 sum(~isnan(SeldScores{S,1}))]; Ax.XLim = [1 sum(~isnan(SeldScores{S,1}))];

subplot(2,2,4);

line([1 sum(~isnan(SeldScores{S,2}))],[0 0],'color',Grey,'LineWidth',3); hold on;
TempToPlot = SeldScores{S,2}(~isnan(SeldScores{S,2}));
plot(TempToPlot(1:round(length(TempToPlot)/2)),'LineStyle','none','Marker','s','MarkerEdgeColor','none','MarkerFaceColor',Blue,'MarkerSize',3)
plot(round(length(TempToPlot)/2)+1:length(TempToPlot),TempToPlot(round(length(TempToPlot)/2)+1:end),'LineStyle','none','Marker','d','MarkerEdgeColor','none','MarkerFaceColor',Blue,'MarkerSize',3)
Ax = gca; Ax.YTick = [];Ax.XTick = [1 sum(~isnan(SeldScores{S,2}))]; Ax.XLim = [1 sum(~isnan(SeldScores{S,2}))];

%% plot
figure;
hold on;
for Session= 1:length(Scores)
    % noise line
    plot([Session Session],Noise(Session,:).*100,'color',Grey,'LineWidth',4)
    
    % points
    plot(Session,Classes(Session,1).*100,'color',Red,'Marker','o','MarkerFaceColor',Red);
    plot(Session,Classes(Session,2).*100,'color',Blue,'Marker','o','MarkerFaceColor',Blue);
end

Ax = gca;
Ax.XLim = [0 length(Scores)+1];
Ax.YLim = [0 100];
xlabel('Experiment')
% AreaList = cat(1,Index.Area);
% for K = 1:length(AreaList)
%     if AreaList(K) == 1
%         ToLabel{K} = 'M2';
%     else
%         ToLabel{K} = 'AM';
%     end
% end
% Ax.XTickLabel = ToLabel;
% Ax.XTick = 1:10:length(Scores);
% Ax.XTickLabel = 1:10:length(Scores);
 Ax.XTick = [1 10 20 31];
Ax.XTickLabel = [1 10 20 31];
ylabel('Classification accuracy');
ytickformat(gca, '%g%%');
end
%%


function [Scores,Classes] = decode_time(Traces,Trials,Shuffle,varargin)

Folds = 10;
Window = [-1000 3200]; % first term is the pre
Model = 'LDA';
DePre = false;
FPS = 4.68;
Iterate = 100;
Clever = false;
Trim = false;
Equate = false;
Smooth = false;

%% PASS ARGUMENTS TO CONTROLS
for I=1:2:numel(varargin)
    eval([varargin{I} '= varargin{I+1};']);
end

Range = frame(Window,FPS);


for Session = 1:length(Traces)
    
    Trial = Trials{Session};
    Sel = true(length(Trial),1);
    
    %% extract values
    for Task = 1:2
        Labels{Task} = destruct(Trial,'Task'); Labels{Task}(Labels{Task} == (3-Task)) = nan;
        Length = ceil(sum(~isnan(Labels{Task})) / 2); ToAdd = cat(1,ones(Length,1),ones(Length,1)+1);
        if Shuffle;ToAdd = ToAdd(randperm(length(ToAdd))); end
        Labels{Task}(~isnan(Labels{Task})) = ToAdd(1:length(Labels{Task}(~isnan(Labels{Task}))));
    end
    
    
    % get activities
    TrigOn = destruct(Trial,'Trigger.Delay.Frame');
    TrigOff = destruct(Trial,'Trigger.Stimulus.Frame');
    %     if Smooth
    %         for C = 1:size(DFFs{Session},1)
    %             NotNaN = ~isnan(DFFs{Session}(C,:));
    % %             DFFs{Session}(C,NotNaN)= gaussfilt(1:length(NotNaN),DFFs{Session}(C,NotNaN),1);
    %             DFFs{Session}(C,NotNaN)= gaussfilt(1:length(DFFs{Session}(C,NotNaN)),DFFs{Session}(C,NotNaN),1);
    %         end
    %     end
    
    Activities = wind_roi(Traces{Session},{TrigOn;TrigOff},'Window',Range);
    
    % get values without clever for threshold
    Values = reshape((nanmean(Activities(:,(end-Range(2))+1:end,:),2)),[size(Activities,1) size(Activities,3)]);
    
    % get values again after threshold
    if Clever
        MeanActivities = nanmean(cat(3,nanmean(Activities(:,:,Labels==1),3), nanmean(Activities(:,:,Labels==0),3)),3);
        for T = 1:size(Activities,3)
            Activities(:,:,T) = Activities(:,:,T) - MeanActivities;
        end
    end
    
    % final values calculation
    Values = reshape((nanmean(Activities(:,(end-Range(2))+1:end,:),2)),[size(Activities,1) size(Activities,3)]);
    
    % depre...
    if DePre
        Values = Values - (squeeze(nanmean(Activities(:,1:(abs(Range(1))),:),2)));
    end
    X = find(~all(isnan(Values)'),1);
    Labels{1}(isnan(Values(X,:))) = nan;
    Labels{2}(isnan(Values(X,:))) = nan;
    
    %% Discriminate
    for Task = 1:2
        TempLabels = Labels{Task};
        if Trim
            TempLabels(find(~isnan(TempLabels),1):find(~isnan(TempLabels),1)+round(sum(~isnan(TempLabels))/4)) = nan;
        end
        if Equate
            [A,B] = min([sum(TempLabels==1) sum(TempLabels==2)]);
            TempReplace = cat(1,repmat((3-B),[A 1]), nan(sum(TempLabels==(3-B))-A,1));
            TempLabels(TempLabels==(3-B)) = TempReplace(randperm(length(TempReplace)));
        end
        IterLabels = TempLabels;

        clearvars TempBases TempTrace TempClasses TempDelayTrace
%         IterLabels = Labels{Task};
        TempScores = nan(length(IterLabels),Iterate);
        for I = 1:Iterate
            
            [TempBasis, TempScore, TempClasses(:,I), PartitionedBasis] = ...
                discriminate2(Values,IterLabels,'Fold',Folds,'Model',Model,'Reg',0);
            
            TempBases(:,I) = nanmean(cat(2,TempBasis{:}),2);
            TempScores(~isnan(IterLabels),I) = TempScore;
        end
        Classes(Session,Task) = nanmean(TempClasses,2);
        Scores{Session,Task} = nanmean(TempScores,2);
        
        Score = nan(length(Sel),1);
        Score(Sel) = Scores{Session,Task};
        Scores{Session,Task} = Score;
        
    end
end
end