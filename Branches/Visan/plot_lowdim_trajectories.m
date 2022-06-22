function [Projections,Explanations,MI,Sig] = plot_lowdim_trajectories(Index,varargin)
Smooth = [];
MeanSubtract = false;

Space = 'PCA';
Plot = true;
Statistics = true;
Folds = 1;
Dimensions = 3;
Simultaneous = true;

% rip
Triggerable = false;
Focus = true;
S = true;
Equate= false;
Normalize= false;
EquatePass = [];

% new
CCD = false;

SessionBased = true;

%% PASS ARGUMENTS TO CONTROLS
for I=1:2:numel(varargin)
    eval([varargin{I} '= varargin{I+1};']);
end

if S
    S = 'S';
end
if Triggerable
    Triggerable = 'Triggerable';
end
if Focus
    Focus = 'Focus';
end

if ~CCD
    [DFFs,Trials] = rip(Index,S,'Hyper','DeNaN','Active',Focus,Triggerable,EquatePass,'DeNaN');
else
    [DFFs,Trials] = rip(Index,S,'Context','DeNaN','Active',Focus,Triggerable,EquatePass,'DeNaN');
end

Colours;

%% modify the data
for Session = 1:length(Index)
    % modify the data
    if ~isempty(Smooth)
        for Cell = 1:size(DFFs{Session},1)
            DFFs{Session}(Cell,:) = gaussfilt(1:length(DFFs{Session}(Cell,:)),DFFs{Session}(Cell,:),Smooth);
        end
    end
    if MeanSubtract
        DFFs{Session} = DFFs{Session} - nanmean(DFFs{Session},2);
    end
end

%% get projection
% reorients the data into a different lower dimensional 'basis'
% AND takes out triggered and cross-combined stuff (i.e., 1 per trial)
% and adds a variance explained output
% !!! works for faux sim and not faux stim
if ~Simultaneous
    for Session = 1:length(Index)
        [Projections{Session},Explanations{Session}] = projectorize(DFFs{Session},Trials{Session},...
            Space,'Simultaneous',false,'Folds',Folds,'Dimensions',Dimensions,'CCD',CCD);
    end
else
    [Projections,Explanations] = projectorize(DFFs,Trials,...
        Space,'Simultaneous',true,'Folds',Folds,'Dimensions',Dimensions,'Equate',Equate,'CCD',CCD);
end

if Normalize
    for S = 1:length(Projections)
        for Dim = 1:2
            Projections{S}(Dim,:,:) = ((squeeze(Projections{S}(Dim,:,:))) - nanmean(squeeze(Projections{S}(Dim,:,:)),2)) ./ nanstd(squeeze(Projections{S}(Dim,:,:)),[],2);
        end
    end
end

%% plot for all trajectories, and average across sessions?
if Plot
    if Simultaneous
        trajectorize(Projections,Trials,'Average',true,'Explanations',Explanations,'Dim',Dimensions,...
            'CCD',CCD);
    else
        trajectorize(Projections,Trials,'Average',false,'Explanations',Explanations,'Dim',Dimensions,...
            'CCD',CCD);
    end
end

%% get statistic
if Statistics
    rng(10)
    for Session = 1:length(Index)
        Onsets = destruct(Trials{Session},'Trigger.Stimulus.Frame') - destruct(Trials{Session},'Trigger.Delay.Frame');
        TempAvg = Projections{Session};
        for III = 1:size(TempAvg,3)
            TempAvg(:,frame(3200)+1:frame(5200),III) = TempAvg(:,Onsets(III)+1:Onsets(III)+frame(2000),III);
            TempAvg(:,Onsets(III)+1:frame(3200),III) = nan;
        end
        TempAvg(:,frame(5200)+1:end,:) = [];
        
        % discrimination of task over time
        if ~CCD
            Labels = 3 - destruct(Trials{Session},'Task');
        else
            Labels = destruct(Trials{Session},'Block') + 1;
        end
        if Equate
            TempLabels = Labels;
            [A,B] = min([sum(TempLabels==1) sum(TempLabels==2)]);
            TempReplace = cat(1,repmat((3-B),[A 1]), nan(sum(TempLabels==(3-B))-A,1));
            TempLabels(TempLabels==(3-B)) = TempReplace(randperm(length(TempReplace)));
            Labels = TempLabels;
        end
        
        % remove temp avg which is not in labels and remove labels nans
        TempAvg(:,:,isnan(Labels)) = [];
        Labels(isnan(Labels)) = [];
        
        for Dim = 1:size(TempAvg,1)
            
            for II = 1:size(TempAvg,2)
                Statistic{Session,1,1}(:,Dim,II) = squeeze(TempAvg(Dim,II,Labels==1));
                Statistic{Session,2,1}(:,Dim,II) = squeeze(TempAvg(Dim,II,Labels==2));
                if Simultaneous
                    if SessionBased
                        TempLabels = shift_labels(Labels,'Halfway');
                        Statistic{Session,1,2}(:,Dim,II) = squeeze(TempAvg(Dim,II,TempLabels==1));
                        Statistic{Session,2,2}(:,Dim,II) = squeeze(TempAvg(Dim,II,TempLabels==2));
                    else
                        for Shuff = 1:100 % number of times to shuffle
                            % control for drift
                            % shift (slow temporal factors control)
                            Labels = shift_labels(Labels,'Random');
                            Statistic{Session,1,Shuff+1}(:,Dim,II) = squeeze(TempAvg(Dim,II,Labels==1));
                            Statistic{Session,2,Shuff+1}(:,Dim,II) = squeeze(TempAvg(Dim,II,Labels==2));
                        end
                    end
                end
            end
        end
    end


    decode_over_time(Statistic,3+SessionBased);

end

