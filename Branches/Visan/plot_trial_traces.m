% used for plotting PC1, average activity, both wrt light, etc WRT delay
% and stimulus

function plot_trial_traces(Index,varargin)
CCD = false;
Cross = false;
DCD = false;

FPS = 4.68;%[11.18] %  22.39  for mesoscope... don't know...
Window = {[-1000 3200];[-1000 2000]};

DePre = false;
Smooth = [];
CI = false;
S = [];
Z = [];
Zcore = [];
Hyper = true;
Normalize = false;

Split = false; % split task
Sub = false; % plot on existing axes

% this is only for data selection
Types = {'DelayResponsive';'StimulusResponsive';'Untriggerable'};
Light = false;

OnlyDelay = false;

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
    S = 'Spikes';
end
if Hyper
    Hyper = 'Hyper';
else
    Hyper = 'Super';
end

%% RIP THE RIGHT TYPES
% hard coded selections from index
% DFFs and Trials are cells with precursor cells of [TYPE,LIGHT] which
% could simply be 1,1 for e.g., popan trace
if ~iscell(Index)
    if ~CCD && ~DCD
        for Type = 1:length(Types)
            [DFFs{Type,1},Trials{Type,1}] = rip(Index,S,Z,Zcore,swap({Hyper;'DistractorCue'},Cross+1),'DeNaN',Types{Type},'Active');
        end
    elseif ~CCD
        for Type = 1:length(Types)
            [DFFs{Type,1},Trials{Type,1}] = rip(Index,S,Z,Zcore,'Rotext','DeNaN',Types{Type},'Active');
        end
    else
        for Type = 1:length(Types)
            [DFFs{Type,1},Trials{Type,1}] = rip(Index,S,Z,Zcore,'Context','DeNaN',Types{Type},'Active');
        end
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


%% here different from plot_task_traces
for S = 1:length(DFFs{1})
    if Smooth
        for Cond = 1:size(DFFs,2)
            DFFs{1,Cond}{S} = gaussfilt(1:length(DFFs{1,Cond}{S}),DFFs{1,Cond}{S},Smooth);
        end
    end
    
    %% extract traces
    for Type = 1:size(DFFs,1)
        for LL = 1:size(DFFs,2)
            if CCD
                for B = 1:2
                    TrigOn = destruct(Trials{Type,LL}{S}(destruct(Trials{Type,LL}{S},'Block')==B-1),'Trigger.Delay.Frame');
                    TrigOff = destruct(Trials{Type,LL}{S}(destruct(Trials{Type,LL}{S},'Block')==B-1),'Trigger.Stimulus.Frame');
                    [Traces{Type,LL}{B,1}] = wind_roi(DFFs{Type,LL}{S},{TrigOn;TrigOff},'Window',frame(Window{1},FPS)-1);
                    
                    TrigOn = destruct(Trials{Type,LL}{S}(destruct(Trials{Type,LL}{S},'Block')==B-1),'Trigger.Stimulus.Frame');
                    TrigOff = destruct(Trials{Type,LL}{S}(destruct(Trials{Type,LL}{S},'Block')==B-1),'Trigger.Post.Frame');
                    [Traces{Type,LL}{B,2}] = wind_roi(DFFs{Type,LL}{S},{TrigOn;TrigOff},'Window',frame(Window{2},FPS)-1);
                end
            elseif DCD
                for B = 1:2
                    TrigOn = destruct(Trials{Type,LL}{S}(destruct(Trials{Type,LL}{S},'DB')==swap([-15 15],B)),'Trigger.Delay.Frame');
                    TrigOff = destruct(Trials{Type,LL}{S}(destruct(Trials{Type,LL}{S},'DB')==swap([-15 15],B)),'Trigger.Stimulus.Frame');
                    [Traces{Type,LL}{B,1}] = wind_roi(DFFs{Type,LL}{S},{TrigOn;TrigOff},'Window',frame(Window{1},FPS)-1);
                    
                    TrigOn = destruct(Trials{Type,LL}{S}(destruct(Trials{Type,LL}{S},'DB')==swap([-15 15],B)),'Trigger.Stimulus.Frame');
                    TrigOff = destruct(Trials{Type,LL}{S}(destruct(Trials{Type,LL}{S},'DB')==swap([-15 15],B)),'Trigger.Post.Frame');
                    [Traces{Type,LL}{B,2}] = wind_roi(DFFs{Type,LL}{S},{TrigOn;TrigOff},'Window',frame(Window{2},FPS)-1);
                end
            else
                for T = 1:2
                    TrigOn = destruct(Trials{Type,LL}{S}(destruct(Trials{Type,LL}{S},'Task')==3-T),'Trigger.Delay.Frame');
                    TrigOff = destruct(Trials{Type,LL}{S}(destruct(Trials{Type,LL}{S},'Task')==3-T),'Trigger.Stimulus.Frame');
                    [Traces{Type,LL}{T,1}] = wind_roi(DFFs{Type,LL}{S},{TrigOn;TrigOff},'Window',frame(Window{1},FPS)-1);
                    
                    TrigOn = destruct(Trials{Type,LL}{S}(destruct(Trials{Type,LL}{S},'Task')==3-T),'Trigger.Stimulus.Frame');
                    TrigOff = destruct(Trials{Type,LL}{S}(destruct(Trials{Type,LL}{S},'Task')==3-T),'Trigger.Post.Frame');
                    [Traces{Type,LL}{T,2}] = wind_roi(DFFs{Type,LL}{S},{TrigOn;TrigOff},'Window',frame(Window{2},FPS)-1);
                end
            end
        end
    end
    
    if Cross % only works for single sessions
        load(Index.Name,'Trial');
        TempDB = Trial(and(Index.Combobulation,destruct(Trial,'Task')==2)).DB;
        TempTrial = Trials{1}{1}(destruct(Trials{1}{1},'Task')==2);
        Traces{1}{1,1}(:,:,(destruct(TempTrial,'DB') == TempDB)) = -Traces{1}{1,1}(:,:,(destruct(TempTrial,'DB') == TempDB));
        Traces{1}{1,2}(:,:,(destruct(TempTrial,'DB') == TempDB)) = -Traces{1}{1,2}(:,:,(destruct(TempTrial,'DB') == TempDB));
    end
    
    %% plot
    Colours;
%     if Cross
%         Red = Orange;
%     end
    for Type = 1:size(DFFs,1)
        if ~Sub
            figure;
        end
        YMax =[];
        YMin = [];
        
        for Trigger = 1:2-OnlyDelay
            Range{Trigger} = round(Window{Trigger} ./ (1000./FPS));
            for Context = 1:2
                if ~OnlyDelay
                    if ~Split
                        if Context == 1
                            if Trigger == 1
                                Axes(1) =subplot(1,20,1:11);
                            else
                                Axes(2) =subplot(1,20,13:20);
                            end
                        end
                    else
                        if Trigger == 1
                            Axes(1,Context) =subplot(2,20,1 + (20*(Context-1)):11 + (20*(Context-1)));
                        else
                            Axes(2,Context) =subplot(2,20,13 + (20*(Context-1)):20 + (20*(Context-1)));
                        end
                    end
                else
                    Axes = gca;
                end
                %                 if Context == 1; Colour = Blue; else; Colour = Red; end
                Colour = swap({swap({Blue;Orange},DCD+CCD+1);swap({Red;Green},DCD+CCD+1)},Context);
                for L = 1:1+Light
                    Trace = squeeze(Traces{Type,L}{Context,Trigger})';
                    if CI && ~(Light && L == 1)
                        for II = 1:size(Traces{Type,L}{Context,Trigger},2)
                            if size(Traces{Type,L}{Context,Trigger},3) > 1
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
                        YMax = max([prctile(CIs(:),80) YMax]);
                        YMin = min([prctile(CIs(:),80) YMin]);
                        plot(Trace,'Color',Colour,'LineWidth',2)
                    elseif ~Light
                        YMax = max([max(Trace(:)) YMax]);
                        YMin = min([min(Trace(:)) YMin]);
                        hold on;
                        for Cell = 1:size(Trace,1)
                            P = plot(Trace(Cell,:),'Color',(Colour) ,'LineWidth',1);
                            P.Color = cat(2,Colour,0.1);
                        end
                        plot(nanmean(Trace,1),'Color',(Colour) ,'LineWidth',3,'LineStyle','--')
                    elseif Light && L == 1
                        if and(Trigger == 1,or(and(L == 1 , Context == 1),Split))
                            patch([abs(Range{1}(1))+frame(600,FPS) abs(Range{1}(1))+frame(600,FPS) abs(Range{1}(1)) abs(Range{1}(1))],[-100 100 100 -100],Red,'FaceAlpha',0.5,'EdgeColor','none')
                        end
                        hold on;
                        Trace = nanmean(Trace,1);
                        YMax = max([max(Trace(1:end-1)) YMax]);
                        YMin = min([min(Trace(:)) YMin]);
                        plot(Trace,'Color',Colour,'LineWidth',2,'LineStyle','--')
                    elseif Light && L == 2
                        Trace = nanmean(Trace,1);
                        YMax = max([max(Trace(1:end-1)) YMax]);
                        YMin = min([min(Trace(:)) YMin]);
                        plot(Trace,'Color',Colour,'LineWidth',2)
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
            if ~OnlyDelay
                set(gcf, 'currentaxes', Axes(F));
            end
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
    
    
end

