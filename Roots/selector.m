% function which generates complicated selected ID
% if input is a field process as name-argument pair
% if a string then it is hard-coded
%
% Hard-coded selections:
% Ran
%     Didn't drop below 5 cm/s during Delay
% DelayDuration
%     [min max]
%     'Short','Medium','Long','Normal'
% StimulusDuration
%     [min max]
%     'Short','Medium','Long','Normal'
% TaskType
%     'Discrimination','Memory'
% PostCues / PostDistractors
%     [numbers of preceding]
% WithFrames
%     max frame number must be given
% HasFrmes
%     not bullshit
% Ignore
%     [trials to ignore]

function [Out, Sel] = selector(TrialInput,varargin)
% fixes TrialInput being a bunch or not
if iscell(TrialInput)
    Trials = TrialInput;
else
    Trials{1} = TrialInput;
end

for T = 1:length(Trials)
    Trial = Trials{T};
    Sel = true(length(Trial),1);
    
    %% BASIC 
    if ~ischar(varargin{1}) && ~iscell(varargin{1})
        Sel = varargin{1};
    end
    %% select hard-coded
    % rotaty stuff
    if any(strcmp(varargin,'Normal'))
        Sel = and(Sel,destruct(Trial,'Contrast')~=0);
    end
    
    %     if any(strcmp(varargin,'Hyper'))
    %         Normal = destruct(Trial,'Contrast') ~= 0;
    %         Hyper = and(destruct(Trial,'Type') == 1,...
    %             or(~isnan(destruct(Trial,'Post.Cue')), ~isnan(destruct(Trial,'Post.Distractor'))));
    %         Sel = and(Sel,and(Normal, Hyper));
    %     end
    
    if any(strcmp(varargin,'Neg'))
        Sel = and(Sel,and(destruct(Trial,'Contrast') < 3,destruct(Trial,'Contrast') ~=0));
    end
    if any(strcmp(varargin,'Pos'))
        Sel = and(Sel,destruct(Trial,'Contrast')  >2);
    end
    if any(strcmp(varargin,'EitherDB'))
        Sel = and(Sel,destruct(Trial,'DB')  ~=0);
    end
    % imaging stuff
    if any(strcmp(varargin,'HasFrames'))
        HasFrames = false(length(Trial),1);
        for I = 1:length(Trial)
            if Trial(I).Trigger.Delay.Frame > 1
                HasFrames(I) = true;
            end
            if I > 1
                if Trial(I-1).Trigger.Post.Frame == Trial(I).Trigger.Stimulus.Frame
                    HasFrames(I-1:I) = false;
                end
            end
            if ~isfield(Trial(I).Trigger.Delay,'Frame')
               HasFrames = true; 
            end
        end
        Sel = and(Sel,HasFrames);
    end
    % behaviour stuff
    for I = 1:length(Trial)
        if any(strcmp(varargin,'A'))
            if Trial(I).Block == 1
                Sel(I) = false;
            end
        end
        if any(strcmp(varargin,'B'))
            if Trial(I).Block == 0
                Sel(I) = false;
            end
        end
        if any(strcmp(varargin,'NoReset'))
%             try
                if Trial(I).Reset || ~isnan(Trial(I).DelayResponse) || Trial(I).Trigger.Stimulus.Time > 4067
                    Sel(I) = false;
                end
%             catch
%                 if Trial(I).Slow || ~isnan(Trial(I).DelayResponse) || Trial(I).Trigger.Stimulus.Time > 4067
%                     Sel(I) = false;
%                 end
%             end
        end
              
        if any(strcmp(varargin,'NoEarlyLick'))
            if ~isnan(Trial(I).DelayResponse)
                Sel(I) = false;
            end
        end
        if any(strcmp(varargin,'Ran'))
            if ~Trial(I).Ran
                Sel(I) = false;
            end
        end
        if any(strcmp(varargin,'Cue'))
            if Trial(I).Type ~= 1
                Sel(I) = false;
            end
        end
        if any(strcmp(varargin,'Probe'))
            if Trial(I).Type ~= 2
                Sel(I) = false;
            end
        end
        if any(strcmp(varargin,'Target'))
            if Trial(I).Type ~= 3
                Sel(I) = false;
            end
        end
        if any(strcmp(varargin,'FAd'))
            if ~Trial(I).FAd
                Sel(I) = false;
            end
        end
        if any(strcmp(varargin,'Short'))
            if Trial(I).Trigger.Stimulus.Time > prctile(destruct(Trial,...
                    'Trigger.Stimulus.Time'),33)
                Sel(I) = false;
            end
        end
        if any(strcmp(varargin,'Medium'))
            if Trial(I).Trigger.Stimulus.Time < prctile(destruct(Trial,...
                    'Trigger.Stimulus.Time'),34) || Trial(I).Trigger.Stimulus.Time...
                    > prctile(destruct(Trial,'Trigger.Stimulus.Time'),66)
                Sel(I) = false;
            end
        end
        if any(strcmp(varargin,'Long'))
            if Trial(I).Trigger.Stimulus.Time < prctile(destruct(Trial,...
                    'Trigger.Stimulus.Time'),67)
                Sel(I) = false;
            end
        end
        if any(strcmp(varargin,'FirstHalf'))
            if Trial(I).Trigger.Stimulus.Time >= 1400
                Sel(I) = false;
            end
        end
        if any(strcmp(varargin,'SecondHalf'))
            if Trial(I).Trigger.Stimulus.Time < 1400
                Sel(I) = false;
            end
        end
        if any(strcmp(varargin,'NotFAd'))
            if Trial(I).FAd
                Sel(I) = false;
            end
        end
        if any(strcmp(varargin,'Limit'))
            if Trial(I).Trigger.Stimulus.Time > 3200
               Sel(I) = false; 
            end
        end
        
        if any(strcmp(varargin,'Nignore'))
            if isfield(Trial,'Ignore')
                if Trial(I).Ignore
                    Sel(I) = false;
                end
            end
            if Trial(I).Trigger.Stimulus.Time > 4100
               Sel(I) = false; 
            end
        end
        
        if any(strcmp(varargin,'Post'))
            if ~(isnan(Trial(I).Post.Probe) && isnan(Trial(I).Post.Target))
                Sel(I) = false;
            end
        end
        if any(strcmp(varargin,'PostProbe'))
            if isnan(Trial(I).Post.Probe)
                Sel(I) = false;
            end
        end
      
        %opto stuff
        if any(strcmp(varargin,'NoLight'))
            if ~(Trial(I).Light == 0)
                Sel(I) = false;
            end
        end
        if any(strcmp(varargin,'NoMaskOn2'))
            if (Trial(I).MaskOn ==2)
                Sel(I) = false;
            end
        end
        if any(strcmp(varargin,'NoMask'))
            if ~(Trial(I).MaskOn ==0)
                Sel(I) = false;
            end
        end
        if any(strcmp(varargin,'NoNoMask'))
            if (Trial(I).MaskOn ==0)
                Sel(I) = false;
            end
        end
        if any(strcmp(varargin,'Light'))
            if ~(Trial(I).Light >= 1)
                Sel(I) = false;
            end
        end
        
        if or(any(strcmp(varargin,'Comb')),any(strcmp(varargin,'NotS1')))
            if ~(or(Trial(I).Light == 0,Trial(I).Light ~= 3))
                Sel(I) = false;
            end
        end
        
        if any(strcmp(varargin,'Posterior'))
            if ~(or(Trial(I).Light == 0,or(Trial(I).Light == 1,or(Trial(I).Light ==4,Trial(I).Light == 5))))
                Sel(I) = false;
            end
        end
        
        if any(strcmp(varargin,'Anterior'))
            if ~(or(Trial(I).Light == 0,or(Trial(I).Light == 2,Trial(I).Light == 6)))
                Sel(I) = false;
            end
        end
        if any(strcmp(varargin,'Visual'))
            if ~(or(Trial(I).Light == 0,or(Trial(I).Light == 1,Trial(I).Light == 4)))
                Sel(I) = false;
            end
        end
        if any(strcmp(varargin,'NonVisual'))
            if ~(or(Trial(I).Light == 0,or(Trial(I).Light == 2,or(Trial(I).Light ==6,Trial(I).Light == 5))))
                Sel(I) = false;
            end
        end
        if any(strcmp(varargin,'AM'))
            if ~(or(Trial(I).Light == 0,Trial(I).Light == 1))
                Sel(I) = false;
            end
        end
        
        if any(strcmp(varargin,'M2'))
            if ~(or(Trial(I).Light == 0,Trial(I).Light == 2))
                Sel(I) = false;
            end
        end
        if any(strcmp(varargin,'bM2'))
            if ~(or(Trial(I).Light == 0,or(Trial(I).Light == 6,Trial(I).Light == 2)))
                Sel(I) = false;
            end
        end
        if any(strcmp(varargin,'S1'))
            if ~(or(Trial(I).Light == 0,Trial(I).Light == 3))
                Sel(I) = false;
            end
        end
        
        if any(strcmp(varargin,'V1'))
            if ~(or(Trial(I).Light == 0,Trial(I).Light == 4))
                Sel(I) = false;
            end
        end
        
        if any(strcmp(varargin,'iAM'))
            if ~(or(Trial(I).Light == 0,Trial(I).Light == 5))
                Sel(I) = false;
            end
        end
        
        if any(strcmp(varargin,'iM2'))
            if ~(or(Trial(I).Light == 0,Trial(I).Light == 6))
                Sel(I) = false;
            end
        end
        
        if any(strcmp(varargin,'EarlyDelayOnset'))
            if ~(or(Trial(I).Light == 0,Trial(I).LightOn == 1))
                Sel(I) = false;
            end
        end
        if any(strcmp(varargin,'LateDelayOnset'))
            if ~(or(Trial(I).Light == 0,Trial(I).LightOn == 2))
                Sel(I) = false;
            end
        end
        if any(strcmp(varargin,'NotLateDelayOnset'))
            if (Trial(I).LightOn == 2)
                Sel(I) = false;
            end
        end
        if any(strcmp(varargin,'StimulusOnset'))
            if ~(or(Trial(I).Light == 0,Trial(I).LightOn == 3))
                Sel(I) = false;
            end
        end
        if any(strcmp(varargin,'Memory'))
            if ~(Trial(I).Task == 1)
                Sel(I) = false;
            end
        end
        if any(strcmp(varargin,'Discrimination'))
            if ~(Trial(I).Task == 2)
                Sel(I) = false;
            end
        end
        if any(strcmp(varargin,'CueA'))
            if ~(Trial(I).Block == 0)
                Sel(I) = false;
            end
        end
        if any(strcmp(varargin,'CueB'))
            if ~(Trial(I).Block == 1)
                Sel(I) = false;
            end
        end
        if any(strcmp(varargin,'Minus'))
            if ~(Trial(I).DB == -15)
                Sel(I) = false;
            end
        end
        if any(strcmp(varargin,'Plus'))
            if ~(Trial(I).DB == 15)
                Sel(I) = false;
            end
        end
    end
    
    %% Select
    if ~iscell(TrialInput)
        if iscell(varargin{1}) % selecting data
            Out = cat(2,{Trial(Sel)},{varargin{1}(Sel)});
        else
            Out = Trial(Sel);
        end
    else
        if iscell(varargin{1}) % selecting data
            if T == 1
                Out{1} = {Trial(Sel)};
                Out{2} = {varargin{1}{T}(Sel)};
            else
                Out{1} = cat(1,Out{1},{Trial(Sel)});
                Out{2} = cat(1,Out{2},{varargin{1}{T}(Sel)});
            end
        else
            Out{T} = Trial(Sel);
        end
    end
end


%% old stuff
% %% process the input
% for I = 1:numel(varargin)
%     if ~ischar(varargin{I})
% %     FieldNames = strsplit(varargin{I},'.');
% %     TempTrial = Trial(1);
% %     for II = 1:length(FieldNames)-1 % get down to nested field
% %         TempTrial = TempTrial.(FieldNames{II});
% %     end
% %     if isfield(TempTrial,(FieldNames(end))) % if field name exists
% %     end
%
% %     %% select right away varargin if they are fields
% %     FieldNames = strsplit(varargin{I},'.');
% %     TempTrial = Trial(1);
% %     for II = 1:length(FieldNames)-1 % get down to nested field
% %         TempTrial = TempTrial.(FieldNames{II});
% %     end
% %     if isfield(TempTrial,(FieldNames(end))) % if field name exists
% %         if ~isnan(varargin{I+1})
% %             if ~ischar(varargin{I+1})
% %                 for J = 1:numel(varargin{I+1})
% %                     TempSelect{J} = and(Select,destruct(Trial,varargin{I})==varargin{I+1}(J));  % all trials without that value remove
% %                 end
% %                 Select = any(cat(2,TempSelect{:}),2);
% %             else
% %                 Select = and(Select,eval(strcat('destruct(Trial,varargin{I})',varargin{I+1})));
% %             end
% %         else
% %             Select = and(Select,isnan(destruct(Trial,varargin{I})));  % all trials without that value remove
% %         end
% %     else
% %         % otherwise define a hard-coded selector
% %         eval([varargin{I} '= varargin{I+1};']);
% % %     end
% % end
%     end
% end


% % if exist('WithFrames','var')

% if any(strcmp(varargin,'WithFrames'))
%     for II = 1:length(Trial)
%         if Trial(II).Trigger.Delay.Frame == 0
%             Select(II) = false;
%         end
%         if Trial(II).Trigger.Stimulus.Frame > WithFrames
%             Select(II) = false;
%             Select(II-1) = false;
%         end
%     end
% end
%
% if exist('Controlled','var')
%     if strcmp(Controlled,'Post') || strcmp(Controlled,'Both')
%         for I = 1:length(Trial)
%             if ~(Trial(I).Stimulus == 234 || Trial(I).Stimulus  == 236)
%                 Select(I) = false;
%             end
%         end
%     end
%     if strcmp(Controlled,'Pre') || strcmp(Controlled,'Both')
%         for I = 2:length(Trial)
%             if ~(Trial(I-1).Stimulus == 234 || Trial(I-1).Stimulus  == 236)
%                 Select(I) = false;
%             end
%         end
%     end
% end
% if exist('Slow','var')
%    Select = and(Select,~destruct(Trial,'Slow'));
% end
% if exist('DelayDuration','var')
%     if ischar(DelayDuration)
%         Tiles = [0 33 67];
%         for L = 1:length(Tiles)
%             ThirdTime{L} = [prctile(destruct(Trial(Select),'Trigger.Stimulus.Time'),Tiles(L)) prctile(destruct(Trial(Select),'Trigger.Stimulus.Time'),Tiles(L)+33)];
%         end
%
%         if strcmp(DelayDuration,'Short')
%             DelayDuration = ThirdTime(1);
%         elseif strcmp(DelayDuration,'Medium')
%             DelayDuration = ThirdTime(2);
%         elseif strcmp(DelayDuration,'Long')
%             DelayDuration = ThirdTime(3);
%         elseif strcmp(DelayDuration,'Normal')
%             DelayDuration = [0 prctile(destruct(Trial(Select),'Trigger.Stimulus.Time'),90)];
%         end
%     end
%     % use the DelayDuration values
%     Select = and(Select,(destruct(Trial,'Trigger.Stimulus.Time')>DelayDuration(1)));
%     Select = and(Select,(destruct(Trial,'Trigger.Stimulus.Time')<DelayDuration(2)));
% end
% if exist('StimulusDuration','var')
%     if isstring(StimulusDuration)
%         Tiles = [0 33 67];
%         for L = 1:length(Tiles)
%             ThirdTime{L} = [prctile(destruct(Trial(Select),'Trigger.Post.Time'),Tiles(L)) prctile(destruct(Trial(Select),'Trigger.Post.Time'),Tiles(L)+33)];
%         end
%
%         if strcmp(StimulusDuration,'Short')
%             StimulusDuration = ThirdTime(1);
%         elseif strcmp(StimulusDuration,'Medium')
%             StimulusDuration = ThirdTime(2);
%         elseif strcmp(StimulusDuration,'Long')
%             StimulusDuration = ThirdTime(3);
%         elseif strcmp(StimulusDuration,'Normal')
%             StimulusDuration = [0 prctile(destruct(Trial(Select),'Trigger.Post.Time'),98)];
%         end
%     end
%     % use the DelayDuration values
%     Select = and(Select,(destruct(Trial,'Trigger.Post.Time')>StimulusDuration(1)));
%     Select = and(Select,(destruct(Trial,'Trigger.Post.Time')<StimulusDuration(2)));
% end
% if exist('PostDistractors','var')
%     for I = 1:length(PostDistractors)
%         Select = and(Select,destruct(Trial,'Post.Distractor')==PostDistractors(I));
%     end
% end
% if exist('PostCues','var')
%     for I = 1:length(PostCues)
%         Select = and(Select,destruct(Trial,'Post.Cue')==PostCues(I));
%     end
% end
%
% if exist('TaskType','var')
%     if strcmp(TaskType , 'Perceptual')
%         Select = and(Select,rem(destruct(Trial,'Task'),2));
%     elseif strcmp(TaskType , 'Memory')
%         Select = and(Select,~rem(destruct(Trial,'Task'),2));
%
%     elseif strcmp(TaskType , 'Shuffle')
%         if ~exist('NumTrials','var')
%         NumTrials = ceil((sum(rem(destruct(Trial,'Task'),2)) + sum((1-rem(destruct(Trial,'Task'),2))))/2);
%         end
%
%         SelectFrom = find(Select);
%         SelectFrom = SelectFrom(randperm(length(SelectFrom)));
%         TempSelect = false(length(Select),1);
%         TempSelect(SelectFrom(1:NumTrials)) = true;
%         Select = and(Select,TempSelect);
%     end
% end