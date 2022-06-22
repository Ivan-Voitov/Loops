function [AvgPlot] = movement_control(Trials,Datas,Pupils,varargin)
FPS = 4.68;
EnMouse = true;
Imaging = [];
CleanPupil = true;

for I = 1:2:numel(varargin)
    if ~exist(varargin{I},'var')
        sprintf('Warning: one of the ParseArgs did not exist \r');
    end
    eval([varargin{I} '= varargin{I+1};']);
end

if isempty(Datas)
    Datas = Trials{2};
    Trials = Trials{1};
end
%% include imaging
if ~isempty(Imaging)
    Meso = Imaging{1}; Reso = Imaging{2};
    Remove1 = false(length(Meso),1); clearvars TempNames
    for Session = 1:length(Meso)
        TempName = strsplit(Meso(Session).Name,'_');
        TempNames{Session} = cat(2,TempName{1},'_',TempName{2});
        if any(strcmp(TempNames{Session},TempNames(1:end-1)))
            Remove1(Session) = true;
        end
    end
    
    Remove2 = false(length(Reso),1); clearvars TempNames
    for Session = 1:length(Reso)
        TempName = strsplit(Reso(Session).Name,'_');
        TempNames{Session} = cat(2,TempName{1},'_',TempName{2});
        if any(strcmp(TempNames{Session},TempNames(1:end-1)))
            Remove2(Session) = true;
        end
    end
    
    DataSet{1} = Meso(~Remove1); DataSet{2} = Reso(~Remove2); DataSet{3} = Reso(~Remove2);
    LightConds = {'NoLight';'NoLight';'Light'}; FPSs = {4.68;22.39;22.39};
        
end



%% organize if not organized
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

% Trials{end+1} = cat(1,Trials{:});
% Datas{end+1} = cat(1,Datas{:});

% Pupils{end+1} = cat(1,Pupils{cell2mat(cellfun(@length,Pupils,'UniformOutput',false))~=1});

%% extract
% temptraces = movement type, session, task, trigger
for Session = 1:length(Trials)
    % load data
    Trial = Trials{Session};
    Data = Datas{Session};
    
    TaskLabel = 3 - destruct(Trial,'Task');
    
    BehStimulusOnset = destruct(Trial,'Trigger.Stimulus.Line');
    BehDelayOnset = Trial(1).Trigger.Delay.Line + 1;
    
    for Task = 1:2
        % running
        TT = 1;
        for T = find(TaskLabel == Task)' %1:length(Data)
            if frame(3200,60) < BehStimulusOnset(T)
                TempTraces{1,Session,Task,1}(TT,:) = Data{T}(BehDelayOnset:frame(3200,60)+BehDelayOnset-1,4);
            else
                TempTraces{1,Session,Task,1}(TT,:) = cat(1,Data{T}(BehDelayOnset:BehStimulusOnset(T),4),nan(frame(3200,60)-size(Data{T}(BehDelayOnset:BehStimulusOnset(T),4),1),1));
            end
            
            try % stimulus
                TempTraces{1,Session,Task,2}(TT,:) = Data{T}(BehStimulusOnset(T)+1:BehStimulusOnset(T)+frame(2000,60),4);
                TempTraces{1,Session,Task,2}(TT,TempTraces{1,Session,Task,2}(TT,:) == 0) = nan;
            catch
                TempTraces{1,Session,Task,2}(TT,:) = cat(1,Data{T}(BehStimulusOnset(T):end,4),nan(frame(2000,60)-size(Data{T}(BehStimulusOnset(T):end,4),1),1));
                TempTraces{1,Session,Task,2}(TT,  TempTraces{1,Session,Task,2}(TT,:)==0) = nan;
            end
            TT = TT + 1;
        end
        
        % pupil
        if ~isempty(Pupils)
            if ~all(isnan(Pupils{Session}(:)))
                Pupil = Pupils{Session}(:,1:3);
                % trigger
                TrigOn = destruct(Trial,'Trigger.Delay.Frame');
                TrigOff = destruct(Trial,'Trigger.Stimulus.Frame') + frame(2000,FPS);
                
                Pupil(Pupil==0) = nan;
                if CleanPupil
                    Focus = false(length(Pupil),1);
                    for Tr = 1:length(TrigOn)
                        try
                            Focus(TrigOn(Tr):TrigOff(Tr)) = true;
                        end
                    end
                    Pupil(~Focus,:) = nan;
%                     Pupil = zscore(Pupil,[],2,'omitnan');
%                     Pupil = (Pupil - nanmean(Pupil,1)) ./ nanstd(Pupil,[],2);
                    
                end
                Pupil = Pupil - nanmean(Pupil,1); % mean subtract x and y and diam
%                 Pupil = zscore(Pupil,[],2); % mean subtract x and y and diam
                %                                 Pupil(:,1) = ((Pupil(:,1).^2) + (Pupil(:,2).^2)).^ 0.5; % convert to distance
%                 subplot(2,1,Task)
%                 plot(Pupil(:,3))
                
                TempTempTraces = wind_roi(Pupil',{TrigOn;TrigOff},'Window',frame([0 6000],FPS));
                Onsets = ((TrigOff-frame(2000,FPS)) - TrigOn)+1; % within each trial the onset
                for III = 1:size(TempTempTraces,3)
                    try
                        TempTempTraces(:,frame(3200,FPS)+1:frame(3200,FPS)+1+frame(2000,FPS),III) = TempTempTraces(:,Onsets(III):Onsets(III)+frame(2000,FPS),III);
                    catch
                        TempTempTraces(:,frame(3200,FPS)+1:frame(3200,FPS)+frame(2000,FPS),III) = TempTempTraces(:,Onsets(III):Onsets(III)+frame(2000,FPS)-1,III);
                    end
                    TempTempTraces(:,Onsets(III):frame(3200),III) = nan;
                end
                TempTempTraces(:,end-frame(800,FPS):end,:) = [];
                
                TT = 1;
                for T = find(TaskLabel == Task)' %1:length(Data)
                    for K = 1:3
                        TempTraces{K+1,Session,Task,1}(TT,:) = TempTempTraces(K,1:frame(3200,FPS),T); % changed from tt to t
                        TempTraces{K+1,Session,Task,2}(TT,:) = TempTempTraces(K,frame(3200,FPS)+1:end,T);
                    end
                    TT = TT + 1;
                end
            end
        end
    end
    %     Running{Mouse,Task} = cat(1,Running{Mouse,Task},cat(2,TempRunning{2}));
end

%% cat across temptraces to get overall avg
for K=1:(~isempty(Pupils)*3)+1
    for Task = 1:2
        for Trigger = 1:2
            TempTraces{K,Session+1,Task,Trigger} = cat(1,TempTraces{K,:,Task,Trigger});
        end
    end
end

%% average into mice and get per mouse p values
for Trigger = 1:2
    for K = 1:(~isempty(Pupils)*3)+1 % running and pupil
        for Task = 1:2
            % top
            for Mouse = 1:length(Trials)
                if ~isempty(TempTraces{K,Mouse,Task,Trigger})
                    AvgPlot{K,Task,Trigger}(Mouse,:) = nanmean(TempTraces{K,Mouse,Task,Trigger},1);
                    AvgAcrossTime{K,Task,Trigger}(Mouse) = nanmean(TempTraces{K,Mouse,Task,Trigger}(:));
                else
                    AvgPlot{K,Task,Trigger}(Mouse,:) = nan((frame(3200,FPS).*(Trigger==1)) +((frame(1950,FPS)).*(Trigger==2)),1);  %frame(5200,7.46)+1;%nan(length(AvgPlot{K,Task,Trigger}(Mouse-1,:)),1)';
                    AvgAcrossTime{K,Task,Trigger}(Mouse) = nan;
                end
            end
            AvgAvgPlot{K,Task,Trigger} = nanmean(TempTraces{K,length(Trials)+1,Task,Trigger},2);
        end
        
        % bottom
        for Mouse = 1:length(Trials)
            for II = 1:size(AvgPlot{K,Task,Trigger}(Mouse,:),2)
                if ~isempty(TempTraces{K,Mouse,1,Trigger})
                    try
                        [MousePlot{K,Trigger}(Mouse,II)] = ranksum(TempTraces{K,Mouse,1,Trigger}(:,II),TempTraces{K,Mouse,2,Trigger}(:,II));
                    catch
                        MousePlot{K,Trigger}(Mouse,II) = nan;
                    end
                else
                    MousePlot{K,Trigger}(Mouse,II) = nan;
                end
            end
            
            try
                AvgMousePlot{K,Trigger}(Mouse) = ranksum(nanmean(TempTraces{K,Mouse,1,Trigger},2),nanmean(TempTraces{K,Mouse,2,Trigger},2));
            catch
                AvgMousePlot{K,Trigger}(Mouse) = nan;
            end
        end
        AvgAvgMousePlot{K,Trigger} = ranksum(nanmean(TempTraces{K,length(Trials)+1,1,Trigger},2),nanmean(TempTraces{K,length(Trials)+1,2,Trigger},2));
    end
end


%% plot session delay-averaged statistics
Colours; Colour = {Blue;Red}; YTitles = {'Running speed (cm/s)';'X Distance from median (A.U)';'Y Distance from median (A.U)';'Diameter (A.U)'};
YTitles(:,2) = {'Statistical difference of running speed (p)';'Statistical difference of X distance from mean (p)';...
    'Statistical difference of Y distance from mean (p)';'Statistical difference of diameter (p)'};
XTicks = {{'0 ms';'3200 ms'};{'2000 ms'}};
for K = 1:size(AvgPlot,1) % running/ pupil * 2
    %% plot the first two of first plot 
    figure;
    for Trigger = 1:2
        subplot(2,25,1+(9*(Trigger==2)):9+(6*(Trigger==2))); hold on;
        if Trigger == 1;            ylabel(YTitles{K,1});end
        for Task = 1:2
            plot(nanmean(AvgPlot{K,Task,Trigger},1),'color',Colour{Task},'LineWidth',2);
            clearvars Means CI
            for II = 1:size(AvgPlot{K,Task,Trigger},2)
                [Means(II),~,CI(II,:)] = normfit(AvgPlot{K,Task,Trigger}(~isnan(AvgPlot{K,Task,Trigger}(:,II)),II));
            end
            patches([],CI,1:length(AvgPlot{K,Task,Trigger}(1,:)),'Colour',Colour{Task})
            
            Ax = gca;
            Ax.XLim = [1 length(AvgPlot{K,Task,Trigger}(1,:))];
            if K == 1 
                Ax.YLim = [0 100];
                Ax.YTick = [0 50 100];
            elseif K == 2 || K == 3  
                Ax.YLim =[-2.5 2.5];
                Ax.YTick = [-2.5 0 2.5];
            elseif K == 4 
                Ax.YLim =[-5 5];
                Ax.YTick = [-5 0 5];
                Ax.YTickLabel = {'-150 mm';'Mean O';'+150 mm'};
            end
            if Trigger == 2
                Ax.YTick = [];
            end
            if Trigger == 1
            Ax.XTick = [1 length(AvgPlot{K,Task,Trigger}(1,:))];
            else
              Ax.XTick = [length(AvgPlot{K,Task,Trigger}(1,:))];
            end
            Ax.XTickLabel = XTicks{Trigger};
        end
    end
    
    %% plot second two of first plot
    for Trigger = 1:2
%         % plot the second 2
%         subplot(2,25,18+(4*(Trigger==2)):21+(4*(Trigger==2))); hold on;
%         plot([nanmean(AvgPlot{K,1,Trigger},2) nanmean(AvgPlot{K,2,Trigger},2)]','color',Grey);
%         scatter(ones(length(Trials),1),nanmean(AvgPlot{K,1,Trigger},2),'MarkerFaceColor',White,'MarkerEdgeColor',Grey)
%         scatter(ones(length(Trials),1)+1,nanmean(AvgPlot{K,2,Trigger},2),'MarkerFaceColor',White,'MarkerEdgeColor',Grey)
%         axis([0.5 2.5 0 100]);
%         Ax = gca; Ax.XTick = [1 2];
%         if K == 1
%             Ax.YLim = [0 100];
%             Ax.YTick = [0 50 100];
%         elseif K == 2 || K == 3
%             Ax.YLim =[-5 5];
%             Ax.YTick = [-5 0 5];
%         elseif K == 4
%             Ax.YLim =[-10 10];
%             Ax.YTick = [-10 0 10];
%         end
%         Ax.XTickLabel = {'D';'M'};
%         %         plot([nanmean(nanmean(AvgPlot{K,1,Trigger},2),1) nanmean(nanmean(AvgPlot{K,2,Trigger},2),1)],'k','LineWidth',2)
%         plot([0.8 1.2],[nanmean(nanmean(AvgPlot{K,1,Trigger},2)) nanmean(nanmean(AvgPlot{K,1,Trigger},2))],'k','LineWidth',2)
%         plot([1.8 2.2], [nanmean(nanmean(AvgPlot{K,2,Trigger},2)) nanmean(nanmean(AvgPlot{K,2,Trigger},2))],'k','LineWidth',2)
%         [P(K,Trigger)] = signrank(nanmean(AvgPlot{K,1,Trigger},2), nanmean(AvgPlot{K,2,Trigger},2));
% %         [P(K,Trigger)] = ttest(nanmean(AvgPlot{K,1,Trigger},2), nanmean(AvgPlot{K,2,Trigger},2));
% %         [P(K,Trigger)] = ranksum(nanmean(AvgPlot{K,1,Trigger},2), nanmean(AvgPlot{K,2,Trigger},2));
%         
%         text(1,1,num2str(P(K,Trigger)));
%         
                % plot the second 2
        subplot(2,25,18+(4*(Trigger==2)):21+(4*(Trigger==2))); hold on;
        plot([AvgAcrossTime{K,1,Trigger}' AvgAcrossTime{K,2,Trigger}']','color',Grey,'LineWidth',1);
%         scatter(ones(length(Trials),1),AvgAcrossTime{K,1,Trigger}','MarkerFaceColor',White,'MarkerEdgeColor',Grey)
%         scatter(ones(length(Trials),1)+1,AvgAcrossTime{K,2,Trigger}','MarkerFaceColor',White,'MarkerEdgeColor',Grey)
        axis([0.5 2.5 0 100]);
        Ax = gca; Ax.XTick = [1 2];
        if K == 1
            Ax.YLim = [0 100];
            Ax.YTick = [0 50 100];
        elseif K == 2 || K == 3
            Ax.YLim =[-5 5];
            Ax.YTick = [-5 0 5];
            Ax.YTickLabel = {'-150 mm';'Mean O';'+150 mm'};
        elseif K == 4
            Ax.YLim =[-5 5];
            Ax.YTick = [-5 0 5];
            Ax.YTickLabel = {'-150 mm';'Mean O';'+150 mm'};
        end
        Ax.XTickLabel = {'D';'WM'};
        %         %         plot([nanmean(nanmean(AvgPlot{K,1,Trigger},2),1) nanmean(nanmean(AvgPlot{K,2,Trigger},2),1)],'k','LineWidth',2)
        %         plot([0.75 1.25],[nanmean(nanmean(AvgPlot{K,1,Trigger},2)) nanmean(nanmean(AvgPlot{K,1,Trigger},2))],'k','LineWidth',2)
        %         plot([1.75 2.25], [nanmean(nanmean(AvgPlot{K,2,Trigger},2)) nanmean(nanmean(AvgPlot{K,2,Trigger},2))],'k','LineWidth',2)
        plot(repmat(1,[size(AvgAcrossTime{K,1,Trigger},2) 1]),AvgAcrossTime{K,1,Trigger},'LineWidth',1,'LineStyle','none','MarkerSize',6,'Marker','o','MarkerFaceColor',White,'MarkerEdgeColor',Blue);
        plot(repmat(2,[size(AvgAcrossTime{K,1,Trigger},2) 1]),AvgAcrossTime{K,2,Trigger},'LineWidth',1,'LineStyle','none','MarkerSize',6,'Marker','o','MarkerFaceColor',White,'MarkerEdgeColor',Red);

        plot([0.75 1.25],[nanmedian(AvgAcrossTime{K,1,Trigger}) nanmedian(AvgAcrossTime{K,1,Trigger})],'color',Black,'LineWidth',2)
        plot([1.75 2.25],[nanmedian(AvgAcrossTime{K,2,Trigger}) nanmedian(AvgAcrossTime{K,2,Trigger})],'color',Black,'LineWidth',2)
        
        [P(K,Trigger)] = signrank(AvgAcrossTime{K,1,Trigger}',AvgAcrossTime{K,2,Trigger}');
%         [P(K,Trigger)] = ttest(nanmean(AvgPlot{K,1,Trigger},2), nanmean(AvgPlot{K,2,Trigger},2));
%         [P(K,Trigger)] = ranksum(nanmean(AvgPlot{K,1,Trigger},2), nanmean(AvgPlot{K,2,Trigger},2));
        
        text(1,1,num2str(P(K,Trigger)));
    end
    
    %% plot first two of first plot
    for Trigger = 1:2
        subplot(2,25,25+1+(9*(Trigger==2)):25+9+(6*(Trigger==2))); hold on;
        if Trigger == 1;            ylabel(YTitles{K,2});end
%         plot(MousePlot{K,Trigger}','color',Grey,'LineWidth',1);

        for II = 1:size(MousePlot{K,Trigger},2)
            [Means(II),~,CI(II,:)] = normfit(MousePlot{K,Trigger}(~isnan(MousePlot{K,Trigger}(:,II)),II));
        end
        patches([],CI,1:length(MousePlot{K,Trigger}(1,:)),'Colour',Grey)
        hold on;
        plot(nanmean(MousePlot{K,Trigger},1),'color',Black,'LineWidth',2);
        Ax = gca;
        Ax.XLim = [1 length(AvgPlot{K,Task,Trigger}(1,:))];
        Ax.YLim = [0 1];
        Ax.YTick = [0 0.05 0.5 1];
        Ax.XTick = [1 length(AvgPlot{K,Task,Trigger}(1,:))];
        Ax.XTickLabel = XTicks{Trigger};
    end
    
    %% plot second two of second plot
    for Trigger = 1:2
        subplot(2,25,25+18+(4*(Trigger==2)):25+21+(4*(Trigger==2))); hold on;
        scatter(ones(length(Trials),1),AvgMousePlot{K,Trigger},'MarkerFaceColor',White,'MarkerEdgeColor',Grey)
        axis([0.5 1.5 0 1]);
        Ax = gca; Ax.XTick = [1 2];
            Ax.YLim = [0 1];
            Ax.YTick = [0 0.05 0.5 1];

        Ax.XTick = [];
%         plot([0.8 1.2],[nanmean(AvgMousePlot{K,Trigger}) nanmean(AvgMousePlot{K,Trigger})],'k','LineWidth',2)
        plot([0.8 1.2],[AvgAvgMousePlot{K,Trigger} AvgAvgMousePlot{K,Trigger}],'k','LineWidth',2)
    end
end

%%
% end
% plot(TempStat(:,:,Row)','color','k');
% axis([0.5 2.5 -2.5-(3*(Row==3)) 2.5+(3*(Row==3))]);
% [~,P] = ttest2(TempStat(:,1,Row),TempStat(:,2,Row));
% text(1.75,3.25,strcat('p = ',num2str(P)));
% ylabel('A.U.');
% Ax = gca;
% Ax.XTick = [1 2];
% Ax.XTickLabel = {'D';'M'};
% title(Titles{Row});
% end
% % end
%
%
% %% plot all session together
% Colours; Colour = {Blue;Red};
% figure; Session = length(Trials) + 1;
% % for Column = 1:1
% for Task = 1:2
%     if Column == 1
%         TempTrace{Task} = Traces.Pupil{Session,Task};
%     elseif Column == 2
%     elseif Column == 3
%     elseif Column == 4clea
%     end
% end
% for Row = 1:3
%     %         subplot(3,4,(Row-1)*4+Column); hold on;
%     subplot(3,1,Row); hold on;
%
%     for Task = 1:2
%         plot(squeeze(nanmean(TempTrace{Task}(Row,:,:),3)),'color',Colour{Task});
%         % CI
%         for II = 1:size(TempTrace{Task},2)
%             try
%                 PD = fitdist(squeeze(TempTrace{Task}(Row,II,:)),'Normal');
%                 TempCI = paramci(PD);
%                 CIs(II,:) = [TempCI(2,1) TempCI(1,1)];
%             catch
%                 CIs(II,:) = [0 0];
%             end
%         end
%         patches(squeeze(nanmean(TempTrace{Task}(Row,:,:),3)),CIs,[1:size(TempTrace{Task},2)],'Colour',Colour{Task})
%     end
%     line([16 16],[-2 2],'color',Black,'LineWidth',2)
%     axis([1 24 -0.5-(1.5*(Row==3)) 0.5+(1.5*(Row==3))]);
%     ylabel('A.U.');
%     Ax = gca;
%     Ax.XTick = [1 16 24];
%     Ax.XTickLabel = {'0 ms';'3200 ms';'2000 ms'};
%     title(Titles{Row});
%
% end
% % end

%% each sessoin individually
% Colours; Colour = {Blue;Red};
% for Session = 1:length(Trials)
%     if ~isempty(Traces.Pupil{Session,1})
%         figure;
%         for Column = 1:1
%             for Task = 1:2
%                 if Column == 1
%                     TempTrace{Task} = Traces.Pupil{Session,Task};
%                 elseif Column == 2
%                 elseif Column == 3
%                 elseif Column == 4
%                 end
%             end
%             for Row = 1:3
%                 subplot(3,4,(Row-1)*4+Column); hold on;
%                 for Task = 1:2
%                     plot(squeeze(nanmean(TempTrace{Task}(Row,:,:),3)),'color',Colour{Task});
%                     % CI
%                     for II = 1:size(TempTrace{Task},2)
%                         try
%                             PD = fitdist(squeeze(TempTrace{Task}(Row,II,:)),'Normal');
%                             TempCI = paramci(PD);
%                             CIs(II,:) = [TempCI(2,1) TempCI(1,1)];
%                         catch
%                             CIs(II,:) = [0 0];
%                         end
%                     end
%                     patches(squeeze(nanmean(TempTrace{Task}(Row,:,:),3)),CIs,[1:size(TempTrace{Task},2)],'Colour',Colour{Task})
%                 end
%             end
%         end
%         suptitle(num2str(Session));
%     end
% end