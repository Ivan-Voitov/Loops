function [Labels] = get_labels(Trials,CCD,Stim,DCD,Shuffle,OnlyCorrect,OnlyPostProbe,OnlyPostCue,Shift,History)

if ~iscell(Trials)
    Trials = {Trials};
end

for S = 1:length(Trials)
    Trial = Trials{S};
    if CCD && ~Stim
        Labels = double(destruct(Trial,'Block') + 1);
        % always not post target % kinda not needed if context rip
        Labels(~isnan(destruct(Trial,'Post.Target'))) = nan;
    elseif Stim && CCD
        Labels = double(destruct(Trial,'Stimulus') == 13);
        Labels(destruct(Trial,'Stimulus') == 17) = 2;
        Labels(Labels == 0) = nan;
    elseif DCD
        Labels = ((sign(destruct(Trial,'DB')) .* 0.5) + 1.5);
    else % is TCD
        Labels = 3 - destruct(Trial,'Task');
    end
    
    % overwrite it fuck it
    if History
        Labels = destruct(Trial,'Post.Cue')>4;
        try
            Labels(isnan(destruct(Trial,'Post.Cue'))) = ...
                destruct(Trial(isnan(destruct(Trial,'Post.Cue'))),'Post.Distractor')>4;
        end
        Labels = double(Labels) +1;
    end
    
    if Shuffle
        Labels = Labels(randperm(length(Labels)));
    end
    if Shift
        Labels = shift_labels(Labels);
        %         Labels = circshift(Labels,12); DO SOME SHIFT LABEL THING
    end
    
    if OnlyCorrect % part 1. need to enscore these trials later
        Labels(or(destruct(Trial,'ResponseType')==2,destruct(Trial,'ResponseType')==3)) = nan;
    end
    Labels(destruct(Trial,'Light')==1) = nan;
    
    if OnlyPostProbe
        Labels(isnan(destruct(Trial,'Post.Probe'))) = nan;
    end
    if OnlyPostCue %  kinda not needed if context rip
        Labels(and(isnan(destruct(Trial,'Post.Cue')),isnan(destruct(Trial,'Post.Distractor')))) = nan;
    end
    
    
    FullLabels{S} = Labels;
end

if S > 1
    Labels = FullLabels;
end