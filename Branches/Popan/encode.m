% unlike low dim dynamics, this is a general function... it does alot of
% models at once.
% unlike low dim dynamics, this function uses delay length averaged deviation
% to compute data points
% also sweeps PCs () and cell numbers
% also has contrasts

function [Index] = encode(Index, varargin)
TCD = true;
CCD = false;
DCD = false;
CCDDisc = false;
Stimulus = false;
History = false;

Folds = -1;
Window = [-1000 3200]; % first term is the pre
Model = 'LDA';
Equate = false;
DePre = false;
FPS = 4.68;
Iterate = 1;
Regularization = 10^(-4);
Threshold= 10^-3; % this basically zero (if 10% dff in 1 frame of 1 of 10 trials)
Clever = false;
OnlyCorrect = true;
NormalizeLDA = true;
AverageProjection = false; % bad, not cross validated traces
NoStim = false; % 210714 big change
OnlyDelay = false;
Minus = false;
Five = false;
Lag = 0;
Shuffle = false;
Shift = false;
OnlyPostCue = false;
OnlyPostProbe = false;
Smooth = 0;
BasisIn = [];
ZScore = false;
Memory = false;
Discrimination = false;

MultiValue = [];

% sweep
PCsCat = [];
PCsRaw = [];
PCsCloud = [];
Cells = [];
PCsExclude = [];

ValuesIn = [];
TraceValue = false;
CueTraceValue = false;

LabelFocus = false;
SoftFocus = false;

Balance = false;

RNG = 10;

%% PASS ARGUMENTS TO CONTROLS
for I=1:2:numel(varargin)
    eval([varargin{I} '= varargin{I+1};']);
end

Range = frame(Window,FPS);

if exist('Stim','var') % bug prevention for old code
    if Stim
        Stimulus = true;
    end
end

if Discrimination || Memory
   Task = swap({'Discrimination';'Memory'},Memory+1);
else
    Task = [];
end

if isstruct(Index)
    if NoStim
        Temp1 = 'NoStimulusResponsive';
    else
        Temp1 = [];
    end
    if OnlyDelay
        Temp2 = 'DelayResponsive';
    else
        Temp2 = [];
    end
    if TraceValue
        FType = 'Trace';
    elseif CueTraceValue
        FType = 'CueTrace';
    elseif FPS == 22.39
        FType = 'Ax';
    else
        FType = 'S';
    end
    
    [DFFs,~,Ripped] = rip(Index,FType,'DeNaN',Temp2,Temp1,'Active');
    %     [DFFsF,~,RippedF] = rip(Index,S,'DeNaN',Temp2,Temp1);
    
    if SoftFocus
        DFFs = soft_focus(DFFs,Index);
    end
    Flag = false;
else
    Ripped = [];
    DFFs = Index{1};
    Trials = Index{2};
    Flag = true; % i.e., this is not to encode
end

% what is limit?
for Session = 1:length(DFFs)
    clearvars TempValues
    if ~Flag
        Loaded = load(Index(Session).Name,'Trial');
        if CCD || CCDDisc % needs || stimulus for old code (sweep) to work
            Trial = Loaded.Trial;
            TempDB = Trial(and(Index(Session).Combobulation,destruct(Trial,'Task')==1)).DB;
            TempSel = false(length(Trial),1);
            TempSel(and(destruct(Trial,'DB')==TempDB,destruct(Trial,'Task')==1)) = true;
            Trial = Trial(and(destruct(Trial,'DB')==TempDB,destruct(Trial,'Task')==1));
            if ~OnlyPostProbe
                % main ccd one
                [Trial,TempTempSel] = selector(Trial,'NoReset','HasFrames','Nignore',swap({'Post';'Cue'},Stimulus+1));
            else
                [Trial,TempTempSel] = selector(Trial,'HasFrames','Nignore');
            end
            for J = 1:length(TempSel)
                if TempSel(J)
                    TempSel(J) = TempTempSel(1);
                    TempTempSel(1) = [];
                end
            end
            Sel = TempSel;
        elseif DCD % rotation only in disc blocks >>> add both tasks at some point?
            Trial = Loaded.Trial;
            %             TempSel = false(length(Trial),1);
            %             TempSel(destruct(Trial,'Task')==2) = true;
            %             Trial = Trial(and(destruct(Trial,'DB')==TempDB,destruct(Trial,'Task')==1));
            [Trial,Sel] = selector(Trial,'NoReset','HasFrames','Nignore',swap({'Post';'Cue'},Stimulus+1),'Discrimination');

            if length(unique(destruct(Trial,'DB'))) == 1
                Index(Session).Trace = nan;
                Index(Session).AvgTrace = nan;
                Index(Session).Basis = nan;
                Index(Session).Score = nan;
                Index(Session).Class = nan;
                continue
            end
            %             for J = 1:length(TempSel)
            %                 if TempSel(J)
            %                     TempSel(J) = TempTempSel(1);
            %                     TempTempSel(1) = [];
            %                 end
            %             end
            %             Sel = TempSel;
        else
            [Trial,Sel] = selector(Loaded.Trial,Index(Session).Combobulation,Task,'NoReset','HasFrames',swap({'Post';'Cue'},Stimulus+1),'Nignore','NoLight'); % no reason not to analyze trials
        end
    else
        Trial = Trials{Session};
        Sel = true(length(Trial),1);
    end
    
    % get labels
    Labels = get_labels(Trial,or(CCD,CCDDisc),Stimulus,DCD,Shuffle,OnlyCorrect,OnlyPostProbe,OnlyPostCue,Shift,History);
    
    % get activities
    [Activities,TrigOn,TrigOff ]= get_activities(DFFs{Session},Trial,Range,LabelFocus,Smooth,PCsCat,...
        Threshold,Ripped,FPS,Stimulus,Minus,ZScore,Iterate,Five,DePre,PCsRaw,PCsExclude,Lag,RNG);
    
    % get values after threshold
    Values= get_values(Activities,Clever,Five,DePre,Range,ValuesIn,Iterate,PCsCloud,Cells,RNG);
    
    % en-nan labels of nan values
    X = find(~all(isnan(Values)'),1);
    Labels(isnan(Values(X,:))) = nan;

    if ~isempty(MultiValue)
        TempRange = frame(MultiValue{1},FPS);

        % get activities
        TempActivities = get_activities(DFFs{Session},Trial,TempRange,LabelFocus,Smooth,PCsCat,...
            Threshold,Ripped,FPS,Stimulus,Minus,ZScore,Iterate,Five,DePre,PCsRaw,PCsExclude,MultiValue{2},RNG);
        
        % get values after threshold
        TempValues = get_values(TempActivities,Clever,Five,DePre,TempRange,ValuesIn,Iterate,PCsCloud,Cells,RNG);
        
        MultiValueIn = TempValues;
    else
        MultiValueIn = [];
    end
    
    %% test difference in values
    %     NewValues = Values;
    %     NewLabels = Labels;
    %     NewValues(isnan(NewValues(:,1)),:) = [];
    %     NewValues(:,isnan(NewLabels)) = [];
    %     NewLabels(isnan(NewLabels)) = [];
    %     for Cell = 1:size(NewValues,1)
    %         [~,P(Cell)] = ttest2(NewValues(Cell,NewLabels==1),NewValues(Cell,NewLabels==2));
    %     end
    %     sum(P<0.05) ./ size(NewValues,1)
    
    %% Discriminate
    clearvars TempBases TempTrace TempClasses TempDelayTrace TempAuxTrace
    TempScores = nan(length(Labels),Iterate);
    for I = 1:swap([1,Iterate],Equate+1)
        Loop = 1;
        while 1
            if Equate
                TempLabels = Labels;
                [A,B] = min([sum(TempLabels==1) sum(TempLabels==2)]);
                TempReplace = cat(1,repmat((3-B),[A 1]), nan(sum(TempLabels==(3-B))-A,1));
                TempLabels(TempLabels==(3-B)) = TempReplace(randperm(length(TempReplace)));
                IterLabels = TempLabels;
            else
                IterLabels = Labels;
            end
            
            if ~isempty(BasisIn)
                [TempBasis, TempScore, TempClasses(:,I), PartitionedBasis] = ...
                    discriminate2(Values,IterLabels,'Folds',Folds,'Model',Model,...
                    'Reg',Regularization,'Normalize',NormalizeLDA,...
                    'BasisIn',BasisIn{Session}');
            else
                [TempBasis, TempScore, TempClasses(:,I), PartitionedBasis] = ...
                    discriminate2(Values,IterLabels,'MultiValue',MultiValueIn,...
                    'Equate',swap([false Equate],2-PCsRaw),'Folds',Folds,...
                    'Model',Model,'Reg',Regularization,'Normalize',NormalizeLDA,...
                    'Balance',Balance);
            end
            
            if isnan(PartitionedBasis(1,1)) && Loop <= 100
                disp(char(strcat('Stuck in loop',{' '},num2str(Loop)))); Loop = Loop + 1;
                continue
            end
            TempBases(:,I) = nanmean(cat(2,TempBasis{:}),2);
            TempScores(~isnan(IterLabels),I) = TempScore;
            
            NumFolded = size(unique(PartitionedBasis(:,1)),1);
            %              210516   if OnlyCorrect || OnlyPostCue || OnlyPostProbe% enscore incorrect trials
            NotNaN = any(~isnan(Values(:,:))')';
            
            IncorrectIndex = find(isnan(Labels));
            for Z = 1:NumFolded%  <> size(PartitionedBasis)
                TempScores(IncorrectIndex(Z:NumFolded:end),I)...
                    = -([ones(size(Values(NotNaN,IncorrectIndex(Z:NumFolded:end)),2),1)...
                    Values(NotNaN,IncorrectIndex(Z:NumFolded:end))'] ...
                    * TempBasis{Z}([true; NotNaN]));
            end
            %                 end
            
            %                if ~Flag
            if ~AverageProjection
                IterTrigOn = TrigOn(~isnan(IterLabels)) - frame(1400,FPS); IterTrigOff = TrigOff(~isnan(IterLabels)) + frame(1400,FPS); % hack
                IterTrigOff(end) = min(IterTrigOff(end),size(DFFs{Session},2));
                
                %                     IterTrigOn(1) = max(IterTrigOn(1),1);
                IterTrigOn(IterTrigOn<1) = 1;
                
                % traces of equated
                TempTrace(I,:) = nan(1,size(DFFs{Session},2));
                for A = 1:5
                    TempAuxTrace{A}(I,:) = nan(1,size(DFFs{Session},2));
                end
                NotNaN = ~isnan(PartitionedBasis(1,2:end));
                
                % define aux bases
                try
                    % pc1 raw
                    Temp = pca(DFFs{Session}(NotNaN,~isnan(DFFs{Session}(1,:)))');% ones(size(PartitionedBasis(1,NotNaN)'))
                    PC1Raw = Temp(:,1);
                    % pc1 avg
                    Temp = pca(nanmean(Activities(NotNaN,abs(Range(1))+1:end,:),3)');% ones(size(PartitionedBasis(1,NotNaN)'))
                    PC1Avg = Temp(:,1);
                catch
                    PC1Raw = nan(size(Activities,1),1);
                    PC1Avg = nan(size(Activities,1),1);
                end
                if isnan(PC1Avg)
                    PC1Avg = nan(size(Activities,1),1);
                end
                for Trig = 1:sum(~isnan(IterLabels))
                    
                    TempActivity = [ones(size(DFFs{Session}(NotNaN,(IterTrigOn(Trig):IterTrigOff(Trig))),2),1)...
                        DFFs{Session}(NotNaN,(IterTrigOn(Trig):IterTrigOff(Trig)))'];
                    for A = 1:3
                        if A == 1 % average
                            TempAuxTrace{A}(I,IterTrigOn(Trig):IterTrigOff(Trig)) = (TempActivity * ones(size(PartitionedBasis(Trig,[true NotNaN])')))';
                        elseif A == 2
                            TempAuxTrace{A}(I,IterTrigOn(Trig):IterTrigOff(Trig)) = (TempActivity(:,2:end) * PC1Raw)';
                        elseif A == 3
                            TempAuxTrace{A}(I,IterTrigOn(Trig):IterTrigOff(Trig)) = (TempActivity(:,2:end) * PC1Avg)';
                        end
                    end
                    
                    if DePre
                        TempActivity(:,2:end) = TempActivity(:,2:end) - nanmean(TempActivity(1:abs(Range(1)),2:end),1);
                    end
                    TempTrace(I,IterTrigOn(Trig):IterTrigOff(Trig)) = (TempActivity * PartitionedBasis(Trig,[true NotNaN])')';
                    
                    Temp = PartitionedBasis(Trig,[true NotNaN]);
                    TempAuxTrace{4}(I,IterTrigOn(Trig):IterTrigOff(Trig)) = (TempActivity * Temp([1 randperm(length(Temp)-1)+1])')';
                end
                
                %210516   %  if OnlyCorrect || OnlyPostCue || OnlyPostProbe
                NotNaN = ~isnan(PartitionedBasis(1,2:end));
                IncorrectTrigOn = TrigOn(IncorrectIndex) - frame(1400,FPS); IncorrectTrigOff = TrigOff(IncorrectIndex) + frame(1400,FPS); % hack
                IncorrectTrigOff(end) = min(IncorrectTrigOff(end),size(DFFs{Session},2));
                
                IncorrectTrigOn(find(IncorrectTrigOn<1)) = max(IncorrectTrigOn(find(IncorrectTrigOn<1)),1);
                
                for Z =1:NumFolded
                    for Trig = (0:NumFolded:length(IncorrectIndex)) + Z
                        if Trig <= length(IncorrectIndex)
                            
                            TempActivity =[ones(size(DFFs{Session}(NotNaN,(IncorrectTrigOn(Trig):IncorrectTrigOff(Trig))),2),1)...
                                DFFs{Session}(NotNaN,(IncorrectTrigOn(Trig):IncorrectTrigOff(Trig)))'];
                            
                            for A = 1:3
                                if A == 1 % average
                                    TempAuxTrace{A}(I,IncorrectTrigOn(Trig):IncorrectTrigOff(Trig)) = (TempActivity(:,2:end) * ones(size(TempBasis{Z}(NotNaN))));
                                elseif A == 2
                                    TempAuxTrace{A}(I,IncorrectTrigOn(Trig):IncorrectTrigOff(Trig)) = (TempActivity(:,2:end) * PC1Raw)';
                                elseif A == 3
                                    TempAuxTrace{A}(I,IncorrectTrigOn(Trig):IncorrectTrigOff(Trig)) = (TempActivity(:,2:end) * PC1Avg)';
                                end
                            end
                            
                            if DePre
                                TempActivity(:,2:end) = TempActivity(:,2:end) - nanmean(TempActivity(1:abs(Range(1)),2:end),1);
                            end
                            
                            TempTrace(I,IncorrectTrigOn(Trig):IncorrectTrigOff(Trig)) = (TempActivity(:,1:end) * TempBasis{Z}([true NotNaN]))';
                            Temp = TempBasis{Z}([true NotNaN]);
                            TempAuxTrace{4}(I,IncorrectTrigOn(Trig):IncorrectTrigOff(Trig)) = (TempActivity(:,1:end) * Temp([1 randperm(length(Temp)-1)+1]))';
                            
                        end
                    end
                end
                %                     end
                %                 end
            end
            break
        end
    end
    Bases{Session} = nanmean(TempBases,2);
    Classes(Session) = nanmean(TempClasses,2);
    Scores{Session} = nanmean(TempScores,2);
    %         if ~Flag; Traces{Session} = nanmean(TempTrace,1); end
    %         if ~Flag; AvgTraces{Session} = nanmean(TempAuxTrace,1); end
    
    if AverageProjection
        NotNaN = ~isnan(Bases{Session}(2:end));
        
        for A = 1:4
            AuxTraces{A}{Session} = (([ones(size(DFFs{Session}(NotNaN,:),2),1) DFFs{Session}(NotNaN,:)'] ...
                * ones(size(Bases{Session}([true; NotNaN]),1),1))');
            AuxTraces{A}{Session} = (AuxTraces{A}{Session} - nanmean(AuxTraces{A}{Session})) / std(AuxTraces{A}{Session},[],2,'omitnan');
        end
        
        Traces{Session} = (([ones(size(DFFs{Session}(NotNaN,:),2),1) DFFs{Session}(NotNaN,:)'] ...
            * Bases{Session}([true; NotNaN]))');
        Traces{Session} = (Traces{Session} - nanmean(Traces{Session})) / std(Traces{Session},[],2,'omitnan');
    else
        Traces{Session} = nanmean(TempTrace,1);
        for A = 1:4
            AuxTraces{A}{Session} = nanmean(TempAuxTrace{A},1);
        end
    end
    
    %         % debug plot
    %         figure;plot(Traces{Session},'k','LineWidth',1); hold on
    %         for Z = 1:length(TrigOn)
    %             line([TrigOn(Z) TrigOn(Z)],[min(Traces{Session}) max(Traces{Session})],'LineWidth',1,'color',swap({'r','b',[0.5 0.5 0.5]},Labels(Z)))
    %         end
    
    Score = nan(length(Sel),1);
    Score(Sel) = Scores{Session};
    Scores{Session} = Score;
    %% save
    if ~Flag
        if History
            Index(Session).HistoryTrace = Traces{Session};
            Index(Session).HistoryAvgTrace = AuxTraces{1}{Session};
            Index(Session).HistoryBasis = Bases{Session};
            Index(Session).HistoryScore = Scores{Session};
            Index(Session).HistoryClass = Classes(Session);
        elseif ~CCD && ~Stimulus && ~DCD
            Index(Session).Trace = Traces{Session};
            Index(Session).AvgTrace = AuxTraces{1}{Session};
            Index(Session).Basis = Bases{Session};
            Index(Session).Score = Scores{Session};
            Index(Session).Class = Classes(Session);
            Index(Session).TaskTrace = Traces{Session};
            Index(Session).TaskAvgTrace = AuxTraces{1}{Session};
            Index(Session).TaskBasis = Bases{Session};
            Index(Session).TaskScore = Scores{Session};
            Index(Session).TaskClass = Classes(Session);
        elseif ~Stimulus && CCD
            Index(Session).CueTrace = Traces{Session};
            Index(Session).CueAvgTrace = AuxTraces{1}{Session};
            Index(Session).CueBasis = Bases{Session};
            Index(Session).CueScore = Scores{Session};
            Index(Session).CueClass = Classes(Session);
        elseif ~Stimulus && DCD
            Index(Session).DistractorTrace = Traces{Session};
            Index(Session).DistractorAvgTrace = AuxTraces{1}{Session};
            Index(Session).DistractorBasis = Bases{Session};
            Index(Session).DistractorScore = Scores{Session};
            Index(Session).DistractorClass = Classes(Session);
        elseif Stimulus && ~CCD && ~DCD
            Index(Session).TaskStimulusTrace = Traces{Session};
            Index(Session).TaskStimulusAvgTrace = AuxTraces{1}{Session};
            Index(Session).TaskStimulusBasis = Bases{Session};
            Index(Session).TaskStimulusScore = Scores{Session};
            Index(Session).TaskStimulusClass = Classes(Session);
        elseif Stimulus && CCD
            Index(Session).CueStimulusTrace = Traces{Session};
            Index(Session).CueStimulusAvgTrace = AuxTraces{1}{Session};
            Index(Session).CueStimulusBasis = Bases{Session};
            Index(Session).CueStimulusScore = Scores{Session};
            Index(Session).CueStimulusClass = Classes(Session);
        elseif Stimulus && DCD
            Index(Session).DistractorStimulusTrace = Traces{Session};
            Index(Session).DistractorStimulusAvgTrace = AuxTraces{1}{Session};
            Index(Session).DistractorStimulusBasis = Bases{Session};
            Index(Session).DistractorStimulusScore = Scores{Session};
            Index(Session).DistractorStimulusClass = Classes(Session);
        elseif Stimulus
            Index(Session).StimTrace = Traces{Session};
            Index(Session).StimAvgTrace = AuxTraces{1}{Session};
            Index(Session).StimBasis = Bases{Session};
            Index(Session).StimScore = Scores{Session};
            Index(Session).StimClass = Classes(Session);
        end
        %         Trace = Traces{Session};
        %         Basis = Bases{Session};
        %         Trial = AllTrial;
        %         save(Index(Session).Name,'Trial','Basis','Trace','-append');
    else
        Out{1}{Session} = Bases{Session};
        Out{2}{Session} = Scores{Session};
        Out{3}(Session) = Classes(Session);
        %         Out{4}{Session} = Traces{Session};
        try
            Out{5}{Session} = Explanations{Session};
        catch
            Out{5}{Session} = nan;
        end
        Out{6}{Session} = Traces{Session};
        Out{7}{Session} = AuxTraces{1}{Session};
        
        % pca1 raw
        Out{8}{Session} = AuxTraces{2}{Session};
        
        % pc1 trial avg
        Out{9}{Session} = AuxTraces{3}{Session};
        
        % shuffle coef
        Out{10}{Session} = AuxTraces{4}{Session};
    end
end

if Flag
    Index = Out;
end

%% MISC


% figure;
% plot(Classes);Ax=gca; Ax.YLim = [0.5 1];

%% FILL OUT REST
%         % encode equated
%         TempTrial = Trial(~isnan(IterLabels));
%         for II = 1:length(TempTrial)
%             TempTrial(II).Score = Scores{Session}(II);
%         end
%         Trial(1).Score = [];
%         Trial(~isnan(IterLabels)) = TempTrial;
%
%         TempTrial = AllTrial(Sel);
%         for II = 1:length(TempTrial)
%             TempTrial(II).Score = Trial(II).Score;
%             TempTrial(II).ClassificationScore = Trial(II).Score;
%         end
%         AllTrial(1).Score = [];
%         AllTrial(1).ClassificationScore = [];
%         AllTrial(Sel) = TempTrial;


%         % encode everything else
%         [FullBasis, DeBugScore, DeBugClass] = ...
%             discriminate2(Values,Labels,'Fold',1,'Model',Model);
%         Basis = FullBasis{1};
%
%         % get FULL VALUES
%         TrigOn = destruct(AllTrial,'Trigger.Delay.Frame');
%         TrigOff = destruct(AllTrial,'Trigger.Stimulus.Frame');
%         Activities = wind_roi(DFFs{Session},{TrigOn;TrigOff},'Window',Range);
%         FullValues = reshape((nanmean(Activities(:,end-Range(2)+1:end,:),2)),[size(Activities,1) size(Activities,3)]);
%         FullScores = -([ones(size(FullValues(~isnan(Basis(2:end)),:),2),1) FullValues(~isnan(Basis(2:end)),:)'] * Basis(~isnan(Basis)));
%
%         for T = 1:length(AllTrial)
%             if isempty(AllTrial(T).Score)
%                 AllTrial(T).Score = FullScores(T);
%             end
%         end
%         Trials{Session} = AllTrial;
%
%         TempTraces = nan(1,size(DFFs{Session},2));
%         for Trig = 1:length(AllTrial)
%             try
%                 TempTraces(TrigOn(Trig):TrigOff(Trig)) = ([ones(size(DFFs{Session}(:,(TrigOn(Trig):TrigOff(Trig))),2),1)...
%                     DFFs{Session}(:,(TrigOn(Trig):TrigOff(Trig)))'] * Basis(:))';
%             end
%         end
%         Traces{Session}(isnan(Traces{Session})) = TempTraces(isnan(Traces{Session}));
