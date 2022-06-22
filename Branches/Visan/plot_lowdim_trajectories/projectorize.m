function [Projection,Explanation] = projectorize(DFF,Trial,Space,varargin)
% kinda like avg_triggered
% reorients the data into a different lower dimensional 'basis'
% AND takes out triggered and cross-combined stuff (i.e., 1 per trial)
% and adds a variance explained output
% works for faux sim and not faux stim
Simultaneous = false;
Dimensions = 3;
Folds = 1;
SS = false;
Normalize = false;
Equate = false;
Smooth = 0;
CCD = false;

%% PASS CONTROL
for I=1:2:numel(varargin)
    eval([varargin{I} '= varargin{I+1};']);
end

rng(100)

if ~Simultaneous
    Projection = nan(Dimensions,frame(6000),length(Trial)); % 6000 is just longest i can get with 2000 stim and 4000 delay max
elseif and(Simultaneous,SS)
    Projection = nan(Dimensions,frame(6000),Folds); % 6000 is just longest i can get with 2000 stim and 4000 delay max
elseif Simultaneous
    Projection = cell(length(Trial),1);
    for C = 1:length(Projection)
        Projection{C} = nan(Dimensions,frame(6000),length(Trial{C}));
    end
end

for Cross = 1:Folds
    %% Crossed! Data
    if ~Simultaneous
        FocusOn = destruct(Trial(0+Cross:Folds:end),'Trigger.Delay.Frame');
        FocusOff = destruct(Trial(0+Cross:Folds:end),'Trigger.Stimulus.Frame') + frame(2000);
        Focused = false(size(DFF,2),1);
        for II = 1:length(FocusOn)
            if FocusOff(II) <= size(DFF,2)
                Focused(FocusOn(II):FocusOff(II)) = true;
            end
        end
        Data = DFF(:,Focused)';
        
    elseif Simultaneous
        Data = [];
        for Session = 1:length(Trial)
            TrigOn = destruct(Trial{Session}(0+Cross:Folds:end),'Trigger.Delay.Frame');
            TrigOff = destruct(Trial{Session}(0+Cross:Folds:end),'Trigger.Stimulus.Frame') + frame(2000);
            
            % cat delay and stim avg's
            TempActivity = wind_roi(DFF{Session},{TrigOn;TrigOff},'Window',[0 frame(6000)]);
            Onsets = ((TrigOff-frame(2000)) - TrigOn)+1;
            for III = 1:size(TempActivity,3)
                TempActivity(:,frame(4000)+1:end,III) = TempActivity(:,Onsets(III):Onsets(III)+frame(2000),III);
                TempActivity(:,Onsets(III):frame(4000),III) = nan;
            end
            if Equate
                if ~CCD
                    TempLabels = destruct(Trial{Session},'Task');
                else
                    TempLabels = destruct(Trial{Session},'Block')+1;
                end
               [A,B] = min([sum(TempLabels==1) sum(TempLabels==2)]);
               TempReplace = cat(1,repmat((3-B),[A 1]), nan(sum(TempLabels==(3-B))-A,1));
               TempLabels(TempLabels==(3-B)) = TempReplace(randperm(length(TempReplace)));
                TempActivity(:,:,isnan(TempLabels)) = nan;
            end
            Data = cat(1,Data,nanmean(TempActivity,3));
        end
        Data = Data';
        if Normalize
            for Cell = 1:size(Data,1)
                Data(Cell,:) = Data(Cell,:) ./ (max(Data(Cell,:)) - min(Data(Cell,:)));
            end
        end
        Data(frame(3400):frame(4000),:) = [];
    end
    
    %% project and get variance explained
    if strcmp(Space,'PCA')
        [Basis{Cross}, ~,~,~,TempExplanation{Cross}] = pca(Data,'numcomponents',Dimensions); % for this cross
    elseif strcmp(Space,'jPCA')
        
    else
        Basis{Cross} = ones(size(Data,2),Dimensions);
        TempExplanation{Cross} = zeros(size(Data,2),1);
    end
    
    %% use the other half of data to get wind_roi like traces per trial
    if ~Simultaneous
        TrigOn = destruct(Trial((Folds+1)-Cross:Folds:end),'Trigger.Delay.Frame');
        TrigOff = destruct(Trial((Folds+1)-Cross:Folds:end),'Trigger.Stimulus.Frame') + frame(2000);
        for D = 1:Dimensions
            Pr = [sum(Basis{Cross}(:,D) .* DFF)];
%             if Smooth
%                Pr = []
%             end
            Projection(D,:,(Folds+1)-Cross:Folds:end) = wind_roi(Pr,{TrigOn; TrigOff},'Window',[0 frame(6000)-1]);
        end
    elseif Simultaneous && ~SS
        Num = 0;
        for Session = 1:length(Trial)
            TrigOn = destruct(Trial{Session}((Folds+1)-Cross:Folds:end),'Trigger.Delay.Frame');
            TrigOff = destruct(Trial{Session}((Folds+1)-Cross:Folds:end),'Trigger.Stimulus.Frame') + frame(2000);
            TempBasis = Basis{Cross}(Num+1:Num+size(DFF{Session},1),:);
            for D = 1:Dimensions
                Pr = [sum(TempBasis(:,D) .* DFF{Session})];
                if Smooth
                    Pr = gaussfilt(1:length(Pr),Pr,Smooth);
                end
                Projection{Session}(D,:,(Folds+1)-Cross:Folds:end) = wind_roi(Pr,{TrigOn; TrigOff},'Window',[0 frame(6000)-1]);
            end
            Num = Num + size(DFF{Session},1);
        end
    elseif Simultaneous && SS
        Data = [];
        for Session = 1:length(Trial)
            TrigOn = destruct(Trial{Session}((Folds+1)-Cross:Folds:end),'Trigger.Delay.Frame');
            TrigOff = destruct(Trial{Session}((Folds+1)-Cross:Folds:end),'Trigger.Stimulus.Frame') + frame(2000);
            
            % cat delay and stim avg's
            TempActivity = wind_roi(DFF{Session},{TrigOn;TrigOff},'Window',[0 frame(6000)-1]);
            Onsets = ((TrigOff-frame(2000)) - TrigOn);
            for III = 1:size(TempActivity,3)
                TempActivity(:,frame(4000):end,III) = TempActivity(:,Onsets(III):Onsets(III)+frame(2000),III);
                TempActivity(:,Onsets(III):frame(4000),III) = nan;
            end
            Data = cat(1,Data,nanmean(TempActivity,3));
        end
        Data = Data';
        for D = 1:Dimensions
            Projection(D,:,Cross) = [sum(Basis{Cross}(:,D) .* Data')];
        end
    end
end
if Simultaneous && SS
   Projection(:,:,1) = nanmean(Projection,3); Projection(:,:,2) = [];
end

%% refine explanations
for C = 1:Folds
    TempExplanation{C}(Dimensions+1:end,:) = [];
    Explanation(:,C+1) = TempExplanation{C};
end
Explanation(:,1) = mean(Explanation(:,2:end),2);
Explanation(:,2:end) = [];
