function [Rate, CI, ControlSig, TaskSig] = performance(TrialCells,Mode,varargin)
OptoDelta = false;
for I=1:2:numel(varargin)
    eval([varargin{I} '= varargin{I+1};']);
end

%% hard code some selections for opto only
if ~iscell(TrialCells)
    Trial = TrialCells; TrialCells = cell(8,1); [TrialCells{:}] = deal(Trial(1));
    Set = destruct(Trial,'Set');
    for K = 1:8
        Flag = false; % for removing first trialscells trial
        for I = 1:length(Trial)
            if Trial(I).Light == (K-2) || and(and(K == 1, or(Set(I) == 2, Set(I) == 5)),Trial(I).Light == 0)
                TrialCells{K}(end+Flag) = Trial(I);
                Flag = true;
            end
        end
    end
end

%% Organize [Trial]'s [Features]
Features = cell(length(TrialCells),1); % then has cells of trial type (C/P/T/All)  * task * condition
Numbers = cell(length(TrialCells),1); % for each trial i have 1 number!!!

for K = 1:length(TrialCells)
    Task = 3 - destruct(TrialCells{K},'Task');
    Type = destruct(TrialCells{K},'Type');
    for Ty = 1:4
        for Ta = 1:2
            if Ty == 4
                Features{K}{Ta,Ty}(:) = (Ta==Task);
            else
                Features{K}{Ta,Ty}(:) = and(Ta==Task,Ty==Type);
            end
        end
    end
    
    if strcmp(Mode,'DelayLength')
        Numbers{K} = destruct(TrialCells{K},'Trigger.Stimulus.Time');
    elseif strcmp(Mode,'BlockLocation')
        Numbers{K} = destruct(TrialCells{K},'BlockLocation');
    elseif strcmp(Mode,'RxnTime')
        Numbers{K} = destruct(TrialCells{K},'ResponseTime') - destruct(TrialCells{K},'Trigger.Stimulus.Time');
    elseif strcmp(Mode,'DelaySpeed')
        Numbers{K} = destruct(TrialCells{K},'DelaySpeed');
    elseif strcmp(Mode,'Responses')
        Numbers{K} = destruct(TrialCells{K},'StimulusResponse');
        Numbers{K}(isnan(Numbers{K})) = false;
    end
end

%% Calculate [Mean and CI] from Numbers and Features
for K = 1:length(TrialCells)% 13 % for each light condition
    for Task = 1:2 % for each task
        for Type = 1:4
            if any(strcmp(Mode,'Responses'))
                [Rate{K}(Task,Type), CI{K}(Task,Type,:)] = binofit(nansum(Numbers{K}(Features{K}{Task,Type})),nansum(Features{K}{Task,Type}));
                CI{K}(Task,Type,:)= CI{K}(Task,Type,:) - Rate{K}(Task,Type);
                Rate{K}(Task,Type) =   Rate{K}(Task,Type).*100;
                CI{K}(Task,Type,:) =   CI{K}(Task,Type,:).*100;
%                 CI(Task,K,:) = ([Rate(Task,K)-X(1) X(2)-Rate(Task,K)]);
            end
        end
    end
end


%             if strcmp(Mode,'FA')
%                 [Rate(Task,K), X] = binofit(nansum(Numbers(Features{Type,K,Task})),nansum(~isnan(Numbers(Features{Type,K,Task}))));
%                 CI(Task,K,:) = ([Rate(Task,K)-X(1) X(2)-Rate(Task,K)]);
%             elseif strcmp(Mode,'ProbeFA')
%                 [Rate(Task,K), X] = binofit(nansum(Numbers(Features{Type,K,Task})),nansum(Features{Type,K,Task}));
%                 CI(Task,K,:) = ([Rate(Task,K)-X(1) X(2)-Rate(Task,K)]);
%             elseif strcmp(Mode,'Miss')
%                 [Rate(Task,K), X] = binofit(nansum(Numbers(Features{Type,K,Task})),nansum(Features{Type,K,Task}));
%                 Rate(Task,K) = 1-Rate(Task,K);
%                 X = 1-X;
%                 % need to flip?
%                 CI(Task,K,:) = ([Rate(Task,K)-X(1) X(2)-Rate(Task,K)]);
%             else
%                 Flag = true;
%                 if strcmp(Mode,'Performance')
%                     [FARate, ~] = binofit(nansum(Numbers(Features{1,K,Task})),nansum(Features{1,K,Task}));
%                     [HitRate, ~] = binofit(nansum(Numbers(Features{3,K,Task})),nansum(Features{3,K,Task}));
%                     Rate(Task,K) = (FARate + (1-HitRate)) * 100;
%                     CI(Task,K,1:2) = nan;
%                 elseif strcmp(Mode,'DelayLength')
%                     Rate(Task,K) = nanmean(Numbers(Features{Type,K,Task}));
%                 elseif strcmp(Mode,'BlockLocation')
%                     Rate(Task,K) = nanmean(Numbers(Features{Type,K,Task}));
%                 elseif strcmp(Mode,'HitRxnTime')
%                     Rate(Task,K) = nanmean(Numbers(Features{Type,K,Task}));
%                     PDF = fitdist(Numbers(Features{Type,K,Task}),'normal');
%                     PDFCI = paramci(PDF);
%                     CI(Task,K) = Rate(K,Task)-PDFCI(1,1);
%                 elseif strcmp(Mode,'FARxnTime')
%                     Rate(Task,K) = nanmean(Numbers(Features{Type,K,Task}));
%                     PDF = fitdist(Numbers(Features{Type,K,Task}),'normal');
%                     PDFCI = paramci(PDF);
%                     CI(Task,K) = Rate(K,Task)-PDFCI(1,1);
%                 elseif strcmp(Mode,'DelaySpeed')
%                     Rate(Task,K) = nanmean(Numbers(Features{Type,K,Task}));
%                 end
%             end
%         end
%     end
% end
% 

%% deltas
if OptoDelta
    for Task = 1:2
        for Type = 1:4
            for K = 3:5
                Rate{K}(Task,Type) = -(Rate{2}(Task,Type) - Rate{K}(Task,Type));
%                 CI{K}(Task,Type,1) = -(Rate{2}(Task,Type) - CI{K}(Task,Type,1));
%                 CI{K}(Task,Type,2) = -(Rate{2}(Task,Type) - CI{K}(Task,Type,2));
            end
            for K = 6:8
                Rate{K}(Task,Type) = -(Rate{1}(Task,Type) - Rate{K}(Task,Type));
%                 CI{K}(Task,Type,1) = -(Rate{1}(Task,Type) - CI{K}(Task,Type,1));
%                 CI{K}(Task,Type,2) = -(Rate{1}(Task,Type) - CI{K}(Task,Type,2));
            end
        end
    end
end

%% sig different from 1
try
    for Task = 1:2
        for Type = 1:4
            if OptoDelta
                for K = 3:5
                    A = sum(Numbers{2}(Features{2}{Task,Type}));
                    B = sum(Numbers{2}(Features{2}{Task,Type})==0);
                    C = sum(Numbers{K}(Features{K}{Task,Type}));
                    D = sum(Numbers{K}(Features{K}{Task,Type})==0);
                    [~,ControlSig{K}(Task,Type)] = fishertest([A B;C D]);
%                     ControlSig{K}(Task,Type) = ranksum(Numbers{2}(Features{2}{Task,Type}),Numbers{K}(Features{K}{Task,Type}));
                end
                for K = 6:8
                    A = sum(Numbers{1}(Features{1}{Task,Type}));
                    B = sum(Numbers{1}(Features{1}{Task,Type})==0);
                    C = sum(Numbers{K}(Features{K}{Task,Type}));
                    D = sum(Numbers{K}(Features{K}{Task,Type})==0);
                    [~,ControlSig{K}(Task,Type)] = fishertest([A B;C D]);
%                     ControlSig{K}(Task,Type) = ranksum(Numbers{1}(Features{1}{Task,Type}),Numbers{K}(Features{K}{Task,Type}));
                end
            else
                for K = 1:length(TrialCells)
                    A = sum(Numbers{2}(Features{1}{Task,Type}));
                    B = sum(Numbers{2}(Features{1}{Task,Type})==0);
                    C = sum(Numbers{K}(Features{K}{Task,Type}));
                    D = sum(Numbers{K}(Features{K}{Task,Type})==0);
                    [~,ControlSig{K}(Task,Type)] = fishertest([A B;C D]);
%                     ControlSig{K}(Task,Type) = ranksum(Numbers{1}(Features{1}{Task,Type}),Numbers{K}(Features{K}{Task,Type}));
                end
            end
        end
    end
    
    %% sig diff in task
    for Type = 1:4
        for K = 1:length(TrialCells)
%             TaskSig{K}(Type) = ranksum(Numbers{K}(Features{K}{1,Type}),Numbers{K}(Features{K}{2,Type}));
            A = sum(Numbers{K}(Features{K}{1,Type}));
            B = sum(Numbers{K}(Features{K}{1,Type})==0);
            C = sum(Numbers{K}(Features{K}{2,Type}));
            D = sum(Numbers{K}(Features{K}{2,Type})==0);
            [~,TaskSig{K}(Type)] = fishertest([A B;C D]);
        end
    end
catch
    ControlSig = [nan];
    TaskSig = [nan];
end
