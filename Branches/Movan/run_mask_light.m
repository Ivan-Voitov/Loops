function run_mask_light(Trials,Datas,varargin)
Window =  frame(600,60);
FPS = 22.39;
EnMouse = true;
Imaging = false;
Masking = false;
Type = 3;
Omit = [];

for I = 1:2:numel(varargin)
    if ~exist(varargin{I},'var')
        sprintf('Warning: one of the ParseArgs did not exist \r');
    end
    eval([varargin{I} '= varargin{I+1};']);
end

ImagingWindow = frame(600,FPS);

if Imaging
    Index = Trials;
    
    Remove = false(length(Index),1); clearvars TempNames
    for Session = 1:length(Index)
        TempName = strsplit(Index(Session).Name,'_');
        TempNames{Session} = cat(2,TempName{1},'_',TempName{2});
        if any(strcmp(TempNames{Session},TempNames(1:end-1)))
            Remove(Session) = true;
        end
    end
    
    Index(Remove) = [];
    
    if ~isempty(Omit)
        Index(Omit) = [];
    end
    Trials = []; Datas = []; Pupils = [];
    for Session = 1:length(Index)
        Temp = load(Index(Session).Name,'Trial','Data','Pupil','IgnoreSeries');
        Trials{end+1} = Temp.Trial(~destruct(Temp.Trial,'Ignore'));
        Datas{end+1} = Temp.Data(~destruct(Temp.Trial,'Ignore'));
        Pupils{end+1} = nan;
        if isfield(Temp,'Pupil')
            if ~isempty(Temp.Pupil)
                Temp.Pupil(Temp.IgnoreSeries,:) = nan; %Temp.Pupil(Temp.Pupil(:,4)==1,:) = nan;
                Pupils{end} = Temp.Pupil;
            end
        end
    end
    
%     Temp = selector(Trials,Datas,'NoReset','Post');
    Temp = selector(Trials,Datas,'NoReset','Post','Nignore','HasFrames');

%     Pupils{24} = nan;
    Trials = Temp{1}; Datas = Temp{2}; clearvars Temp
    
end

%% organize
if isempty(Datas)
    Datas = Trials{2};
    Trials = Trials{1};
end

if ~iscell(Trials)
    if EnMouse
        for I = 1:length(Trials); MouseNames{I} = Trials(I).MouseName; end
        Sessions = unique(MouseNames);
        for I = 1:length(Trials); S(I) = find(strcmp(Trials(I).MouseName,Sessions)); end
    else
        for I = 1:length(Trials); FileNames{I} = Trials(I).FileName; end
        Sessions = unique(FileNames);
        for I = 1:length(Trials); S(I) = find(strcmp(Trials(I).FileName,Sessions)); end
    end
    
    for Session = 1:length(Sessions)
        NewTrials(Session) = {Trials(S==Session)};
        NewDatas(Session) = {Datas(S==Session)};
    end
    Trials = NewTrials; Datas = NewDatas; clearvars NewTrials NewDatas;
end

%% extract triggered data
Speed = cell(length(Trials),4,2);
for Session = 1:length(Trials)
    if ~isempty(Trials{Session})
        for Task = 1:2
            clearvars Triggers
            Trial = Trials{Session}(3 - destruct(Trials{Session},'Task') == Task);
            Data = Datas{Session}(3 - destruct(Trials{Session},'Task') == Task);
            Condition = false(length(Trial),4);
            Triggers(1,:) = destruct(Trial,'Trigger.Delay.Line');
            Triggers(2,:) = destruct(Trial,'Trigger.Stimulus.Line');
            if Imaging
                TrigOn = destruct(Trial,'Trigger.Delay.Frame');
                TrigOff = destruct(Trial,'Trigger.Delay.Frame') + ImagingWindow;
                if ~all(all(isnan(Pupils{Session})))
                    Pupil = (Pupils{Session}(:,3) - nanmean(Pupils{Session}(:,3),1));
%                     Pupil = zscore(Pupils{Session}(:,3),[],'omitnan');
                    %                       Pupil = Pupils{Session}(:,3);
                else
                    Pupil = nan;
                end
            end
            %             Triggers(2,:) = destruct(Trial,'Trigger.Stimulus.Line') - frame(600,60);
            %             Triggers(3,:) = destruct(Trial,'Trigger.Stimulus.Line');
            if ~Imaging
                for On = 1:2
                    for Light = 1:2
                        % all combinations of maskon and light on
                        Condition(:,1 + (On-1)*2) = and(destruct(Trial,'MaskOn') ~= On+(On==2) , destruct(Trial,'LightOn') ~= On+(On==2));
                        if Masking
                            Condition(:,2 + (On-1)*2)  = and(destruct(Trial,'MaskOn') == On+(On==2), destruct(Trial,'LightOn') ~= On+(On==2));
                        else
                            Condition(:,2 + (On-1)*2)  = destruct(Trial,'LightOn') == On+(On==2);
                        end
                        %                     Condition(:,2 + (On-1)*3) = and(destruct(Trial,'MaskOn') == On , destruct(Trial,'LightOn') ~= On);
                        %                     Condition(:,3 + (On-1)*3)  = destruct(Trial,'LightOn') == On;
                    end
                end
            else
                for Light = 1:2
                    Condition(:,[1 3]) = repmat(destruct(Trial,'Light') == 0,[1 2]);
                    Condition(:,[2 4]) = repmat(destruct(Trial,'Light') == 1,[1 2]);
                end
                
            end
            
            for C = 1:4
                %                 On = rem(C-1,3) + 1;
                if C > 2 && Imaging
                    Pupila = [];
                    TT = 1;
                    for T = find(Condition(:,C))'+ 1
                        try
                            Pupila(TT) = nanmean(Pupil(TrigOn(T):TrigOff(T)));
                        catch
                            Pupila(TT) = nan;
                        end
                        TT = TT + 1;
                    end
                    Speed{Session,C,Task} = nanmean(Pupila);
                else
                    On = ceil(C/2);
                    TT = 1;
                    Speeds = [];
                    for T = find(Condition(:,C))'
                        try
                            Speeds(TT) = nanmean(Data{T}(Triggers(On,T):Triggers(On,T)+Window,4));
                        catch
                            Speeds(TT) = nanmean(Data{T}(Triggers(On,T):end,4));
                        end
                        TT = TT + 1;
                    end
                    Speed{Session,C,Task} = nanmean(Speeds);
                end
            end
        end
    end
end

Remove = false(size(Speed,1),1);
for M = 1:size(Speed,1)
    if isempty(Speed{M,1,1})
        Remove(M) = true;
    end
end
Speed(Remove,:,:) = [];

%% plot

figure; Colours;
set(gcf, 'Position',  [400, 100, 400, 600])
if Type == 1
    for K = 1:4
        ToPlot(K,:,1) = (cell2mat(cellfun(@mean,Speed(:,K,1),'UniformOutput',false)));
        ToPlot(K,:,2) = (cell2mat(cellfun(@mean,Speed(:,K,2),'UniformOutput',false)));
    end
    for On = 1:2
        subplot(1,2,On);
        hold on;
        
        plot([ToPlot(((On-1)*2)+1,:,1); ToPlot(((On-1)*2)+2,:,1)],'LineWidth',1,'color',Grey); hold on
        plot([repmat(3,[1 size(ToPlot,2)]); repmat(4,[1 size(ToPlot,2)])],[ToPlot(((On-1)*2)+1,:,2); ToPlot(((On-1)*2)+2,:,2)],'LineWidth',1,'color',Grey); hold on
        
        
        scatter(ones(size(Speed,1),1),ToPlot(((On-1)*2)+1,:,1),'MarkerFaceColor','none','MarkerEdgeColor',Blue,'LineWidth',1,'MarkerFaceColor',White)
        scatter(ones(size(Speed,1),1)+1,ToPlot(((On-1)*2)+2,:,1),'MarkerFaceColor','none','MarkerEdgeColor',Blue,'LineWidth',1,'MarkerFaceColor',Orange)
        
        scatter(ones(size(Speed,1),1)+2,ToPlot(((On-1)*2)+1,:,2),'MarkerFaceColor','none','MarkerEdgeColor',Red,'LineWidth',1,'MarkerFaceColor',White)
        scatter(ones(size(Speed,1),1)+3,ToPlot(((On-1)*2)+2,:,2),'MarkerFaceColor','none','MarkerEdgeColor',Red,'LineWidth',1,'MarkerFaceColor',Orange)
        
        axis([0.5 4.5 0 100]);
        Ax = gca; Ax.XTick = [1.5 3.5]; Ax.YTick = [0 50 100];
        Ax.XTickLabel = {'D';'WM'};
        plot([0.75 1.25],[nanmedian(ToPlot(((On-1)*2)+1,:,1)) nanmedian(ToPlot(((On-1)*2)+1,:,1))],'k','LineWidth',2)
        plot([1.75 2.25], [nanmedian(ToPlot(((On-1)*2)+2,:,2)) nanmedian(ToPlot(((On-1)*2)+2,:,2))],'k','LineWidth',2)
        plot([2.75 3.25],[nanmedian(ToPlot(((On-1)*2)+1,:,1)) nanmedian(ToPlot(((On-1)*2)+1,:,1))],'k','LineWidth',2)
        plot([3.75 4.25], [nanmedian(ToPlot(((On-1)*2)+2,:,2)) nanmedian(ToPlot(((On-1)*2)+2,:,2))],'k','LineWidth',2)
        if On == 1
            xlabel('Delay onset');
        elseif On == 2 && ~Imaging
            xlabel('Stimulus onset');
        elseif On == 2 && Imaging
            xlabel('Pupil diameter');
        end
        if Imaging && On == 2
            Ax.YLim = [-2 2];
            Ax.YTick = [-2 0 2];
            
            
        end
        %                 if C == 1
        %             ylabel('Delay onset')
        %         elseif C == 4
        %             ylabel('Delay end');
        %         elseif C == 7
        %             xlabel('No light');
        %             ylabel('Stimulus')
        %         elseif C == 8
        %             xlabel('Masking light');
        %         elseif C == 9
        %             xlabel('Silencing light');
        %         end
    end
    
elseif Type == 2
    for On = 1:2
        for K = 1:2
            C = K + (On-1)*2;
            
            subplot(2,2,On + (K-1)*2);
            hold on;
            ToPlot(C,:,1) = (cell2mat(cellfun(@mean,Speed(:,C,1),'UniformOutput',false)));
            ToPlot(C,:,2) = (cell2mat(cellfun(@mean,Speed(:,C,2),'UniformOutput',false)));
            plot([ToPlot(C,:,1); ToPlot(C,:,2)],'LineWidth',1,'color',Grey); hold on
            scatter(ones(size(Speed,1),1),ToPlot(C,:,1),'MarkerFaceColor','none','MarkerEdgeColor',Blue,'LineWidth',1,'MarkerFaceColor',White)
            scatter(ones(size(Speed,1),1)+1,ToPlot(C,:,2),'MarkerFaceColor','none','MarkerEdgeColor',Red,'LineWidth',1,'MarkerFaceColor',White)
            axis([0.5 2.5 0 100]);
            Ax = gca; Ax.XTick = [1 2]; Ax.YTick = [0 50 100];
            Ax.XTickLabel = {'D';'WM'};
            plot([0.75 1.25],[nanmedian(ToPlot(C,:,1)) nanmedian(ToPlot(C,:,1))],'k','LineWidth',2)
            plot([1.75 2.25], [nanmedian(ToPlot(C,:,2)) nanmedian(ToPlot(C,:,2))],'k','LineWidth',2)
            if C == 1
                ylabel('No light')
            elseif C == 2
                xlabel('Delay onset');
                ylabel('Silencing light')
            elseif C == 4
                xlabel('Stimulus onset');
            end
            if Imaging && C > 2
                Ax.YLim = [- 5 5];
                Ax.YTick = [-5 0 5];
                Ax.YTickLabel = {'-150 mm';'Mean O';'+150 mm'};
            end
            %                 if C == 1
            %             ylabel('Delay onset')
            %         elseif C == 4
            %             ylabel('Delay end');
            %         elseif C == 7
            %             xlabel('No light');
            %             ylabel('Stimulus')
            %         elseif C == 8
            %             xlabel('Masking light');
            %         elseif C == 9
            %             xlabel('Silencing light');
            %         end
        end
    end
    
    
    
    
    
elseif Type == 3
    for K = 1:4
        ToPlot(K,:,1) = (cell2mat(cellfun(@mean,Speed(:,K,1),'UniformOutput',false)));
        ToPlot(K,:,2) = (cell2mat(cellfun(@mean,Speed(:,K,2),'UniformOutput',false)));
    end
    for On = 1:2 % (running and pupil.)
        % discrimination
        subplot(2,2,On);
        hold on;
        plot([ToPlot(((On-1)*2)+1,:,1); ToPlot(((On-1)*2)+2,:,1)],'LineWidth',1,'color',Grey); hold on
        scatter(ones(size(Speed,1),1),ToPlot(((On-1)*2)+1,:,1),'MarkerFaceColor','none','MarkerEdgeColor',Blue,'LineWidth',1,'MarkerFaceColor',White)
        scatter(ones(size(Speed,1),1)+1,ToPlot(((On-1)*2)+2,:,1),'MarkerFaceColor','none','MarkerEdgeColor',Blue,'LineWidth',1,'MarkerFaceColor',White)
        axis([0.5 2.5 0 100]);
        Ax = gca; Ax.XTick = [1 2]; Ax.YTick = [0 50 100];
        Ax.XTickLabel = {'Off';'On'};
        plot([0.75 1.25],[nanmedian(ToPlot(((On-1)*2)+1,:,1)) nanmedian(ToPlot(((On-1)*2)+1,:,1))],'k','LineWidth',2)
        plot([1.75 2.25], [nanmedian(ToPlot(((On-1)*2)+2,:,1)) nanmedian(ToPlot(((On-1)*2)+2,:,1))],'k','LineWidth',2)
        if Imaging && On == 2
            Ax.YLim = [-5 5];
            Ax.YTick = [-5 0 5];
            Ax.YTickLabel = {'-150 mm';'Mean O';'+150 mm'};
        end
        P(On,1) = signrank(ToPlot(((On-1)*2)+1,:,1),ToPlot(((On-1)*2)+2,:,1));
        text(1,swaparoo([80 4],and(Imaging,On==2)+1),strcat({'p = '},num2str(P(On,1))));
        
        % memory
        subplot(2,2,On+2);
        hold on;
        plot([ToPlot(((On-1)*2)+1,:,2); ToPlot(((On-1)*2)+2,:,2)],'LineWidth',1,'color',Grey); hold on
        scatter(ones(size(Speed,1),1),ToPlot(((On-1)*2)+1,:,2),'MarkerFaceColor','none','MarkerEdgeColor',Red,'LineWidth',1,'MarkerFaceColor',White)
        scatter(ones(size(Speed,1),1)+1,ToPlot(((On-1)*2)+2,:,2),'MarkerFaceColor','none','MarkerEdgeColor',Red,'LineWidth',1,'MarkerFaceColor',White)
        axis([0.5 2.5 0 100]);
        Ax = gca; Ax.XTick = [1 2]; Ax.YTick = [0 50 100];
        Ax.XTickLabel = {'Off';'On'};
        plot([0.75 1.25],[nanmedian(ToPlot(((On-1)*2)+1,:,2)) nanmedian(ToPlot(((On-1)*2)+1,:,2))],'k','LineWidth',2)
        plot([1.75 2.25], [nanmedian(ToPlot(((On-1)*2)+2,:,2)) nanmedian(ToPlot(((On-1)*2)+2,:,2))],'k','LineWidth',2)
        if On == 1
            xlabel('Delay onset');
        elseif On == 2 && ~Imaging
            xlabel('Stimulus onset');
        elseif On == 2 && Imaging
            xlabel('Pupil diameter');
        end
        if Imaging && On == 2
            Ax.YLim = [-5 5];
            Ax.YTick = [-5 0 5];
            Ax.YTickLabel = {'-150 mm';'Mean O';'+150 mm'};
        end
        P(On,2) = signrank(ToPlot(((On-1)*2)+1,:,2),ToPlot(((On-1)*2)+2,:,2));
        text(1,swaparoo([80 4],and(Imaging,On==2)+1),strcat({'p = '},num2str(P(On,2))));
        
    end
end


%% stats
if ~Imaging
    TempStat = cat(1,ToPlot(:,:,1),ToPlot(:,:,2));
    Stat = reshape(TempStat,[size(TempStat,1)*size(TempStat,2) 1]);
    
    TaskGroup = repmat([repmat('D',[4 1]); repmat('M',[4 1])],[size(ToPlot,2) 1]);
    ConditionGroup = repmat(repmat([1 2]',[4 1]),[size(ToPlot,2) 1]);
    OnsetGroup = repmat(repmat(cat(2,[1 1],[2 2])',[2 1]),[size(ToPlot,2) 1]);
    
    [p] =anovan(Stat,{TaskGroup,ConditionGroup,OnsetGroup},'model','full','varnames',{'Task';'Condition';'Onset'});
    format long g
    p
else
    TempStat = cat(1,ToPlot(1:2,:,1),ToPlot(1:2,:,2));
    Stat = reshape(TempStat,[4*size(TempStat,2) 1]);
    
    TaskGroup = repmat([repmat('D',[2 1]); repmat('M',[2 1])],[size(ToPlot,2) 1]);
    ConditionGroup = repmat(repmat([1 2]',[2 1]),[size(ToPlot,2) 1]);
    
    anovan(Stat,{TaskGroup,ConditionGroup},'model','full','varnames',{'Task';'Condition'});
    
    TempStat = cat(1,ToPlot(3:4,:,1),ToPlot(3:4,:,2));
    Stat = reshape(TempStat,[4*size(TempStat,2) 1]);
    
    TaskGroup = repmat([repmat('D',[2 1]); repmat('M',[2 1])],[size(ToPlot,2) 1]);
    ConditionGroup = repmat(repmat([1 2]',[2 1]),[size(ToPlot,2) 1]);
    
    anovan(Stat,{TaskGroup,ConditionGroup},'model','full','varnames',{'Task';'Condition'});
end
% TempStat = cat(1,ToPlot(:,:,1),ToPlot(:,:,2));
% Stat = reshape(TempStat,[108 1]);
%
% TaskGroup = repmat([repmat('D',[9 1]); repmat('M',[9 1])],[size(ToPlot,2) 1]);
% ConditionGroup = repmat(repmat([1 2 3]',[6 1]),[size(ToPlot,2) 1]);
% OnsetGroup = repmat(repmat(cat(2,[1 1 1],[2 2 2],[3 3 3])',[2 1]),[size(ToPlot,2) 1]);
%
% anovan(Stat,{TaskGroup,ConditionGroup,OnsetGroup},'model','full','varnames',{'Task';'Condition';'Onset'});

