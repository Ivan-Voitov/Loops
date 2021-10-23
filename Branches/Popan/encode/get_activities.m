function [Activities,TrigOn,TrigOff] = get_activities(DFFs,Trials,Range,LabelFocus,Smooth,PCsCat,Threshold,Ripped,FPS,Stim,Minus,ZScore,Iterate,Five,DePre,PCsRaw,PCsExclude,Lag)

if ~iscell(DFFs)
    Trials = {Trials};
    DFFs = {DFFs};
end

for S = 1:length(DFFs)
    Trial = Trials{S};
    DFF = DFFs{S};
    if ~Stim
        TrigOn = destruct(Trial,'Trigger.Delay.Frame');
        TrigOff = destruct(Trial,'Trigger.Stimulus.Frame');
    elseif Stim
        TrigOn = destruct(Trial,'Trigger.Stimulus.Frame');
        TrigOff = destruct(Trial,'Trigger.Post.Frame');
    end
    
    if Minus
        TrigOn = TrigOff - Range(2);
    end
    
    if LabelFocus
        Frames = [];
        for III = 1:length(TrigOn)
            Frames = cat(1,Frames,[TrigOn(III):TrigOff(III)]');
        end
        LabelFocus = false(size(DFF,2),1);
        LabelFocus(Frames(~isnan(Frames))) = true;
        DFF(:,~LabelFocus) = nan;
    end
    
    if Smooth && isempty(PCsCat)
        for C = 1:size(DFF,1)
            %             NotNaN = ~isnan(DFFs{Session}(C,:));
            DFF(C,:)= gaussfilt(1:length(DFF(C,:)),DFF(C,:),1);
            %             DFFs{Session}(C,NotNaN)= gaussfilt(1:length(DFFs{Session}(C,NotNaN)),DFFs{Session}(C,NotNaN),1);
        end
    end
    
    if ZScore
        DFF = zscore(DFF',[],'omitnan')';
    end
    
    % ONLY DONE ONCE!!! -ish... need EnNaN for pc stuff
    Activities = wind_roi(DFF,{TrigOn;TrigOff},'Window',Range);
    if ~isempty(Threshold)
        [EnNaN] = threshold_values(Activities,Range,Iterate,Threshold,Five,DePre);
        % hack to make sure i get delay responsive things
        if FPS ~= 22.79
            try
                EnNaN(Ripped(Session).DelayResponsive) = false;
            end
        end
        Activities(EnNaN,:,:) = nan;
    end
    sweep_package_cat_catexclude;
    sweep_package_raw_exclude;
    
    if Lag
        Activities(:,abs(Range(1))+1:abs(Range(1))+1+frame(Lag,FPS),:) = nan;
    end
    
    FullActivities{S} = Activities;
end
if S > 1
    Activities = FullActivities;
end