% used for plotting PC1, average activity, both wrt light, etc WRT delay
% and stimulus

function plot_cue_traces(Index,varargin)
FPS = 4.68;%[11.18] %  22.39  for mesoscope... don't know...
Window = {[-1000 3000];[-1000 2000]};

DePre = false;
Smooth = [];
CI = false;
S = [];
Z = [];
Ax = [];
Zcore = [];
Hyper = false;
Normalize = false;
CCD = true;
OfAvg = false;

Smooth = [];
Smooth2 = [];
MirrorCue = false;

Split = false; % split task
Sub = false; % plot on existing axes

% this is only for data selection
Types = {'DelayResponsive';'StimulusResponsive';'Untriggerable'};
Light = false;

%% PASS ARGUMENTS TO CONTROLS
for I=1:2:numel(varargin)
    eval([varargin{I} '= varargin{I+1};']);
end

if Z
    Z = 'Z';
end

if Zcore
    Zcore = 'Zcore';
end
if S
    S = 'S';
end
if Ax
    Ax = 'Ax';
end

%% RIP THE RIGHT TYPES
% hard coded selections from index
% DFFs and Trials are cells with precursor cells of [TYPE,LIGHT] which
% could simply be 1,1 for e.g., popan trace
if ~iscell(Index)
    for Type = 1:length(Types)
        [DFFs{Type,1},Trials{Type,1}] = rip(Index,S,Z,Ax,Zcore,'DeNaN',Types{Type},'Active','Context');
    end
    if Light
        for Type = 1:size(Trials,1)
            DFFs{Type,2} = DFFs{Type,1};
            Trials{Type,2} = selector(Trials{Type,1},'Light');
            Trials{Type,1} = selector(Trials{Type,1},'NoLight');
        end
    end
elseif iscell(Index)
    if Light && size(Index{1},1) == 1
        if strcmp(Z,'Z')
            for S = 1:length(Index{1})
                 Index{1}{S} = zscore(Index{1}{S},[],'omitnan');
            end
        end
        DFFs{1,1} = Index{1}(:);
        DFFs{1,2} = Index{1}(:);
        Trials{1,1} = selector(Index{2}(:),'NoLight');
        Trials{1,2} = selector(Index{2}(:),'Light');
    else
        try % normal use, i.e only one type
            DFFs{1,1} = {Index{1}{1,:}};
            Trials{1,1} = {Index{2}{1,:}};
            if size(Index{1},1) > 1
                DFFs{1,1} = Index{1}{1,:};
                Trials{1,1} = Index{2}{1,:};
                DFFs{1,2} = Index{1}{2,:};
                Trials{1,2} = Index{2}{2,:};
            end
        catch % debug use (single sessoin)
            DFFs{1,1} = Index{1};
            Trials{1,1} = Index{2};
        end
    end
end

% smooth
if ~isempty(Smooth)
    for T = 1:size(DFFs,1)
        for L = 1:size(DFFs,2)
            for S = 1:length(DFFs{T,L})
                DFFs{T,L}{S} = gaussfilt(1:length(DFFs{T,L}{S}),DFFs{T,L}{S},Smooth);
%                 DFFs{T,L}{S} = medfilt1(DFFs{T,L}{S},Smooth,'omitnan','truncate');
%                         Trace(I,:) = medfilt1(Trace(I,:),Smooth,'omitnan','truncate');

%                 DFFs{T,L}{S} = smooth(DFFs{T,L}{S},Smooth)';
            end
        end
    end
end
% if ~OfAvg && MirrorCue
% for Z = 1:length(CueTraces); 
% if Trials{Z}(1).DB == 15
% CueTraces{Z} = - OutLDA;
%% extract traces
for Type = 1:size(DFFs,1)
    for LL = 1:size(DFFs,2)
        if MirrorCue
            [Traces{Type,LL}{1,1}, DP] = avg_triggered(DFFs{Type,LL},Trials{Type,LL},1,'Window',Window{1},'FPS',FPS,'DePre',DePre,'Smooth',Smooth2,'MirrorCue',true,'OfAvg',OfAvg);
            Traces{Type,LL}{1,2} = avg_triggered(DFFs{Type,LL},Trials{Type,LL},2,'Window',Window{2},'FPS',FPS,'DePre',DP,'Smooth',Smooth2,'MirrorCue',true,'OfAvg',OfAvg);
        else
            if ~OfAvg
                for Z = 1:length(DFFs{Type,LL})
                    if Trials{Type,LL}{Z}(1).DB == 15
                        DFFs{Type,LL}{Z} =  -DFFs{Type,LL}{Z};
                    end
                end
            end
            
%             Cue = swaparoo({'CueA';'CueB'},Trials{Type,LL}(1).DB}
            [Traces{Type,LL}{1,1}, DP] = avg_triggered(DFFs{Type,LL},selector(Trials{Type,LL},'CueA'),1,'Window',Window{1},'FPS',FPS,'DePre',DePre,'Smooth',Smooth2);
            Traces{Type,LL}{1,2} = avg_triggered(DFFs{Type,LL},selector(Trials{Type,LL},'CueA'),2,'Window',Window{2},'FPS',FPS,'DePre',DP,'Smooth',Smooth2);
            [Traces{Type,LL}{2,1}, DP] = avg_triggered(DFFs{Type,LL},selector(Trials{Type,LL},'CueB'),1,'Window',Window{1},'FPS',FPS,'DePre',DePre,'Smooth',Smooth2);
            Traces{Type,LL}{2,2} = avg_triggered(DFFs{Type,LL},selector(Trials{Type,LL},'CueB'),2,'Window',Window{2},'FPS',FPS,'DePre',DP,'Smooth',Smooth2);
            
            for Z = 1:size(DFFs{Type,LL},2)
                if Trials{Type,LL}{Z}(1).DB == 15
                    for SSS = 1:2
                        Temp = Traces{Type,LL}{1,SSS}(Z,:);
                        Traces{Type,LL}{1,SSS}(Z,:) = Traces{Type,LL}{2,SSS}(Z,:);
                        Traces{Type,LL}{2,SSS}(Z,:) = Temp;
                    end
                end
            end
        end
    end
end

%%
if Normalize
    if ~CCD
        for Task = 1:2
            Normalizer = nanmean(Traces{1}{Task,1}(:,11:end),2) .* ((Task.*2)-3);
            Normalizer = max(Normalizer,0.2);
            for LightCond = 1:2
                for Trig = 1:2
                    for TraceNumber = 1:size(Traces{LightCond}{Task,Trig},1)
                        Traces{LightCond}{Task,Trig}(TraceNumber,:) =  Traces{LightCond}{Task,Trig}(TraceNumber,:) ./ Normalizer(TraceNumber);
                    end
                end
            end
        end
    else
        for Z = 1:size(Traces{1}{1,1},1)
            if ~MirrorCue
                STD =  nanstd(cat(2,Traces{1,1}{1,1}(Z,:),Traces{1,1}{2,1}(Z,:)));
                %             STD =  nanstd(cat(2,Traces{1,1}{1,1}(Z,:),Traces{1,1}{2,1}(Z,:)));
                %             STD1 =  nanstd(Traces{1,1}{1,1}(Z,:));
                %             STD2 =  nanstd(Traces{1,1}{2,1}(Z,:));
            else
                STD =  nanstd(Traces{1,1}{1,1}(Z,:));
                %             STD =  nanstd(Traces{1,1}{1,1}(Z,:));
            end
            for LL = 1:2
                for Trig = 1:2
                    for Task = 1:(2 - MirrorCue)
                        Traces{1,LL}{Task,Trig}(Z,:) =  Traces{1,LL}{Task,Trig}(Z,:) ./ STD;
                    end
                    %                 Traces{1,LL}{1,Trig}(Z,:) =  Traces{1,LL}{1,Trig}(Z,:) ./ STD1;
                    %                 Traces{1,LL}{2,Trig}(Z,:) =  Traces{1,LL}{2,Trig}(Z,:) ./ STD2;
                end
            end
        end
    end
end

%% multiplot
% for Z = 1:size(Traces{1}{1,1},1)
%     figure;
%     plot(Traces{1}{1,1}(Z,:)')
%     hold on
%     plot(Traces{1}{2,1}(Z,:)')
% end

%% plot
Colours;
for Type = 1:size(DFFs,1)
    if ~Sub
        figure;
    end
    YMax =[];
    YMin = [];
    
    for Trigger = 1:2-Sub
        Range{Trigger} = round(Window{Trigger} ./ (1000./FPS));
        for Task = 1:2-MirrorCue
            if ~Sub
            if ~Split
                if Task == 1
                    if Trigger == 1
                        Axes(1) =subplot(1,20,1:11);
                    else
                        Axes(2) =subplot(1,20,13:20);
                    end
                end
            else
                if Trigger == 1
                    Axes(1,Task) =subplot(2,20,1 + (20*(Task-1)):11 + (20*(Task-1)));
                else
                    Axes(2,Task) =subplot(2,20,13 + (20*(Task-1)):20 + (20*(Task-1)));
                end
            end
            else
               Axes = gca; 
            end
            if ~MirrorCue
            Colour = swaparoo({Green;Orange},Task);
            else
               Colour = [0 0 0]; 
            end
            for L = 1:1+Light
                Trace = Traces{Type,L}{Task,Trigger};
                if CI && ~(Light && L == 1)
                    for II = 1:size(Traces{Type,L}{Task,Trigger},2)
                        if size(Traces{Type,L}{Task,Trigger},1) > 1
                            if all(isnan(Trace(:,II)))
                                CIs(II,:) = [0 0];
                            else
                                PD = fitdist(Trace(:,II),'Normal');
                                TempCI = paramci(PD);
                                CIs(II,:) = [TempCI(2,1) TempCI(1,1)];
                            end
                        else
                            CIs(II,:) = [Trace(:,II) Trace(:,II)];
                        end
                    end
                    Trace = nanmean(Trace,1);
                    patches([],CIs,[1:size(Trace,2)],'Colour',Colour)
                    hold on;
                    %                 YMax = max([max(CIs(:)) YMax]);
                    %                 YMin = min([min(CIs(:)) YMin]);
                    YMax = max([max(CIs(:)) YMax]);
                    YMin = min([min(CIs(:)) YMin]);
                    plot(Trace,'Color',Colour,'LineWidth',2)
                elseif ~Light
                    YMax = max([max(Trace(:)) YMax]);
                    YMin = min([min(Trace(:)) YMin]);
                    hold on;
                    for Cell = 1:size(Trace,1)
                        P = plot(Trace(Cell,:),'Color',(Colour) ,'LineWidth',2.5);
                        P.Color = cat(2,Colour,0.1);
                    end
                    plot(nanmean(Trace,1),'Color',(Colour) ,'LineWidth',3,'LineStyle','--')
                elseif Light
                    if and(Trigger == 1,or(and(L == 1 , Task == 1),Split))
                        patch([abs(Range{1}(1))+frame(600,FPS) abs(Range{1}(1))+frame(600,FPS) abs(Range{1}(1)) abs(Range{1}(1))],[-10000 10000 10000 -10000],Red,'FaceAlpha',0.5,'EdgeColor','none')
                    end
                    hold on;
                    Trace = nanmean(Trace,1);
                    YMax = max([max(Trace(1:end-1)) YMax]);
                    YMin = min([min(Trace(:)) YMin]);
                    plot(Trace,'Color',Colour,'LineWidth',2,'LineStyle','--')
                end
            end
        end
    end
    %
    %     YMin = YMin - 1;
    %     YMax = YMax + 1;
    %     YMax = 0.3;
    %     YMin = -0.2;
    %     YMax = 1.8;
    for F = 1:length(Axes(:))
        
        set(gcf, 'currentaxes', Axes(F));
        line([abs(Range{2-rem(F,2)}(1)) abs(Range{2-rem(F,2)}(1))],...
            [YMin YMax],'color','k','LineWidth',2);
        Ax = gca;
        Ax.YLim = [YMin YMax];
        if F ==2
            Ax.XLim = [1 abs(Range{2-rem(F,2)}(1))+Range{2-rem(F,2)}(2)+1];
            line([1 abs(Range{2-rem(F,2)}(1))+Range{2-rem(F,2)}(2)+1],...
                [0 0],'color','k','LineWidth',2);
            Ax.XTick = [1 abs(Range{2-rem(F,2)}(1)) abs(Range{2-rem(F,2)}(1))+Range{2-rem(F,2)}(2)+1];
            Ax.XTickLabel = {'-1000 ms';'0 ms';'+2000 ms'};
            Ax.YTick = [];
        else
            Ax.YTick = [YMin YMax];
            Ax.XLim = [1 abs(Range{2-rem(F,2)}(1))+Range{2-rem(F,2)}(2)+1];
            line([1 abs(Range{2-rem(F,2)}(1))+Range{2-rem(F,2)}(2)+1],...
                [0 0],'color','k','LineWidth',2);
            
            Ax.XTick = [1 abs(Range{2-rem(F,2)}(1)) abs(Range{2-rem(F,2)}(1))+Range{2-rem(F,2)}(2)+1];
            Ax.XTickLabel = {'-1000 ms';'0 ms';'+3200ms'} ;
        end
        
    end
end
