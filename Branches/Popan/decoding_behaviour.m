function [Sig] = decoding_behaviour(Index,varargin)
FPS = 4.68;
CCD = false;
DistractorEncoding = false;
% controls
Avg = false;
PC1 = false;
Alt = false;
% takes a long time to calc and not relevant
ROC = false;

% only used for controls. first term is the pre
Window = [0 3200]; 

% Control = false;

%% PASS CONTROL
for I=1:2:numel(varargin)
    eval([varargin{I} '= varargin{I+1};']);
end

% if DistractorEncoding
%     Index = (Inderescorex);
% end

%% collect data
if Avg || PC1
    [DFFs,~] = rip(Index,'S','DeNaN','Active');
end
for Session = 1:length(Index)
    % I have to use sel because some NaN (e.g., end of 4th session) of
    % score is because of nan of DFF, which is not HasFrame'd because that
    % only looks at limits of dff, not if full trial is nan'd.
    
    Loaded = load(Index(Session).Name,'Trial');
    if CCD
        % unfuck this, i can 'beh' rip
        TempDB = Loaded.Trial(and(Index(Session).Combobulation,destruct(Loaded.Trial,'Task')==1)).DB;
        if isfield(Index(Session),'DeSet')
            if ~isempty(Index(Session).DeSet)
                Trial = Trial(Index(Session).DeSet);
            end
        end
        % need this step because i can't just 'sel' things
        Index(Session).CueScore=Index(Session).CueScore(and(destruct(Loaded.Trial,'DB')==TempDB,destruct(Loaded.Trial,'Task')==1));
        
        Trial = Loaded.Trial(and(destruct(Loaded.Trial,'DB')==TempDB,destruct(Loaded.Trial,'Task')==1));
        [Trials{Session},Sel] = selector(Trial,'NoReset','HasFrames','Nignore','Post');
    else
        Trial = Loaded.Trial;
        if DistractorEncoding && Alt           
            Index(Session).Combobulation = or(Index(Session).Combobulation,destruct(Trial,'Task')==2);
        end
        [Trials{Session},Sel] = selector(Trial,Index(Session).Combobulation,'NoReset','HasFrames','Post','Nignore'); % no reason not to analyze trials
    end
    
    if ~Avg && ~PC1
        if ~CCD && ~DistractorEncoding
            Scores{Session} = Index(Session).Score(Sel);
        else
            Scores{Session} = Index(Session).CueScore(Sel);
        end
    else
        TrigOn = destruct(Trial,'Trigger.Delay.Frame');
        TrigOff = destruct(Trial,'Trigger.Stimulus.Frame');
        if Avg
            AvgActivity = squeeze(nanmean(wind_roi(nanmean(DFFs{Session},1),{TrigOn;TrigOff},'Window',frame(Window,FPS)),2));
            Scores{Session} = AvgActivity(Sel);
        elseif PC1
            PCd = pca(DFFs{Session}(:,~isnan(DFFs{Session}(1,:))));
            AvgActivity = squeeze(nanmean(wind_roi(PCd(:,1)',{TrigOn;TrigOff},'Window',frame(Window,FPS)),2));
            Scores{Session} = AvgActivity(Sel);
        end
    end
end

%% for ROC get contrasts
if ROC
    if ~CCD
        [DFFs,~] = rip(Index,'S','Super','DeNaN','Active');
    else
        [DFFs,~] = rip(Index,'S','Context','DeNaN','Active');
    end
    % low dim contrast
    for Session = 1:length(Index)
        Traces{Session} = Index(Session).(swap({'Trace';'CueTrace'},CCD+1));
        %         LowDimTraces{Session} = Index(Session).AvgTrace;
        
        % Crossed PCA
        [~,LowDimTraces{Session}] = pca(DFFs{Session}','numcomponents',1); %not cross val'd
        TrigOn = destruct(Trials{Session},'Trigger.Delay.Frame');
        TrigOff = destruct(Trials{Session},'Trigger.Stimulus.Frame');
        for C = 1:2
            
            TempDFF = nan(size(DFFs{Session}));
            for Tr= C:2:length(TrigOn)
                TempDFF(:,TrigOn(Tr):TrigOff(Tr)) = DFFs{Session}(:,TrigOn(Tr):TrigOff(Tr));
            end
            [TempBasis,~] = pca(TempDFF','numcomponents',1);
            for Tr= (3-C):2:length(TrigOn)
                LowDimTraces{Session}(TrigOn(Tr):TrigOff(Tr)) = DFFs{Session}(:,TrigOn(Tr):TrigOff(Tr))' * TempBasis;
            end
        end
        %         if Control
        %             for Tr = 1:length(TrigOn)
        %                 Scores{Session}(Tr) = nanmean(LowDimTraces{Session}(TrigOn(Tr):TrigOff(Tr)));
        %             end
        %         end
    end
end

% if Control
%
% end

%% define contrasts and calculate numbers
% name here to edit faster
XPairs ={{'CR';'FA'};{'Correct';'Incorrect'};{'Short delay';'Long delay'};{'<5 Cues';'>=5 Cues'}};
XPairs = XPairs([1 4]);
PooledAccuracy = cell(length(XPairs),2-CCD,2); % cat across sessions
for Session = 1:length(Trials)
    Trial = Trials{Session};
    Score = Scores{Session};
    Zcore = -zscore(Score,[],'omitnan');
      
    if ~CCD && ~DistractorEncoding
        TaskLabels = 3 - destruct(Trial,'Task');
        Score(TaskLabels == 2) = -Score(TaskLabels==2); % fliparooni
    elseif DistractorEncoding
        % flip +15 deg WM cues
        if Trial(find(destruct(Trial,'Task')==1,1)).Block == 1
            Score = -Score;
        end
%         % flip +15 deg Discrimination cues
%         TempSelect = and(destruct(Trial,'Task')==2,destruct(Trial,'DB')==15);
%         Score(TempSelect) = -Score(TempSelect);
        
        % flip the corresponding Discrimination task cues
        TempDB = Trial(find(destruct(Trial,'Task')==1,1)).DB;
        Score(and(destruct(Trial,'Task')==2,destruct(Trial,'DB')==TempDB)) = ...
            -Score(and(destruct(Trial,'Task')==2,destruct(Trial,'DB')==TempDB));
        
        
%         Score(destruct(Trial,'Task')==2) = -Score(destruct(Trial,'Task')==2);
%         TempSelect = and(destruct(Trial,'Task')==1,destruct(Trial,'Block')==1);
%         Score(TempSelect) = -Score(TempSelect);
%         % maybe should be -15

%         
        TaskLabels = 3 - destruct(Trial,'Task');
        
        
    else
        Score(destruct(Trial,'Block')==1) = -Score(destruct(Trial,'Block')==1);
        ContextLabels = destruct(Trial,'Block')+1;
    end
    
    % define contrasts. nan is what i leave out
    Contrast.FA = double(destruct(Trial,'ResponseType') == 2);
    Contrast.FA(destruct(Trial,'Type')~= 1) = nan;
    % Contrast.Miss = double(destruct(Trial,'ResponseType') == 3);
    % Contrast.Miss(destruct(Trial,'Type')~= 3) = nan;
    %     Contrast.Correct = double(or(destruct(Trial,'ResponseType') == 2,destruct(Trial,'ResponseType') == 3));
    %     Contrast.Correct(destruct(Trial,'Type')==2) = nan;
    %     Contrast.Length = double(destruct(Trial,'Trigger.Stimulus.Time')>1600);
    Contrast.BlockLocation = double(destruct(Trial,'Post.Cue')>4);
    if ~CCD
        Contrast.BlockLocation(isnan(destruct(Trial,'Post.Cue'))) = ...
            double(destruct(Trial(isnan(destruct(Trial,'Post.Cue'))),'Post.Distractor')>4);
    end
    
    % store each classification
    ContrastNames = fieldnames(Contrast);
    for K = 1:length(ContrastNames)
        for Bin = 0:1
            if ~CCD
                for Task= 1:2
                    if ~all(isnan(Score(and(Contrast.(ContrastNames{K})==Bin,TaskLabels==Task))))
                        SessionedAccuracy(Session,K,Task,Bin+1) = nanmean(Score(and(and(Contrast.(ContrastNames{K})==Bin,TaskLabels==Task),~isnan(Score)))>0);
                        PooledAccuracy{K,Task,Bin+1} = cat(1,PooledAccuracy{K,Task,Bin+1},Score(and(and(Contrast.(ContrastNames{K})==Bin,TaskLabels==Task),~isnan(Score)))>0);
                        
                        SessionedScore(Session,K,Task,Bin+1) = nanmean(Zcore(and(and(Contrast.(ContrastNames{K})==Bin,TaskLabels==Task),~isnan(Zcore))));
                        PooledScore{K,Task,Bin+1} = cat(1,PooledAccuracy{K,Task,Bin+1},Zcore(and(and(Contrast.(ContrastNames{K})==Bin,TaskLabels==Task),~isnan(Zcore))));
                    else
                        SessionedAccuracy(Session,K,Task,Bin+1) = nan;
                        
                        SessionedScore(Session,K,Task,Bin+1) = nan;
                    end
                end
            else
                if ~all(isnan(Score(Contrast.(ContrastNames{K})==Bin)))
                    SessionedAccuracy(Session,K,1,Bin+1) = nanmean(Score(and(Contrast.(ContrastNames{K})==Bin,~isnan(Score)))>0);
                    PooledAccuracy{K,1,Bin+1} = cat(1,PooledAccuracy{K,1,Bin+1},Score(and(Contrast.(ContrastNames{K})==Bin,~isnan(Score)))>0);
                    
                    for Context = 1:2
                        SessionedScore(Session,K,Context,Bin+1) = nanmean(Zcore(and(and(Contrast.(ContrastNames{K})==Bin,~isnan(Zcore)),ContextLabels==Context)));
                        PooledScore{K,Context,Bin+1} = cat(1,PooledAccuracy{K,1,Bin+1},Zcore(and(and(Contrast.(ContrastNames{K})==Bin,~isnan(Zcore)),ContextLabels==Context)));
                    end
                else
                    SessionedAccuracy(Session,K,1,Bin+1) = nan;
                    
                    SessionedScore(Session,K,1,Bin+1) = nan;
                end
            end
        end
        %         if K == 1
        %             mean(Point1(:,1,1,2))
        %             mean(Point2{1,1,2})
        %         end
    end
end

%% PLOT
for Style = 1:2
    Sessioned = swap({SessionedAccuracy; SessionedScore},Style);
    Pooled = swap({PooledAccuracy; PooledScore},Style);
    
    figure;
    set(gcf, 'Position', [500, 300, 700, 400])
    
    Colours;% if and(CCD,Style==1); Blue = Black; end
    if CCD; Blue = swap({Orange;Black},(Style == 1)+1); Red = Green;end
    if DistractorEncoding
        Red = Orange;
    end
    
    for K = 1:length(ContrastNames)
        Ax{1} = subplot(2,length(ContrastNames),K);
        hold on;
        
        % discrimination // CCD
        % first three
        for C = 1:1+(or(~CCD,Style==2))
            X = plot([Sessioned(:,K,C,1) Sessioned(:,K,C,2)]','color',swap({Blue;Red},C),'LineWidth',1,'Marker','o','MarkerFaceColor',White,'MarkerEdgeColor',swap({Blue;Red},C),'MarkerSize',5);
            for Y = 1:length(X)
                X(Y).Color = cat(2,swap({Blue;Red},C),0.2);
            end
            plot([0.75 1.25],[nanmedian(Sessioned(:,K,C,1)) nanmedian(Sessioned(:,K,C,1))],'LineWidth',2,'color',swap({Blue;Red},C));
            plot([1.75 2.25],[nanmedian(Sessioned(:,K,C,2)) nanmedian(Sessioned(:,K,C,2))],'LineWidth',2,'color',swap({Blue;Red},C));
            try
                [Sig(K,1)] = signrank(Sessioned(:,K,C,2), Sessioned(:,K,C,1));
                text(0,0.75+(C*0.05),num2str(Sig(K)),'color',swap({Blue;Red},C));
            end
        end
        
        % second three
        Ax{2} = subplot(2,length(ContrastNames),K+(length(ContrastNames)));
        hold on;
        for C = 1:1+(or(~CCD,Style==2))
            for Bin = 1:2
                [Mean{Bin}, CI{Bin}] = binofit(sum(Pooled{K,C,Bin}),length(Pooled{K,C,Bin}));
            end
            errorbar(0,Mean{1},Mean{1}-CI{1}(1),Mean{1}-CI{1}(2),'LineWidth',2,'color',swap({Blue;Red},C),'Marker','o','MarkerFaceColor',swap({Blue;Red},C),'MarkerSize',5);
            errorbar(1,Mean{2},Mean{2}-CI{2}(1),Mean{2}-CI{2}(2),'LineWidth',2,'color',swap({Blue;Red},C),'Marker','o','MarkerFaceColor',swap({Blue;Red},C),'MarkerSize',5);
            if Style == 1
            [~,Sig(K)] = fishertest([[sum(Pooled{K,C,1}) sum(Pooled{K,C,2})];[sum(Pooled{K,C,1}==0) sum(Pooled{K,C,2}==0)]]);
            else
                Sig(K) = nan;
            end
            NumTrials = sum(Pooled{K,C,2})+sum(Pooled{K,C,1})+sum(Pooled{K,C,1}==0)+sum(Pooled{K,C,2}==0);
            text(1,0.75+(C*0.05),num2str(NumTrials),'color',Black);
            text(0,0.75+(C*0.05),num2str(Sig(K)),'color',swap({Blue;Red},C));
        end
        
        if Style == 1
            % misc
            for Axes = 1:2
                Ax{Axes}.XTick = [0 1] + (Axes==1);
                Ax{Axes}.XTickLabel = XPairs{K};
                Ax{Axes}.XLim = [-0.5 1.5]   + (Axes==1);
                Ax{Axes}.YTick = [0 0.5 1];
                Ax{Axes}.YLim = [0+(0.5*(Axes~=1)) 1];
                %             Ax{Axes}.YLim = [0.5 1];
                Ax{Axes}.YTickLabel = {'0%';'50%';'100%'};
            end
        else
            Min = min(Sessioned(:));
            Max = max(Sessioned(:));
            for Axes = 1:2
                Ax{Axes}.XTick = [0 1] + (Axes==1);
                Ax{Axes}.XTickLabel = XPairs{K};
                Ax{Axes}.XLim = [-0.5 1.5]   + (Axes==1);
                Ax{Axes}.YTick = [Min 0 Max];
                %                             Ax{Axes}.YLim = [0+(0.5*(Axes~=1)) 1];
                Ax{Axes}.YLim = [Min Max];
                Ax{Axes}.YTickLabel = [Min 0 Max];
            end
        end
    end
end


%% ROC ANALYSIS
if ROC
    clearvars Labels Values
    
    % identify prior
    for Session = 1:length(Trials)
        Trial = Trials{Session};
        TempTrial = Trial(destruct(Trial,'Task') == 1);
        TempLabel = double(destruct(TempTrial,'ResponseType') == 2);
        TempLabel(destruct(TempTrial,'Type')~= 1) = nan;
        Ratio(Session) = sum((TempLabel==1)) / length(TempLabel);
    end
    
    Accuracy{1} = [];
    Accuracy{2} = [];
    for Session = 1:length(Trials)
        Projection{1} = Traces{Session}; Projection{2} = LowDimTraces{Session}';
        Trial = Trials{Session};
        %     for Task = 1:2
        %     Task = 2;
        %     Projection{2} = Projection{2}';
        TempTrial = Trial(destruct(Trial,'Task') == 1);
        TrigOn = destruct(TempTrial,'Trigger.Delay.Frame');
        TrigOff = destruct(TempTrial,'Trigger.Stimulus.Frame');
        for P = 1:2
            Activities = wind_roi(Projection{P},{TrigOn;TrigOff},'Window',frame(Window,FPS));
            Values{Session}(P,:) = squeeze(nanmean(Activities,2));
        end
        if CCD
            Values{Session}(1,destruct(TempTrial,'Block')==0) = -Values{Session}(1,destruct(TempTrial,'Block')==0);
        end
        %         % ALTERNATIVE WMCD SCORE
        %         Values{Session}(1,:) = -Scores{Session}(destruct(Trial,'Task') == 1);
        
        Labels{Session} = double(destruct(TempTrial,'ResponseType') == 2);
        Labels{Session}(destruct(TempTrial,'Type')~= 1) = nan;
        
        % mitras
        Y = Labels{Session}';
        X1 = Values{Session}(1,:)';
        X2 = Values{Session}(2,:)';
        
        
        
        nanind = find(isnan(Y));
        Y(nanind) = [];
        X1(nanind) = [];
        X2(nanind) = [];
        
        % sanity check
        %     Y(X1<prctile(X1,20)) = true;
        
        % ROC curves
        [A1{Session},B1{Session},~,D1] = perfcurve(Y,X1,0);
        Accuracy{1}(end+1) = D1;
        [A1{Session},B1{Session},~,D2] = perfcurve(Y,X2,0);
        Accuracy{2}(end+1) = D2;
        % model classification
        %     Mdl = fitcsvm(X1,Y,'Standardize',1,'Prior',[1-mean(Ratio) mean(Ratio)]);
        % %     Mdl = fitcsvm(X1,Y,'Standardize',0,'Prior','empirical');
        %     [Yp,x]=predict(Mdl,X1);
        %
        % %     Mdl = mnrfit(X1,Y+1);
        % %     Mdl(1) + (Mdl(2).*X1)
        % %     Mdl = lda(X1,Y+1,1,[])';
        % %     Score = [ones(length(X1),1) X1] * Mdl; Mdl(2) + Mdl(1);
        % %     Yp = Score<0;
        %
        %     Accuracy{1}(end+1) = numel(find(Y==Yp'))/numel(Y);
        %
        %     Mdl = fitcsvm(X1,Y,'Standardize',1,'Prior',[1-mean(Ratio) mean(Ratio)]);
        %     Yp=predict(Mdl,X2);
        % %     sum(Yp)
        %     Accuracy{2}(end+1) = numel(find(Y==Yp'))/numel(Y);
        % %
    end
    
    
    
    Accuracy{1} = Accuracy{1} .* 100;
    Accuracy{2} = Accuracy{2} .* 100;
end
% [mean(Accuracy{1}), mean( Accuracy{2})]
% signrank(Accuracy{1},Accuracy{2})


%% PLOT ROC
Colours;
if ROC
    % figure;
    % [mean(Accuracy{1}), mean( Accuracy{2})]
    figure;
    P =  signrank(Accuracy{1},Accuracy{2});
    
    plot([Accuracy{1}; Accuracy{2}],'color',Grey,'Marker','o','MarkerEdgeColor',Grey)
    hold on;
    
    plot(ones(length(Accuracy{1}),1),[Accuracy{1}],'LineStyle','none','Marker','o','MarkerEdgeColor','k','MarkerFaceColor',White,'LineWidth',1)
    plot(ones(length(Accuracy{2}),1)+1,[Accuracy{2}],'LineStyle','none','Marker','o','MarkerEdgeColor',Grey,'MarkerFaceColor',White,'LineWidth',1)
    
    
    plot([0.75 1.25],[nanmedian(Accuracy{1}) nanmedian(Accuracy{1})],'k','LineWidth',2)
    plot([1.75 2.25],[nanmedian(Accuracy{2}) nanmedian(Accuracy{2})],'color',Grey,'LineWidth',2)
    
    
    Ax = gca;
    Ax.XLim = [0.5 2.5];
    Ax.XTick = [1 2];
    Ax.YTick = [0 50 100];
    Ax.YTickLabel = {'0';'0.5';'1'};
    
    Ax.YLim = [0 100];
    Ax.XTickLabel = {'WMCD';'PC1'};
    ylabel('AUC');
    text(1.25,20,num2str(P));
end
