function [DFFs,Trials,Index] = rip(Index,varargin)
% rip like:
% Normal (use for classifying tuning curves)
% Trials: has frames, running
% DFFs: active
% Super
% Trials: '' + nignore + post
% DFFs: ''
% Hyper (use for popan)
% Trials: '' + split into contrast blocks
% DFFs: ''
% Ultra (use for Breakan) % code l8r
% Trials: '' + set blocks
% DFFs: ''
% can:
% ZSCORE
% DFF (df/f0)
% NaN ignoreseries
% deset

%% LOAD DATA
for I = 1:length(Index)
    if ~any(strcmp(varargin,'Beh'))
        if any(strcmp(varargin,'S'))
            % speed up
            if I > 1
%                 if strcmp(Index(I).Name, Index(I-1).Name)
%                     Trial = StoredTrial;
%                 else
                    load(Index(I).Name,'Trial','Spikes');
                    DFF = Spikes;
                    StoredTrial = Trial;
%                 end
            else
                load(Index(I).Name,'Trial','Spikes');
                DFF = Spikes;
                StoredTrial = Trial;
            end
        elseif any(strcmp(varargin,'Ax'))
            load(Index(I).Name,'Trial','ConfidentAxon');
            DFF = ConfidentAxon;
        elseif any(strcmp(varargin,'Trace'))
            load(Index(I).Name,'Trial');
            DFF = Index(I).Trace;
        elseif any(strcmp(varargin,'CueTrace'))
            load(Index(I).Name,'Trial');
            DFF = Index(I).CueTrace;
        elseif any(strcmp(varargin,'DistractorTrace'))
            load(Index(I).Name,'Trial');
            DFF = Index(I).DistractorTrace;
        elseif any(strcmp(varargin,'AverageTrace'))
            load(Index(I).Name,'Trial','Spikes');
            DFF = nanmean(Spikes,1);
        elseif any(strcmp(varargin,'DelayTrace'))
            load(Index(I).Name,'Trial');
            DFF = Index(I).DelayTrace;
        else
            load(Index(I).Name,'DFF','Trial');
        end
        
        %% MODIFY TIMESERIES
        if any(strcmp(varargin,'DeNaN'))
            DFF(:,Index(I).Ignore) = nan;
            if any(~isnan(Index(I).Pupil(:)))
                DFF(:,find(Index(I).Pupil(:,4))) = nan;
            end
        end
        if any(strcmp(varargin,'Z'))
            DFF = zscore(DFF',[],'omitnan')';
        end
        if any(strcmp(varargin,'Normalize'))
            DFF = DFF ./ nanstd(DFF(:));
        end
        if any(strcmp(varargin,'Zcore'))
            DFF = DFF ./ nanstd(Index(I).Score);
        end
        
        if any(strcmp(varargin,'DFF'))
            F0 = f0_spline(DFF);
            DFF = (DFF - F0) ./ F0;
        end
        
        Select = true(size(DFF,1),1)';
    else
        load(Index(I).Name,'Trial');
        Select = true(Index(I).CellCount,1)';
    end
    %% SELECT CELLS
    if any(strcmp(varargin,'Skewed'))
        Select = and(Select,Index(I).Skewness > prctile(Index(I).Skewness,50));
    end
    if any(strcmp(varargin,'Active'))
        Select = and(Select,Index(I).Active);
    end
    if any(strcmp(varargin,'Spiky')) % top ~65%
        Select = and(Select,Index(I).Spikiness > 75);
    end
    if any(strcmp(varargin,'VerySpiky')) % top ~40%
        Select = and(Select,Index(I).Spikiness > 90);
    end
    if any(strcmp(varargin,'SuperSpiky')) % top 
        Select = and(Select,Index(I).Spikiness > 95);
    end
    if any(strcmp(varargin,'Inactive'))
        Select = and(Select,~Index(I).Active);
    end
    if any(strcmp(varargin,'Fitted'))
        Select = and(Select,Index(I).Fitability < 20);
    end
    if any(strcmp(varargin,'DelayResponsive'))
        Select = and(Select,Index(I).DelayResponsive);
    end
    if any(strcmp(varargin,'VeryDelayResponsive'))
        Select = and(Select,Index(I).VeryDelayResponsive);
    end
    if any(strcmp(varargin,'StimulusResponsive'))
        Select = and(Select,Index(I).StimulusResponsive);
    end
    if any(strcmp(varargin,'NoStimulusResponsive'))
        Select = and(Select,~Index(I).StimulusResponsive);
    end
    if any(strcmp(varargin,'Triggerable'))
        Select = and(Select,or(Index(I).DelayResponsive,...
            Index(I).StimulusResponsive));
    end
    if any(strcmp(varargin,'Untriggerable'))
        Select = and(Select,and(~Index(I).DelayResponsive,...
            ~Index(I).StimulusResponsive));
    end
    if ~any(strcmp(varargin,'Trace'))  && ~any(strcmp(varargin,'DistractorTrace')) && ~any(strcmp(varargin,'CueTrace'))  && ~any(strcmp(varargin,'AverageTrace')) && ~any(strcmp(varargin,'Beh'))
        DFF = DFF(Select,:);
    end
    % second phase!!!
    if ~any(strcmp(varargin,'Beh'))
        Select2 = true(size(DFF,1),1)';
    else
        Select2 = true(length(Select),1)';
    end
    if any(strcmp(varargin,'Based'))
        Select2 = and(Select2,~isnan(Index(I).Basis(2:end))');
    end
    if ~any(strcmp(varargin,'Trace')) && ~any(strcmp(varargin,'Beh'))
        DFF = DFF(Select2,:);
    end
    % third phase
    Names = fieldnames(Index(I));
    if ~any(strcmp(varargin,'Blocks'))
        try
            for F = [7:min(length(Names)-1,20)] % not first ones, and not deset
                Index(I).(Names{F}) = Index(I).(Names{F})(Select);
            end
        catch
            for F = [7:min(length(Names)-2,20)] % not first ones, and not deset, and not verydelayresponsive
                Index(I).(Names{F}) = Index(I).(Names{F})(Select);
            end
        end
    else
        for F = [7:11]
            Index(I).(Names{F}) = Index(I).(Names{F})(Select);
        end
    end
    % cell count
    Index(I).(Names{3}) = sum(Select);
    
    %% SELECT TRIALS
    % FIRST THING'S FIRST, LET'S RECOMBOBULATE
    %     Trial = Trial(Index(I).Combobulation);
    % AND THE REST...
    %     if any(strcmp(varargin,'DeSet'))
    %         Trial = Trial(destruct(Trial,'Set')==1);
    %     end
    % include in this list combobulation for bug purposes
    if any(strcmp(varargin,'Normal'))
        Trial = selector(Trial,Index(I).Combobulation,'HasFrames','Nignore'); % all analysable trials
        
    elseif any(strcmp(varargin,'Super'))
        Trial = selector(Trial,Index(I).Combobulation,'NoReset','HasFrames','Post','Nignore'); % no reason not to analyze trials
    elseif any(strcmp(varargin,'SuperO'))
        TempDB = Trial(and(Index(I).Combobulation,destruct(Trial,'Task')==1)).DB;
        Trial = selector(Trial,~Index(I).Combobulation,swap({'Minus';'Plus'},(TempDB==15)+1),'NoReset','HasFrames','Post','Nignore'); % no reason not to analyze trials
        
    elseif any(strcmp(varargin,'Hyper'))
        TempDB = Trial(and(Index(I).Combobulation,destruct(Trial,'Task')==1)).DB;
        Trial = selector(Trial,Index(I).Combobulation,'NoReset','HasFrames','Post','Nignore','Cue'); % nothing but visual responses
    elseif any(strcmp(varargin,'HyperO'))
        TempDB = Trial(and(Index(I).Combobulation,destruct(Trial,'Task')==1)).DB;
        Trial = selector(Trial,~Index(I).Combobulation,swap({'Minus';'Plus'},(TempDB==15)+1),'NoReset','HasFrames','Post','Nignore','Cue'); % no reason not to analyze trials
        
    elseif any(strcmp(varargin,'Context')) || any(strcmp(varargin,'Sontext'))
        %         What is DB of combobulated
        TempDB = Trial(and(Index(I).Combobulation,destruct(Trial,'Task')==1)).DB;
        if ~isfield(Index(I),'DeSet')
            Trial = Trial(and(destruct(Trial,'DB')==TempDB,destruct(Trial,'Task')==1));
        else
            if ~isempty(Index(I).DeSet)
                Trial = Trial(and(Index(I).DeSet,and(destruct(Trial,'DB')==TempDB,destruct(Trial,'Task')==1)));
                
                %                 Trial = Trial(Index(I).DeSet);
            else
                Trial = Trial(and(destruct(Trial,'DB')==TempDB,destruct(Trial,'Task')==1));
            end
        end
        Trial = selector(Trial,'NoReset','HasFrames','Nignore',...
            swap({'Post';'Cue'},any(strcmp(varargin,'Sontext'))+1));
    elseif any(strcmp(varargin,'Dontext'))
        TempDB = Trial(and(Index(I).Combobulation,destruct(Trial,'Task')==2)).DB;
        Trial = Trial(and(destruct(Trial,'DB')==TempDB,destruct(Trial,'Task')==2));
        Trial = selector(Trial,'NoReset','HasFrames','Nignore','Post');
    elseif any(strcmp(varargin,'Rotext')) % disc in both rotation blocks
        Trial = selector(Trial,'NoReset','HasFrames','Nignore','Post','Discrimination');
    elseif any(strcmp(varargin,'DistractorCue'))
        %         TempDB = Trial(and(Index(I).Combobulation,destruct(Trial,'Task')==1)).DB;
        Trial = Trial(or(and(Index(I).Combobulation,destruct(Trial,'Task')==1),...
            destruct(Trial,'Task')==2));
        Trial = selector(Trial,'NoReset','HasFrames','Nignore','Post');
        
    elseif any(strcmp(varargin,'Cross')) % basically context and the opposite db disc task
        TempDB1 = Trial(and(Index(I).Combobulation,destruct(Trial,'Task')==1)).DB;
        TempDB2 = Trial(and(Index(I).Combobulation,destruct(Trial,'Task')==2)).DB;
        Trial = Trial(or(and(destruct(Trial,'DB')==TempDB2,destruct(Trial,'Task')==2),and(destruct(Trial,'DB')==TempDB1,destruct(Trial,'Task')==1)));
        Trial = selector(Trial,'NoReset','HasFrames','Nignore','Post');
    elseif any(strcmp(varargin,'AllTrials'))
        % still keeps track of combob'd. basically a context AND a matched
        % distractor
        TempDB = Trial(and(Index(I).Combobulation,destruct(Trial,'Task')==1)).DB;
        Trial = Trial(or(and(destruct(Trial,'DB')~=TempDB,destruct(Trial,'Task')==2),...
            and(destruct(Trial,'DB')==TempDB,destruct(Trial,'Task')==1)));
        Trial = selector(Trial,'NoReset','HasFrames','Nignore','Post');
    elseif any(strcmp(varargin,'Blocks'))
        Trial = selector(Trial,...
            swap({ones(1,length(Trial));...
            Index(I).EqualizeTask;...
            Index(I).EqualizeCue;...
            Index(I).BalanceTask;...
            Index(I).BalanceCue},...
            find([any(strcmp(varargin,'EqualizeTask')) ...
            any(strcmp(varargin,'EqualizeCue')) ...
            any(strcmp(varargin,'BalanceTask')) ...
            any(strcmp(varargin,'BalanceCue'))])+1)',...
            'NoReset','HasFrames','Nignore');
        if any(strcmp(varargin,'Inner'))
            Trial = selector(Trial,'Inner');
        end
        
    elseif any(strcmp(varargin,'NotExperiments'))
        Trial = selector(Trial,'NoReset','HasFrames','Nignore','Post');
    else
        Trial = Trial(Index(I).Combobulation);
    end
    
    Trials{I} = Trial;
    try
        DFFs{I} = DFF;
    catch
        DFFs{I} = nan;
    end
    
    if or(any(strcmp(varargin,'EquateTask')),any(strcmp(varargin,'Equate')))
        TempLabels = destruct(Trials{I},'Task');
        [A,B] = min([sum(TempLabels==1) sum(TempLabels==2)]);
        TempReplace = cat(1,repmat((3-B),[A 1]), nan(sum(TempLabels==(3-B))-A,1));
        TempLabels(TempLabels==(3-B)) = TempReplace(randperm(length(TempReplace)));
        Trials{I}(isnan(TempLabels)) = [];
    end
    
    %% Focus (for cleaning bullshit for projections)
    if any(strcmp(varargin,'Focus'))
        Trials(I) = selector(Trials(I),'HasFrames');
        Frames = [];
        for III = 1:length(Trials{I})
            Frames = cat(1,Frames,[Trials{I}(III).Trigger.Delay.Frame:Trials{I}(III).Trigger.Post.Frame]');
        end
        Focus = false(size(DFFs{I},2),1);
        Focus(Frames(~isnan(Frames))) = true;
        DFFs{I}(:,~Focus) = nan;
    end
    if any(strcmp(varargin,'DelayFocus'))
        Trials(I) = selector(Trials(I),'HasFrames');
        Frames = [];
        for III = 1:length(Trials{I})
            Frames = cat(1,Frames,[Trials{I}(III).Trigger.Delay.Frame:Trials{I}(III).Trigger.Stimulus.Frame]');
        end
        Focus = false(size(DFFs{I},2),1);
        Focus(Frames(~isnan(Frames))) = true;
        DFFs{I}(:,~Focus) = nan;
    end
end


% [~,Sort] = sort(cat(2,Ripped(:).Latency));


