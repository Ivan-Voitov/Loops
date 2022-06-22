function delay_length_symmetry(Trial,varargin)
HalfTime = 2000;
PerfType = 'Correct';

%% PASS ARGUMENTS
for S = 1:2:numel(varargin)
    if ~exist(varargin{S},'var')
        sprintf('Warning: one of the ParseArgs did not exist \r');
    end
    eval([varargin{S} '= varargin{I+1};']);
end


%% ORGANIZE
TempIndex = [];
if iscell(Trial)
    for K = 1:length(Trial)
        for Z = 1:length(Trial{K})
            TempIndex(end+1).FileName = Trial{K}(Z).Name;
        end
    end
end
Trial = TempIndex;

Remove = false(length(Trial),1); clearvars TempNames
for Session = 1:length(Trial)
    TempName = strsplit(Trial(Session).FileName,'_');
    TempNames{Session} = cat(2,TempName{1},'_',TempName{2});
    if any(strcmp(TempNames{Session},TempNames(1:end-1)))
        Remove(Session) = true;
    end
end
Trial(Remove) = [];

for Session = 1:length(Trial)
    Temp = load(Trial(Session).FileName,'Trial');
    Trials{Session} = selector(Temp.Trial(~destruct(Temp.Trial,'Ignore')),'NoReset','Post','NoLight');
    if size(Trials{Session},1) == 1
        Trials{Session} = Trials{Session}';
    end
end

Sessions = 1:length(Trials); Trial = cat(1,Trials{:});

%% EXTRACT
for S = 1:length(Sessions)
    
    % select the first pair of D > WM
    % "we compared the first WM block following a discrimination task block
    % and compared if the same effect existed if it was rotated away vs not
    % rotated away."
    FoundIt = nan;
    for T = 2:length(Trials{S})
        if Trials{S}(T-1).Task == 2 &&  Trials{S}(T).Task == 1
            FoundIt = T;
        end
    end
    if ~isnan(FoundIt)
        First = FoundIt - find(destruct(Trials{S}(FoundIt-1:-1:1),'Contrast')~=...
            circshift(destruct(Trials{S}(FoundIt-1:-1:1),'Contrast'),-1),1);
        Last = length(Trials{S});
        for T = FoundIt+1:length(Trials{S})
            if or((Trials{S}(T-1).Task ~= Trials{S}(T).Task),...
                    (Trials{S}(T-1).DB ~= Trials{S}(T).DB))
                Last = T;
            end
        end
    else
        % nan output
        RotateOut(S,1,:) = nan(4,1);
        RotateOut(S,2,:) = nan(4,1);
        MatchUnmatch(S,1,:) = nan(4,1);
        MatchUnmatch(S,2,:) = nan(4,1);
        continue
    end
    
    TempDB = -Trials{S}(end).DB; %(destruct(TempTrial(end),'DB'));
    Trial = Trials{S}(First:Last);
    FoundIt = FoundIt - First + 1;
    
    for J = 1:2 % which type of plot
        % analyze
        Duration = destruct(Trial,'Trigger.Stimulus.Time') >= HalfTime;
        Selectors = {{2; ~Duration};{2; Duration};...
            {1; ~Duration};{1; Duration};{2; ~Duration};{2; Duration};...
            {1; ~Duration};{1; Duration}};
        clearvars Quad
        for K = 1:4 * J
            TempTrial = Trial(and(and(destruct(Trial,'Task')==Selectors{K}{1},...
                Selectors{K}{2}),destruct(Trial,'Type') ~=2));
            
            % if doing what I think version, then i also select for matched
            % and unmatched cues in WM task
            if J == 2 && Selectors{K}{1} == 1
                if K < 5
                    % OR [1 0]
                    TempTrial = TempTrial(destruct(TempTrial,'Block')==...
                        swap([0 1],(TempDB==15)+1));
                elseif K > 4
                    TempTrial = TempTrial(destruct(TempTrial,'Block')==...
                        swap([1 0],(TempDB==15)+1));
                end
            end
            
            %% calculate numbers
            SR = destruct(TempTrial,'StimulusResponse');
            Type = destruct(TempTrial,'Type');
            if strcmp(PerfType,'Correct')
                Quad(K) = (sum(and(SR==1,Type == 3)) + ...
                    sum(and(isnan(SR),Type == 1))) ...
                    / length(TempTrial);
            elseif strcmp(PerfType,'Performance')
                % performance
                Quad(K) = 1 - (sum(and(isnan(SR),Type == 3)) / sum(Type==3)) - ...
                    (sum(and(SR==1,Type == 1)) / sum(Type==1));
            end
        end
        
        % store output
        if J == 1
            if Trial(1).DB==Trial(end).DB
                RotateOut(S,1,:) = Quad; % matched DB
                RotateOut(S,2,:) = nan(4,1);
            else
                RotateOut(S,1,:) = nan(4,1);
                RotateOut(S,2,:) = Quad; % unmatched DB
            end
        elseif J == 2
            if Trial(1).DB~=Trial(end).DB
                MatchUnmatch(S,1,:) = Quad(1:4); % matched cue
                MatchUnmatch(S,2,:) = Quad(5:8); % unmatched cue
            else
                % can even do somtething like mean(quad(1:4,5:8)) and nan because technically
                % both are unmatched
                MatchUnmatch(S,1,:) = nan(4,1);
                MatchUnmatch(S,2,:) = nan(4,1);
            end
        end
    end
end

%% plot
Colours;
Colour = {Blue;Red;Purple};
YLabels = {PerfType;'Short - Long trial averages';'Short - long trial averages'};
XLabels = {{'Short trials';'Long trials'};{'Not rotated';'Rotated out'};{'Unmatched Cue';'Matched Cue'}};
figure;Fig = gcf;
Fig.Position = [Fig.Position(1) Fig.Position(2) 400 420];
for J = 1:3
    %     Fig = figure;
    subplot(1,3,J)
    for Task = 1:3-(J==1)
        clearvars ToPlot
        if Task < 3
            if J == 1
                ToPlot(:,1) = straighten(RotateOut(:,:,1+((Task-1)*2)));
                ToPlot(:,2) = straighten(RotateOut(:,:,2+((Task-1)*2)));
            elseif J == 2
                ToPlot(:,1) = RotateOut(:,1,1+((Task-1)*2)) - RotateOut(:,1,2+((Task-1)*2));
                ToPlot(:,2) = RotateOut(:,2,1+((Task-1)*2)) - RotateOut(:,2,2+((Task-1)*2));
            elseif J == 3
                ToPlot(:,1) = MatchUnmatch(:,1,1+((Task-1)*2)) - MatchUnmatch(:,1,2+((Task-1)*2));
                ToPlot(:,2) = MatchUnmatch(:,2,1+((Task-1)*2)) - MatchUnmatch(:,2,2+((Task-1)*2));
            end
        else
            if J == 2
                ToPlot(:,1) = (RotateOut(:,1,3)-RotateOut(:,1,1)) - (RotateOut(:,1,4)-RotateOut(:,1,2));
                ToPlot(:,2) = (RotateOut(:,2,3)-RotateOut(:,2,1)) - (RotateOut(:,2,4)-RotateOut(:,2,2));
            elseif J == 3
                ToPlot(:,1) = (MatchUnmatch(:,1,3)-MatchUnmatch(:,1,1)) - (MatchUnmatch(:,1,4)-MatchUnmatch(:,1,2));
                ToPlot(:,2) = (MatchUnmatch(:,2,3)-MatchUnmatch(:,1,1)) - (MatchUnmatch(:,2,4)-MatchUnmatch(:,2,2));
            end
        end
        
        plot([1.05 2.05] - ((Task<3)*0.1),[ToPlot(:,1) ToPlot(:,2)],...
            'color',Colour{Task},'LineStyle',swap({'-';'none'},(J>1)+1),'LineWidth',0.5,...
            'Marker',swap({'none';'o'},(J>1)+1),...
            'MarkerFaceColor',Colour{Task}, 'MarkerSize',5);
        hold on;
        plot([1.05 2.05] - ((Task<3)*0.1),[nanmean(ToPlot(:,1),1) nanmean(ToPlot(:,2),1)],...
            'color',Colour{Task},'LineWidth',2,'Marker','o','MarkerFaceColor',White,...
            'MarkerSize',15);
        
        if J == 1
            [P(Task)]=signrank(ToPlot(:,1),ToPlot(:,2));
        else
            [P(Task)]=ranksum(ToPlot(:,1),ToPlot(:,2));
        end
        text(1.25,0+(Task.*0.15),num2str(P(Task)),'color',Colour{Task});
        
    end
    
    
    %     Fig = gcf;
    %     Fig.Position = [Fig.Position(1) Fig.Position(2) 400 420];
    Ax = gca; %axis square;
%     Ax.Position = [0.22 0.11 0.57 0.815];
    ylabel(YLabels{J});
    Ax.YTick = [-1 -0.75 -0.5 -0.25 0 0.25 0.5 0.75 1];
    Ax.XTick = [1 2];
    Ax.XTickLabel = XLabels{J};
    Ax.YTickLabel = {'-100%';'-75%';'-50%';'-25%';'0%';'25%';'50%';'75%';'100%'};
    
    if J == 1
        axis([0.75 2.25 0-(J>1) 1]);
    else
        axis([0.75 2.25 -0.25 0.5]);
    end
    
end
