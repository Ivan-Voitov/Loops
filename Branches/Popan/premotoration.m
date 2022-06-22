function premotoration(Index,varargin)
% an encode-style function which has CDFA and also cross-task functionality
% and also does the cue just for now for sanity checks

Folds = -1;
Window = [0 3200]; % first term is the pre
Model = 'LDA';
Equate = false; % !!!
Balance = true;
FPS = 4.68;
Iterate = 1; % !!!
Regularization = 10^(-3);
Threshold= 10^-3; % 3 is basically zero (if 10% dff in 1 frame of 1 of 10 trials)
BasisIn = [];
ValuesIn = [];
% CueControl = false;
Prior = [0.5 0.5];

Style = 1;

Minus = false;
Stimulus = false;

%% READY
for I=1:2:numel(varargin)
    eval([varargin{I} '= varargin{I+1};']);
end

%% SET
Range = frame(Window,FPS);
[DFFs,Trials,Ripped] = rip(Index,'S','DeNaN','Active','AllTrials');
if Equate == false
    Iterate = 1;
end

%% GO
for Session = 1:length(DFFs)
    
    clearvars TempValues
    % test for sessions with double db's for WM and disc
    %         TempDB = Trial(and(Index(Session).Combobulation,destruct(Trial,'Task')==1)).DB;
    
    %         sum(or(and(~destruct(Trial,'DB')==TempDB,destruct(Trial,'Task')==1),...
    %         and(~destruct(Trial,'DB')==(-TempDB),destruct(Trial,'Task')==2)))
    
    % fix for sessions with double db's for WM and disc
    %         Trial(or(and(~destruct(Trial,'DB')==TempDB,destruct(Trial,'Task')==1),...
    %         and(~destruct(Trial,'DB')==(-TempDB),destruct(Trial,'Task')==2))) = [];
    
    [Trial] = selector(Trials{Session},'NoReset','HasFrames',swap({'Post';'Cue'},Stimulus+1),'Nignore');
    
    % get labels
    LickLabels = nan(length(Trial),1);
    LickLabels(destruct(Trial,'ResponseType')==1) = 1;
    LickLabels(destruct(Trial,'ResponseType')==2) = 2;
    
    CueLabels = nan(length(Trial),1);
    CueLabels(destruct(Trial,'Block')==1) = 1;
    CueLabels(destruct(Trial,'Block')==0) = 2;
    
    % get activities
    if ~Stimulus
        TrigOn = destruct(Trial,'Trigger.Delay.Frame');
        TrigOff = destruct(Trial,'Trigger.Stimulus.Frame');
    else
        TrigOn = destruct(Trial,'Trigger.Stimulus.Frame');
        TrigOff = destruct(Trial,'Trigger.Post.Frame');
    end
    
    if Minus
        TrigOn = TrigOff - Range(2);
        TrigOff(TrigOff<max(TrigOff)) = TrigOff(TrigOff<max(TrigOff))+1;
    end
    
    Activities = wind_roi(DFFs{Session},{TrigOn;TrigOff},'Window',Range);
    if ~isempty(Threshold)
        [EnNaN] = threshold_values(Activities,Range,Iterate,Threshold,false,false,10);
        % hack to make sure i get delay responsive things
        if FPS ~= 22.79
            try
                EnNaN(Ripped(Session).DelayResponsive) = false;
            end
        end
        Activities(EnNaN,:,:) = nan;
    end
    
    % get values after threshold
    [Values] = get_values(Activities,false,false,false,Range,ValuesIn,Iterate,[],[],10);
    
    % en-nan labels of nan values
    X = find(~all(isnan(Values)'),1);
    LickLabels(isnan(Values(X,:))) = nan;
    CueLabels(isnan(Values(X,:))) = nan;
    
    %% BUILD DECODER
    for Condition = [1:4] % train on: D WM D WM
        try
            % not the right task i nan
            SplitLickLabels = LickLabels;
            SplitLickLabels(~(destruct(Trial,'Task')==rem(Condition,2)+1)) = nan;
            
            SplitCueLabels = CueLabels;
            SplitCueLabels(~(destruct(Trial,'Task')==rem(Condition,2)+1)) = nan;
            
            % not the right task i nan (= split labels) or nan the others
            if Condition > 2
                OfInterestLick = LickLabels;
                OfInterestLick(destruct(Trial,'Task')==rem(Condition,2)+1) = nan;
                OfInterestCue = CueLabels;
                OfInterestCue(destruct(Trial,'Task')==rem(Condition,2)+1) = nan;
            else
                OfInterestLick = SplitLickLabels;
                OfInterestCue = SplitCueLabels;
            end
            
            clearvars TempCueClass TempLickClass TempCueAvgBasis TempLickAvgBasis TempBases TempTrace TempClasses TempDelayTrace TempAuxTrace TempLickClasses TempCueClasses TempLickBases TempCueBases
            TempLickScores = nan(length(SplitLickLabels),Iterate);
            TempCueScores = nan(length(SplitCueLabels),Iterate);
            for I = 1:Iterate
                %% discriminate
                if Equate
                    TempLabels = SplitLickLabels;
                    [A,B] = min([sum(TempLabels==1) sum(TempLabels==2)]);
                    TempReplace = cat(1,repmat((3-B),[A 1]), nan(sum(TempLabels==(3-B))-A,1));
                    TempLabels(TempLabels==(3-B)) = TempReplace(randperm(length(TempReplace)));
                    IterLickLabels = TempLabels;
                    TempLabels = SplitCueLabels;
                    [A,B] = min([sum(TempLabels==1) sum(TempLabels==2)]);
                    TempReplace = cat(1,repmat((3-B),[A 1]), nan(sum(TempLabels==(3-B))-A,1));
                    TempLabels(TempLabels==(3-B)) = TempReplace(randperm(length(TempReplace)));
                    IterCueLabels = TempLabels;
                else
                    IterLickLabels = SplitLickLabels;
                    IterCueLabels = SplitCueLabels;
                end
                
                [~, TempLickScore, TempLickClass(:,I), TempLickBasis] = ...
                    discriminate2(Values,IterLickLabels,'Prior',Prior,'Folds',Folds,'Model',Model,'Reg',Regularization,'Normalize',1,...
                    'Balance',Balance);
                %             TempLickClass(:,I)
                [~, TempCueScore, TempCueClass(:,I), TempCueBasis] = ...
                    discriminate2(Values,IterCueLabels,'Prior',Prior,'Folds',Folds,'Model',Model,'Reg',Regularization,'Normalize',1,...
                    'Balance',Balance);
                
                TempLickAvgBasis(:,I) = nanmean(cat(2,TempLickBasis'),2);
                TempLickScores(~isnan(IterLickLabels),I) = TempLickScore;
                
                TempCueAvgBasis(:,I) = nanmean(cat(2,TempCueBasis'),2);
                TempCueScores(~isnan(IterCueLabels),I) = TempCueScore;
                
                %% fill out the rest of the scores (can even be in discriminate if clever)
                NotNaN = ~isnan(TempLickAvgBasis(2:end,I));
                ToFill = find(isnan(IterLickLabels));
                RotatingLickBasis = TempLickBasis';
                for Z = ToFill'
                    TempLickScores(Z) = -([1; ...
                        Values(NotNaN,Z)]' ...
                        * RotatingLickBasis([true; NotNaN],1));
                    RotatingLickBasis = circshift(RotatingLickBasis',1)';
                end
                
                NotNaN = ~isnan(TempCueAvgBasis(2:end,I));
                ToFill = find(isnan(IterCueLabels));
                RotatingCueBasis = TempCueBasis';
                for Z = ToFill'
                    TempCueScores(Z) = -([1; ...
                        Values(NotNaN,Z)]' ...
                        * RotatingCueBasis([true; NotNaN],1));
                    RotatingCueBasis = circshift(RotatingCueBasis',1)';
                end
                
                %% recalc classes
                TempCrossLickClass(:,I) = ( (nansum(double(TempLickScores(:,I) < 0) .* double(OfInterestLick-1)) ./ nansum(OfInterestLick==2)) + ...
                    ((nansum(double(TempLickScores(:,I) >= 0) .* double(1 - (OfInterestLick-1))) ./ nansum(OfInterestLick==1))) ) ./2;
                
                TempCrossCueClass(:,I) = ( (nansum(double(TempCueScores(:,I) < 0) .* double(OfInterestCue-1)) ./ nansum(OfInterestCue==2)) + ...
                    ((nansum(double(TempCueScores(:,I) >= 0) .* double(1 - (OfInterestCue-1))) ./ nansum(OfInterestCue==1))) ) ./2;
                
                %% for plotting classes
                TempCrossCRClass(:,I) = (nansum(double(TempLickScores(:,I) >= 0) .* double(1 - (OfInterestLick-1))) ./ nansum(OfInterestLick==1));
                TempCrossFAClass(:,I) = (nansum(double(TempLickScores(:,I) < 0) .* double(OfInterestLick-1)) ./ nansum(OfInterestLick==2));
                
                %% for plotting (avg scores per OfInterest selection)
                TempLickScores = zscore(TempLickScores,[],'omitnan');
                TempCueScores = zscore(TempCueScores,[],'omitnan');
                
                TempAvgFAScore(I) = nanmean((double(TempLickScores((1 - (OfInterestLick-1))==1,I))));
                TempAvgCRScore(I) = nanmean((double(TempLickScores((1 - (OfInterestLick-1))==0,I))));
                
                TempAvgCueAScore(I) = nanmean((double(TempCueScores((1 - (OfInterestCue-1))==1,I))));
                TempAvgCueBScore(I) = nanmean((double(TempCueScores((1 - (OfInterestCue-1))==0,I))));
                
            end
            
            AvgCueAScore(Session,Condition) = nanmean(TempAvgCueAScore);
            AvgCueBScore(Session,Condition) = nanmean(TempAvgCueBScore);
            
            AvgFAScore(Session,Condition) = nanmean(TempAvgFAScore);
            AvgCRScore(Session,Condition) = nanmean(TempAvgCRScore);
            
            AvgFAClass(Session,Condition) = nanmean(TempCrossCRClass);
            AvgCRClass(Session,Condition) = nanmean(TempCrossFAClass);
            
            LickClasses(Session,Condition) = nanmean(TempLickClass,2);
            CueClasses(Session,Condition) = nanmean(TempCueClass,2);
            
            CrossLickClasses(Session,Condition) = nanmean(TempCrossLickClass,2);
            CrossCueClasses(Session,Condition) = nanmean(TempCrossCueClass,2);
            
            %             Bases{Session,Condition} = nanmean(TempBases,2);
            %             Classes(Session,Condition) = nanmean(TempClasses,2);
            %             CrossClasses(Session,Condition) = nanmean(CrossClass,2);
            %             Scores{Session,Condition} = nanmean(TempScores,2);
        catch
            AvgCueAScore(Session,Condition) = nan;
            AvgCueBScore(Session,Condition) = nan;
            
            AvgFAScore(Session,Condition) = nan;
            AvgCRScore(Session,Condition) = nan;
            
            LickClasses(Session,Condition) = nan;
            CueClasses(Session,Condition) = nan;
            
            CrossLickClasses(Session,Condition) = nan;
            CrossCueClasses(Session,Condition) = nan;
            
        end
    end
    %         Classes(Session,:)
end

%% remove nan
CrossLickClasses(isnan(sum(CrossLickClasses')),:) = [];

%% plot
Colours;
%%
figure;
for C = 1:4
    [Mu(C) CI(C)] = normfit(CrossLickClasses(:,C));
end

errorbar([1 2 3 4],Mu,CI,'color',Black,'LineWidth',2,'Marker','o','MarkerFaceColor',White)

axis([0.75 4.25 0.4 1]);
Ax = gca;
Ax.YTick = [0 0.5 1];
Ax.XTick = [1 2 3 4];
ylabel('Classification accuracy (%)');
Ax.XTickLabel = {'D train, D test';'WM train, WM test';'D train, WM test';'WM train, D test'};

for C = 1:4
    P = signrank(CrossLickClasses(:,C),repmat(0.5,[size(CrossLickClasses,1) 1]));
    text(0.1+C,0.75,num2str(P))
end

%%
figure;
plot(CrossLickClasses','LineStyle','none','LineWidth',2,'color',Black,'Marker','o','MarkerFaceColor',White); hold on;

axis([0.75 4.25 0.4 1]);
Ax = gca;
Ax.YTick = [0 0.5 1];
Ax.XTick = [1 2 3 4];
ylabel('Classification accuracy (%)');
Ax.XTickLabel = {'D train, D test';'WM train, WM test';'D train, WM test';'WM train, D test'};

for C = 1:4
    plot([-0.2 0.2]+C,nanmedian([CrossLickClasses(:,C) CrossLickClasses(:,C)],1),'color',Black,'LineWidth',4)
    
    P = signrank(CrossLickClasses(:,C),repmat(0.5,[size(CrossLickClasses,1) 1]));
    text(0.1+C,0.75,num2str(P))
end

%%
figure;
for C = 1:4
    subplot(1,4,C);
    plot(-[AvgCRScore(:,C) AvgFAScore(:,C)]','color',Black,'LineWidth',0.5); hold on;
    plot([ones(size(AvgCRScore,1),1)], -[AvgCRScore(:,C)],'LineStyle','none','color',Black,'Marker','o','MarkerFaceColor',White,'LineWidth',2);
    plot([ones(size(AvgCRScore,1),1)]+1, -[AvgFAScore(:,C)],'LineStyle','none','color',Red,'Marker','o','MarkerFaceColor',White,'LineWidth',2);
    
    plot([0.8 1.2],nanmedian(-[AvgCRScore(:,C) AvgCRScore(:,C)],1),'color',Black,'LineWidth',4)
    plot([1.8 2.2],nanmedian(-[AvgFAScore(:,C) AvgFAScore(:,C)],1),'color',Black,'LineWidth',4)
    
    
    P = signrank(AvgCRScore(:,C), AvgFAScore(:,C));
    text(1.1,0,num2str(P))
    text(1.1,0.1,num2str(nanmean(CrossLickClasses(:,C))));
    Min = min(cat(1,-AvgCRScore(:,C),-AvgFAScore(:,C)));
    Max = max(cat(1,-AvgCRScore(:,C),-AvgFAScore(:,C)));
    axis([0.75 2.25 Min Max]);
    Ax = gca;
    Ax.YTick = 0;
    Ax.XTick = [1 2];
    Ax.XTickLabel = {'Pre-CR';'Pre-FA'};
    ylabel('Score');
    title(swap({'D train, D test';'WM train, WM test';'D train, WM test';'WM train, D test'},C));
end

% cue control
% for C = 1:4
%     subplot(2,4,C+4); plot([AvgCueAScore(:,C) AvgCueBScore(:,C)]');
%     P = signrank(AvgCueAScore(:,C), AvgCueBScore(:,C));
%     text(1.1,0,num2str(P))
%     text(1.1,0.1,num2str(nanmean(CrossCueClasses(:,C))))
% end
