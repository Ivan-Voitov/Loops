function [Min,Max,NumTrials] = list_all_cells(Index,varargin)
Normalize = true;
Bounds = [0.1 2];
Spikes = false;
OnlyEven = false;
OnlyOdd = false;
OnlyDiscrimination = false;
OnlyMemory = false;
TomMemory = false;
TomDiscrimination = false;
Smooth = [];
FPS = 4.68;
Z = false;
% ThresholdLatency = false;
HighLight = [];
DFFsIn = [];
Light = [];
Types = {'DelayResponsive';'StimulusResponsive'};

%% PASS ARGUMENTS TO CONTROLS
for I=1:2:numel(varargin)
    eval([varargin{I} '= varargin{I+1};']);
end

if Spikes; S = 'S'; Z = ''; else; Z = 'Z'; S = ''; end % weird way of doing this...
if ~isempty(DFFsIn) && Z == 'Z'; Z = true;end
%% load data
if ~exist('Traces','var')
    for CellType = 1:length(Types)
        if ~isempty(DFFsIn)
            [~,Trials,Ripped{CellType}] = rip(Index,S,Z,'Active',swaparoo({'Super';'Hyper'},CellType),'DeNaN',Types{CellType},'Beh'); % can't beh here because need to get ripped
            DFFs = DFFsIn;
        else
            [DFFs,Trials,Ripped{CellType}] = rip(Index,S,Z,'Active',swaparoo({'Super';'Hyper'},CellType),'DeNaN',Types{CellType});
        end
        if OnlyEven
            for Session = 1:length(Trials); Trials{Session} = Trials{Session}(2:2:end); end
            [X{CellType},Sort] = sort(cat(2,Ripped{CellType}.OddLatency));
        elseif OnlyOdd
            for Session = 1:length(Trials); Trials{Session} = Trials{Session}(1:2:end); end
            [X{CellType},Sort] = sort(cat(2,Ripped{CellType}.EvenLatency));
        elseif OnlyMemory
            for Session = 1:length(Trials); Trials{Session} = selector(Trials{Session},'Memory'); end
            [X{CellType},Sort] = sort(cat(2,Ripped{CellType}.DiscriminationLatency));
        elseif OnlyDiscrimination
            for Session = 1:length(Trials); Trials{Session} = selector(Trials{Session},'Discrimination'); end
            [X{CellType},Sort] = sort(cat(2,Ripped{CellType}.MemoryLatency));
        elseif TomDiscrimination
            for Session = 1:length(Trials); Trials{Session} = selector(Trials{Session},'Discrimination'); end
            [X{CellType},Sort] = sort(cat(2,Ripped{CellType}.Latency));
        elseif TomMemory
            for Session = 1:length(Trials); Trials{Session} = selector(Trials{Session},'Memory'); end
            [X{CellType},Sort] = sort(cat(2,Ripped{CellType}.Latency));
        else
            [X{CellType},Sort] = sort(cat(2,Ripped{CellType}.Latency));
        end
        
        if ~isempty(Light)
            if Light == 1
                Trials= selector(Trials,'Light');
            elseif Light == 2
                for Z = 1:length(Trials)
                Trials{Z}= Trials{Z}(randperm(length(selector(Trials{Z},'Light'))));
                end
            else
                Trials= selector(Trials,'NoLight');
            end
        end
        
        Traces{1,CellType} = (avg_triggered(DFFs,Trials,1,'Window',[0 3200],'Sort',Sort,'Smooth',Smooth,'FPS',FPS,'Z',Z))';
        Traces{2,CellType} = (avg_triggered(DFFs,Trials,2,'Window',[0 2000],'Sort',Sort,'Smooth',Smooth,'FPS',FPS,'Z',Z))';
        
        %     if ThresholdLatency
        %         Traces{1,CellType}(:,X>=ThresholdLatency) = [];
        %         Traces{2,CellType}(:,X>=ThresholdLatency) = [];
        %     end
        
        
    end
    clearvars DFFsIn
end



%% normalize
if Normalize
    if exist('Min','var')
        for CellType = 1:length(Types)
            if ~Spikes
                for Trigger = 1:2
                    Traces{Trigger,CellType} = Traces{Trigger,CellType} - Min{CellType};
                end
            end
        end
    else
        for CellType = 1:length(Types)
            if ~Spikes
                Min{CellType} = prctile(cat(1,Traces{2,CellType},Traces{1,CellType}),10);
                for Trigger = 1:2
                    Traces{Trigger,CellType} = Traces{Trigger,CellType} - Min{CellType};
                end
            end
        end
    end
    if exist('Max','var')
        for CellType = 1:length(Types)
            for Trigger = 1:2
                for Cell = 1:size(Traces{Trigger,CellType},2)
                    Traces2{Trigger,CellType}(:,Cell) = Traces{Trigger,CellType}(:,Cell) ./ Max{CellType}(Cell);
                end
            end
        end
    else
        for CellType = 1:length(Types)
            %         if CellType == 1
            %             Max = prctile(cat(1,Traces{2,CellType},Traces{1,CellType}(1:size(Traces{1,CellType},1),:)),75);
            Max{CellType} = max(cat(1,Traces{2,CellType},Traces{1,CellType}(1:size(Traces{1,CellType},1),:)));
            
            %         else
            %             Max = prctile(cat(1,Traces{2,CellType},Traces{1,CellType}(1:size(Traces{1,CellType},1),:)),75);
            %         end
            for Trigger = 1:2
                for Cell = 1:size(Traces{Trigger,CellType},2)
                    if Normalize == 1
                        Traces2{Trigger,CellType}(:,Cell) = Traces{Trigger,CellType}(:,Cell) ./ Max{CellType}(Cell);
                    elseif Normalize == 2
                        Val(Cell)  =min(X{CellType}(Cell),length(Traces{CellType,CellType}(:,(Cell))));
                        Val(Cell) = round(max(Val(Cell),1));
                        Traces2{CellType,CellType}(:,Cell) = Traces{CellType,CellType}(:,Cell) ./  Traces{CellType,CellType}(Val(Cell),Cell);
                    end
                end
            end
        end
    end
else
    Traces2 = Traces;
end

%% plot
% NORMALIZED TO [ 80] PERCENT RANGE OF MEAN SUBTRACTED TRACE?
if length(Types) ==2
DelayLines = cat(2,Traces2{1,1},Traces2{1,2});
StimulusLines = cat(2,Traces2{2,1},Traces2{2,2});
else
    DelayLines =Traces2{1,1};
StimulusLines = Traces2{2,1};
end
% TempSize = cellfun(@size,DFFs{1},'UniformOutput',false);
% TempSize = cat(1,TempSize{:});
% TempSize = sum(TempSize(:,1));

figure;

subplot(1,20,1:11)

imagesc(DelayLines(:,:)',Bounds)
for H = 1:length(HighLight)
    line([1 2],[HighLight(H) HighLight(H)],'color','k','LineWidth',3);
end
Ax = gca;
Ax.YTick = [];
Ax.XTick = [];
% line([0.5 size(DelayLines,1)+0.5],[TempSize TempSize],'color','k','LineWidth',2)

    subplot(1,20,12:20)
    imagesc(StimulusLines(:,:)',Bounds)
    Ax = gca;
    Ax.YTick = [];
    Ax.XTick = [];

% line([0.5 size(StimulusLines,1)+0.5],[TempSize TempSize],'color','k','LineWidth',2)

CB = colorbar;
CB.Ticks = [];


