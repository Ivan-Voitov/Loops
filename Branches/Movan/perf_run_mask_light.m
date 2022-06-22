function perf_run_mask_light(Trials,Datas,varargin)
%% READY
Window =  frame(1200,60);
EnMouse = false;
EarData = false;

%% SET
for I = 1:2:numel(varargin)
    if ~exist(varargin{I},'var')
        sprintf('Warning: one of the ParseArgs did not exist \r');
    end
    eval([varargin{I} '= varargin{I+1};']);
end

% organize
if isempty(Datas) && ~EarData
    Datas = Trials{2};
    Trials = Trials{1};
end

%% GO
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
Speed = cell(length(Trials),3,2);
Response = cell(length(Trials),3,2);
for Session = 1:length(Trials)
    for Task = 1:2-EarData
        clearvars Triggers
        if ~EarData
            Trial = Trials{Session}(3 - destruct(Trials{Session},'Task') == Task);
            Data = Datas{Session}(3 - destruct(Trials{Session},'Task') == Task);
        else
            Trial = Trials{Session};
        end
        Condition = false(length(Trial),3-EarData);
        Triggers = destruct(Trial,'Trigger.Delay.Line');
        Condition(:,1) = and(destruct(Trial,'MaskOn') ~= 1, destruct(Trial,swap({'LightOn';'Light'},EarData+1)) ==0);
        if ~EarData
            Condition(:,2) = and(destruct(Trial,'MaskOn') == 1, destruct(Trial,'LightOn') ==0);
            Condition(:,3) = destruct(Trial,'LightOn') == 1;
        else
            Condition(:,2) = destruct(Trial,'Light')==2;
        end
        for C = 1:3-EarData
            Speeds = nan(length(Trial),1);
            Responses = nan(length(Trial),1);
            for T = find(Condition(:,C))'
                if ~EarData
                    try
                        Speeds(T) = nanmean(Data{T}(Triggers(T):Triggers(T)+Window,4));
                    catch
                        Speeds(T) = nanmean(Data{T}(Triggers(T):Trial(T).Trigger.Stimulus.Line,4));
                    end
                else
                    Speeds(T) = Trial(T).DelaySpeed;
                end
                if Trial(T).Type == 1
                    %                     Responses(T) = or(Trials{Session}(T).ResponseType == 1, Trials{Session}(T).ResponseType == 4);
                    Responses(T) = ~isnan(Trial(T).StimulusResponse);
                end
            end
            Speed{Session,C,Task} = nanmean(Speeds);
            Response{Session,C,Task} = nanmean(Responses);
        end
    end
end

%% adjust
if ~EarData
    TempEffect(:,1) = (cell2mat(cellfun(@mean,Response(:,3,1),'UniformOutput',false)));
    TempEffect(:,2) = (cell2mat(cellfun(@mean,Response(:,3,2),'UniformOutput',false)));
    Remove = TempEffect(:,1) > 0.15;
    Remove(TempEffect(:,2) < 0.05) = true;
    
    BaseLine{1,1} = (cell2mat(cellfun(@mean,Speed(:,1,1),'UniformOutput',false)));
    Remove(find(isnan(BaseLine{1,1}))) = true;
else
    Remove = false(length(Trials),1);
end
%% plot
Colours;if EarData; Blue = Red; end;
clearvars Effect
BaseLine{1,1} = (cell2mat(cellfun(@mean,Speed(~Remove,1,1),'UniformOutput',false)));
BaseLine{2,1} = (cell2mat(cellfun(@mean,Response(~Remove,1,1),'UniformOutput',false)));
BaseLine{1,2} = (cell2mat(cellfun(@mean,Speed(~Remove,1,2),'UniformOutput',false)));
BaseLine{2,2} = (cell2mat(cellfun(@mean,Response(~Remove,1,2),'UniformOutput',false)));

for Condition = 1:2-EarData
    figure;
    for Column = 1:2
        subplot(1,2,Column);
        if Column == 1
            Effect(:,1) = (cell2mat(cellfun(@mean,Speed(~Remove,Condition+1,1),'UniformOutput',false)));
            Effect(:,2) = (cell2mat(cellfun(@mean,Speed(~Remove,Condition+1,2),'UniformOutput',false)));
        else
            Effect(:,1) = (cell2mat(cellfun(@mean,Response(~Remove,Condition+1,1),'UniformOutput',false)));
            Effect(:,2) = (cell2mat(cellfun(@mean,Response(~Remove,Condition+1,2),'UniformOutput',false)));
        end
        for Task = 1:2-EarData
            %             [Mu{1} CI{1}] = normfit(BaseLine{Column,Task});
            %             [Mu{2} CI{2}] = normfit(Effect(:,Task));
            %             errorbar([1 2],[Mu{1} Mu{2}],[CI{1} CI{2}],'color',swap({Blue,Red},Task),...
            %                 'LineWidth',2,'Marker','o','MarkerFaceColor',White,'MarkerSize',10);
            %             hold on;
            plot([1 2],([BaseLine{Column,Task} Effect(:,Task)]),'color',swap({Blue,Red},Task),'LineWidth',0.5);
            hold on;
            plot([1 2],nanmean([BaseLine{Column,Task} Effect(:,Task)]),'color',swap({Blue,Red},Task),...
                'LineWidth',2,'Marker','o','MarkerFaceColor',White,'MarkerSize',8);
        end
        axis([0.75 2.25 0 swap([100 1],Column)]);
    end
end
