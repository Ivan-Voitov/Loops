function [Sweep,Explanations] = sweep_decoding(Index,varargin)
CCD = false;
Iterations = 5;
Stim = false;
SweepRaw = true;
SweepCells = true;
SweepExclusion = true;
Focus = [];
Lag = 0;
Smooth = 0;
Equate = true;
SoftFocus = false;
DEBUG = false;

%% PASS ARGUMENTS TO CONTROLS
for I=1:2:numel(varargin)
    eval([varargin{I} '= varargin{I+1};']);
end

if Focus
    Focus = 'Focus';
end

%% get data
if ~CCD && ~Stim
    % task dimension
    [DFFs,Trials] = rip(Index,'S','Super','DeNaN','Active',Focus);
    % Classes = cat(1,Index.Class);
elseif CCD && ~Stim
    % cue dimension
    [DFFs,Trials,~] = rip(Index,'S','DeNaN','Context','Active',Focus);
    % Classes = cat(1,Index.CueClass);
elseif Stim
    % stimulus dimension
    [DFFs,Trials,~] = rip(Index,'S','DeNaN','Sontext','Active',Focus);
    % Classes = cat(1,Index.CueClass);
end

% soft focus
if SoftFocus
    DFFs = soft_focus(DFFs,Index,2);
%     for Session = 1:length(DFFs)
%         load(Index(Session).Name,'Trial');
%         Trial = selector(Trial,'HasFrames','Nignore','NoReset','EitherDB');
%         Frames = [];
%         for III = 1:length(Trial)
%             Frames = cat(1,Frames,[Trial(III).Trigger.Delay.Frame:Trial(III).Trigger.Post.Frame]');
%         end
%         Focus = false(size(DFFs{Session},2),1);
%         Focus(Frames(~isnan(Frames))) = true;
%         DFFs{Session}(:,~Focus) = nan;
%     end
end

%% debug
% [TempSweep] = encode({DFFs,Trials},'Lag',Lag,'Stim',Stim,...
%     'CCD',CCD,'Iterate',1,'Smooth',Smooth,'PCsExclude',1:100);

% [TempSweep] = encode({DFFs,Trials},'Lag',Lag,'Stim',Stim,...
%     'CCD',CCD,'Iterate',1,'Smooth',Smooth);
% 
% [Input] = encode(Input,'CCD',true,'Smooth',Smooth,'Equate',Equate);

%% sweep PC #s on raw
if SweepRaw
    for PC = swaparoo({[1:20];[1 10 20]},DEBUG+1)
        [TempSweep] = encode({DFFs,Trials},'Lag',Lag,'Equate',Equate,'Stim',Stim,...
            'CCD',CCD,'Model','LDA','PCsRaw',[1:PC],'Iterate',1,'Smooth',Smooth);
        Sweep.Raw(:,PC) = TempSweep{3};
    end
    for PC = 1:20
        for S = 1:length(TempSweep{5})
            try
                Explanations.Raw(S,PC) = TempSweep{5}{S}(PC);
            catch
                Explanations.Raw(S,PC) = nan;
            end
        end
    end
    for PC = 2:20
        Explanations.Raw(:,PC) = Explanations.Raw(:,PC) + Explanations.Raw(:,PC-1);
    end
end

%% sweep PC exclusion
if SweepExclusion
    for PC = swaparoo({[1:100];[1 50 100]},DEBUG+1)
        [TempSweep] = encode({DFFs,Trials},'Lag',Lag,'Equate',Equate,...
            'Stim',Stim,'CCD',CCD,'Model','LDA','PCsExclude',[1:PC],'Iterate',1,'Smooth',Smooth);
        Sweep.Exclude(:,PC) = TempSweep{3};
    end
    for PC = 1:100
        for S = 1:length(TempSweep{5})
            try
                Explanations.Exclude(S,PC) = TempSweep{5}{S}(PC);
            catch
                Explanations.Exclude(S,PC) = nan;
            end
        end
    end
    Explanations.Exclude(:,1) = 100 - Explanations.Exclude(:,1);
    for PC = 2:100
        Explanations.Exclude(:,PC) = Explanations.Exclude(:,PC-1) - Explanations.Exclude(:,PC);
    end
end
% hold on
% plot((mean(Explanations.Exclude,1)./2)+50,'k')
% plot(mean(Sweep.Exclude,1).*100,'k','marker','o')

%% sweep cell #s
if SweepCells
    for Cells = swaparoo({[1:100];[1 50 100]},DEBUG+1)
        for Iteration = 1:50+Iterations-round(Cells./2)
            [TempSweep] = encode({DFFs,Trials},'Equate',Equate,'Smooth',Smooth,'Lag',Lag,'Stim',Stim,'CCD',CCD,'Model','LDA','Cells',[1:Cells],'Iterate',1);
            Sweep.Cells(:,Cells,Iteration) = TempSweep{3};
            Explanations.Cells(:,Cells,Iteration) = TempSweep{5};
        end
    end
    for Cell = swaparoo({[1:100];[1 50 100]},DEBUG+1)
        TotalIteration = 50+Iterations-round(Cell./2);
        TempCellExplanations(:,Cell) = nanmean(cell2mat(Explanations.Cells(:,Cell,1:TotalIteration)),3);
        TempCellExplanations(:,Cell) = TempCellExplanations(:,Cell) .* 100;
        TempSweepCells(:,Cell) = nanmean(Sweep.Cells(:,Cell,1:TotalIteration),3);
    end
    Sweep.Cells = TempSweepCells;
    Explanations.Cells = TempCellExplanations;
end
