function scatter_task_noise(Index,varargin)
DePre = false;
FPS = 4.68;
Window = [0 3200]; % this is because i dont want to include more time steps for
% one task over the other which might happen by chance at very rare delay
% lengths
ZScore = false; % (across all trials)
Way = 3;
Equate = false;

%% PASS ARGUMENTS TO CONTROLS
for I=1:2:numel(varargin)
    eval([varargin{I} '= varargin{I+1};']);
end

if ~iscell(Index)
    [DFFs,Trials] = rip(Index,'S','Super','DeNaN','DelayResponsive','Active');
else
    DFFs = Index{1}; Trials = Index{2};
end

Range = round(Window ./ (1000./FPS));

%% extract values
Activity = [];
Correlation = [];
CentralCorrelation = [];
for Session = 1:length(DFFs)
    if Equate
        TempLabels = destruct(Trials{Session},'Task');
        [A,B] = min([sum(TempLabels==1) sum(TempLabels==2)]);
        TempReplace = cat(1,repmat((3-B),[A 1]), nan(sum(TempLabels==(3-B))-A,1));
        TempLabels(TempLabels==(3-B)) = TempReplace(randperm(length(TempReplace)));
    end
    
    % all trials
    TrigOn = destruct(Trials{Session},'Trigger.Delay.Frame');
    TrigOff = destruct(Trials{Session},'Trigger.Stimulus.Frame');
    Activities = wind_roi(DFFs{Session},{TrigOn;TrigOff},'Window',Range);
%     Activities = cat(3,Activities{:});
    if DePre 
%         Values = Values - (squeeze(nanmean(Activities(:,1:(abs(Range(1))),:),2)));
    end
    if ZScore
        
    end
    
    Labels = destruct(Trials{Session},'Task'); % 1 is mem 2 is dis
    Activities(:,:,isnan(TempLabels)) = [];
    Labels(isnan(TempLabels)) = [];
    if Session > 1; TempSize = size(Activity.Normal,1); else; TempSize = 0 ; end
    
    [Activity] = task_activity(Activities,Labels,Activity); % n = cells
    [Correlation] = task_noise(Activities,Labels,Correlation,'AverageFR',Activity.Normal(TempSize+1:end,:),'Way',Way); % n = pairs
    Stats{Session} = [std(Correlation.Normal(:,1)) std(Correlation.Normal(:,2))];
%     Central = and(and(Activity.Normal(TempSize+1:end,1)>prctile(Activity.Normal(TempSize+1:end,1),40),Activity.Normal(TempSize+1:end,1)<prctile(Activity.Normal(TempSize+1:end,1),60)),...
%         (and(Activity.Normal(TempSize+1:end,2)>prctile(Activity.Normal(TempSize+1:end,2),40),Activity.Normal(TempSize+1:end,2)<prctile(Activity.Normal(TempSize+1:end,2),60))));
%     [CentralCorrelation] = task_noise(Activities(Central,:,:),Labels,CentralCorrelation); % n = central pairs
end

%% plot!!!!
Stats = cell2mat(Stats)
figure;plot([Stats(1:2:end); Stats(2:2:end)],'k');
axis([0.8 2.2 0.15 0.16])
Ax = gca;
Ax.XTick = [];
Ax.YTick = [0.15 0.16];
scatter_pretty([],Correlation,[]);
