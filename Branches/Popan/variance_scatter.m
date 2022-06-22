function variance_scatter(Index,varargin)
DePre = false;
Window = [0 3200]; % this is because i dont want to include more time steps for
% one task over the other which might happen by chance at very rare delay
% lengths
ZScore = false; % (across all trials)
DelayResponsive = false;
Based = true;
Threshold= 10^-3; % this basically zero (if 10% dff in 1 frame of 1 of 10 trials)
Segments = 100;
CCD = false;
FPS = 4.68;

%% PASS ARGUMENTS TO CONTROLS
for I=1:2:numel(varargin)
    eval([varargin{I} '= varargin{I+1};']);
end

if ~iscell(Index)
    if DelayResponsive
        [DFFs,Trials] = rip(Index,'S',swap({'Super';'Context'},CCD+1),'DeNaN','DelayResponsive','Active');
    elseif Based
        [DFFs,Trials] = rip(Index,'S',swap({'Super';'Context'},CCD+1),'DeNaN','Active','NoStimulusResponsive'); 
    else
        [DFFs,Trials] = rip(Index,'S',swap({'Super';'Context'},CCD+1),'DeNaN','Active');
    end
else
    DFFs = Index{1}; Trials = Index{2};
end

Range = frame(Window,FPS);

%% extract values
Activity = [];
% Correlation = [];
% CentralCorrelation = [];
for Session = 1:length(DFFs)
    % all trials
    TrigOn = destruct(Trials{Session},'Trigger.Delay.Frame');
    TrigOff = destruct(Trials{Session},'Trigger.Stimulus.Frame');
    if ZScore
        DFFs{Session} = zscore(DFFs{Session}',[],'omitnan')';
    end
    
    Activities = wind_roi(DFFs{Session},{TrigOn;TrigOff},'Window',[Range(1)+1 Range(2)]);
%     Activities = cat(3,Activities{:});
    if DePre 
%         Values = Values - (squeeze(nanmean(Activities(:,1:(abs(Range(1))),:),2)));
    end
    if ZScore
        
    end

%     min(Activities)
    
    Labels = destruct(Trials{Session},swap({'Task';'Block'},CCD+1)); % 1 is mem 2 is dis
%     if Session > 1; TempSize = size(Activity.Normal,1); else; TempSize = 0 ; end
    [Activity] = context_activity(Activities,Labels,Activity,'Threshold',Threshold); % n = cells
    
%     [Correlation] = task_noise(Activities,Labels,Correlation,'AverageFR',Activity.Normal(TempSize+1:end,:)); % n = pairs
%     Central = and(and(Activity.Normal(TempSize+1:end,1)>prctile(Activity.Normal(TempSize+1:end,1),40),Activity.Normal(TempSize+1:end,1)<prctile(Activity.Normal(TempSize+1:end,1),60)),...
%         (and(Activity.Normal(TempSize+1:end,2)>prctile(Activity.Normal(TempSize+1:end,2),40),Activity.Normal(TempSize+1:end,2)<prctile(Activity.Normal(TempSize+1:end,2),60))));
%     [CentralCorrelation] = task_noise(Activities(Central,:,:),Labels,CentralCorrelation); % n = central pairs
end

%% plot!!!!
% Colours;

% subplot(2,2,[1 3]);
scatter_sym((Activity.Normal),(Activity.Shifted),'Labels',{'Discrimination';'Memory'},'Segments',Segments,'PointSize',14);
% scatter_sym((Activity.CrossedMemory),(Activity.CrossedDiscrimination),'Labels',{'Discrimination';'Memory'},'Colours',{Blue;Red});
% axis([Threshold (0.7) Threshold (0.7)])
% 
% [~, ~] = tight_fig(1, 1, 0.02, [0.1 0.1], [0.1 0.1],1,600,600);
% scatter_sym(log(Activity.Normal),log(Activity.Shifted),'Labels',{'Discrimination';'Memory'},'Colours',{Blue;Red},'Segments',50);
% title('Average delay activity per task');
% 
% [~, ~] = tight_fig(1, 1, 0.02, [0.1 0.1], [0.1 0.1],1,600,600);
% scatter_sym(sqrt(Activity.Normal),sqrt(Activity.Shifted),'Labels',{'Discrimination';'Memory'},'Colours',{Blue;Red},'Segments',50);
% title('Average delay activity per task');
