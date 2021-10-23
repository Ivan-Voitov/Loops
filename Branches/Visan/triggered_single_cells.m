function triggered_single_cells(Index,varargin)
% bla
NumCells = [];
FPS = 4.68;%[11.18] %  22.39  for mesoscope... don't know...
Window = [-1000 3200];
Smooth = [];
Ind = [];
Sort = [];
ResponseType = 'Triggerable';
LineLimit = -1;


%% PASS ARGUMENTS TO CONTROLS
for I=1:2:numel(varargin)
    eval([varargin{I} '= varargin{I+1};']);
end

Range = frame(Window,FPS);

%% get data
% rip
if ~iscell(Index)
    % need to rip out such that context A of TCD is same style as B in CCD
    [DFFs, Trials, Ripped] = rip(Index,'DeNaN','Hyper',ResponseType,'Active');
    [~, CCDTrials, ~] = rip(Index,'Context','Beh');
else
    DFFs = Index{1};
    Trials = Index{2};
    Ripped = Index{3};
end

% sort
Cells = [];
for Session = 1:length(DFFs)
    % cell # ; fitability (sort) ; session #
    Cells(end+1:end+size(DFFs{Session},1),:) = [(1:size(DFFs{Session},1))', Ripped(Session).Latency', Ripped(Session).Fitability', repmat(Session,[size(DFFs{Session},1) 1])];
    % store the triggers
    %     {session}{task}{cut}
    for Task = 1:3
        if Task < 3
            Inds = destruct(Trials{Session},'Task')==(3-Task);
            DelayTriggers{Session}{Task} = {(destruct(Trials{Session}(Inds),'Trigger.Pre.Frame') + 2); ...
                destruct(Trials{Session}(Inds),'Trigger.Delay.Frame');destruct(Trials{Session}(Inds),'Trigger.Stimulus.Frame')};
            StimulusTriggers{Session}{Task} = {destruct(Trials{Session}(Inds),'Trigger.Delay.Frame') ; ...
                destruct(Trials{Session}(Inds),'Trigger.Stimulus.Frame');destruct(Trials{Session}(Inds),'Trigger.Post.Frame')};
        else
            Inds = destruct(CCDTrials{Session},'Block')==Task-2 -(Trials{Session}(1).DB == +15);
            DelayTriggers{Session}{Task} = {(destruct(CCDTrials{Session}(Inds),'Trigger.Pre.Frame') + 2); ...
                destruct(CCDTrials{Session}(Inds),'Trigger.Delay.Frame');destruct(CCDTrials{Session}(Inds),'Trigger.Stimulus.Frame')};
            StimulusTriggers{Session}{Task} = {destruct(CCDTrials{Session}(Inds),'Trigger.Delay.Frame') ; ...
                destruct(CCDTrials{Session}(Inds),'Trigger.Stimulus.Frame');destruct(CCDTrials{Session}(Inds),'Trigger.Post.Frame')};
        end
    end
end

%% sort by latency to have a consistent indexing
if ~isempty(Sort)
    if strcmp(Sort,'Latency')
        [~, TempInd] = sort(Cells(:,2),'ascend');
    elseif strcmp(Sort,'Fitability')
        [~, TempInd] = sort(Cells(:,3),'ascend');
    end
    Cells = Cells(TempInd,:);
end

%% plot
if isempty(Ind)
    Ind = randperm(length(Cells));
    % elseif isempty(NumCells)
end

NumCells = length(Ind);

Done = 0;
for C = 1:length(Ind)
    if ~isnan(Cells(Ind(C),2)) %latency is not missing
        figure;
        Session = Cells(Ind(C),4);
        Raw = DFFs{Session}(Cells(Ind(C),1),:);
        for Task = 1:3
            Triggered{1,Task} = wind_roi(Raw,DelayTriggers{Session}{Task},'Window',Range);
            Triggered{2,Task} = wind_roi(Raw,StimulusTriggers{Session}{Task},'Window',Range);
        end
        for Plot = 1:2
            subplot(1,2,Plot)
            if strcmp(ResponseType,'DelayResponsive')
                [Ax{Plot}] = plot_single_cell(Triggered(1,1:2+(Plot==2)),Range,LineLimit);
            elseif strcmp(ResponseType,'StimulusResponsive')
                [Ax{Plot}] = plot_single_cell(Triggered(2,1:2+(Plot==2)),Range,LineLimit);
            else
                [Ax{Plot}] = plot_single_cell(Triggered,Range,LineLimit);
            end
        end
        Ax{1}.YLim = max([Ax{1}.YLim; Ax{2}.YLim]);
        Ax{2}.YLim = max([Ax{1}.YLim; Ax{2}.YLim]);
        
        suptitle(num2str(Ind(C)));
        Done = Done + 1;
    end
    if Done >= NumCells
        break
    end
end
end

function [Axes] = plot_single_cell(Triggered,Range,LineLimit)
% define plotting variables
Colours;
if size(Triggered,2) == 2 % if TCD
    Colour = {Blue;Red};
    CCD = false;
else % if CCD
    Colour = {Blue;Orange;Green};
    CCD = true;
end
set(gcf, 'Position',  [500, 300, 350, 500])
hold on;
YMax =[];
YMin = [];
if size(Triggered,1) == 2
    Axes(1) =subplot(1,2,1);hold on;
    Axes(2) =subplot(1,2,2);hold on;
else
    Axes(1) =gca; hold on;
end
for Trigger = 1:size(Triggered,1)
    set(gcf, 'currentaxes', Axes(Trigger));
    for Task = [1:2]+CCD
        if LineLimit ~= -1
            [~,Ind] = sort(squeeze(sum(isnan(Triggered{Trigger,Task}),2)));
            Triggered{Trigger,Task} = Triggered{Trigger,Task}(:,:,Ind);
        end
        for Line = 1:min(size(Triggered{Trigger,Task},3),LineLimit)
            P = plot(Triggered{Trigger,Task}(1,:,Line),'color',((Colour{Task} + [1 1 1]) ./ 2),'LineWidth',1);
            P.Color(4) = 0.25;
            YMin = min([YMin min(Triggered{Trigger,Task}(1,:,Line))]);
            YMax = max([max(Triggered{Trigger,Task}(1,:,Line)) YMax]);
        end
        hold on;
    end
    for Task = [1:2]+CCD
        plot(squeeze(nanmean(Triggered{Trigger,Task},3)),'color',Colour{Task},'LineWidth',2)
    end
    axis([1 size((Triggered{Trigger,Task}(1,:,Line)),2) YMin YMax]);
    line([abs(Range(1)) abs(Range(1))],...
        [YMin YMax],'color','k','LineWidth',2);
    Axes(Trigger).XTick = [1 abs(Range(1)) size((Triggered{Trigger,Task}(1,:,Line)),2)];
    Axes(Trigger).XTickLabel = {'-1000 ms';'0 ms';'+3200 ms'};
    ylabel('DFF');
    
end
end