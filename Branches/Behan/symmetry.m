function symmetry(Trial,varargin)
%% PASS ARGUMENTS
EnMouse = false;
DBTest = false;
TaskTest = false;

for I = 1:2:numel(varargin)
    if ~exist(varargin{I},'var')
        sprintf('Warning: one of the ParseArgs did not exist \r');
    end
    eval([varargin{I} '= varargin{I+1};']);
end

%% ORGANIZE
if length(Trial)<1000 % i.e., is imaging
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
    
    Sessions = 1:length(Trials); Trial = cat(1,Trials{:}); Flag = true;
else
    if EnMouse
        for I = 1:length(Trial); MouseNames{I} = Trial(I).MouseName; end
        Sessions = unique(MouseNames);
        for I = 1:length(Trial); S(I) = find(strcmp(Trial(I).MouseName,Sessions)); end
    else
        for I = 1:length(Trial); FileNames{I} = Trial(I).FileName; end
        Sessions = unique(FileNames);
        for I = 1:length(Trial); S(I) = find(strcmp(Trial(I).FileName,Sessions)); end
    end
    Flag = false;
end

%% EXTRACT
for J = 1:1+DBTest
    for I = 1:length(Sessions)
        if Flag
            if DBTest
                if J == 1
                    TempTrial = Trials{I}(and(and(destruct(Trials{I},'Light')==0,destruct(Trials{I},'Task')==1),destruct(Trials{I},'DB')==-15));
                else
                    TempTrial = Trials{I}(and(and(destruct(Trials{I},'Light')==0,destruct(Trials{I},'Task')==1),destruct(Trials{I},'DB')==15));
                end
            else
                TempTrial = Trials{I}(and(destruct(Trials{I},'Light')==0,destruct(Trials{I},'Task')==1));
            end
        else
            if ~TaskTest
                TempTrial = Trial(and(and(destruct(Trial,'Light')==0,destruct(Trial,'Task')==1),...
                    (S == I)'));
            else
                TempTrial = Trial(and(destruct(Trial,'Light')==0,...
                    (S == I)'));
            end
        end
        B = destruct(TempTrial,'StimulusResponse');
        C = destruct(TempTrial,'Type');
        if ~TaskTest
            D = destruct(TempTrial,'Block');
        else
            D = 2 - destruct(TempTrial,'Task');
        end
        %     % this is performance
        %     CueA(I) = 1 - (nansum(B(and(D == 0,C == 1)))/nansum(C(D == 0) == 1)) - ...
        %         (nansum(isnan(B(and(D == 0,C == 3))))/nansum(C(D == 0) == 3));
        %     CueB(I) = 1 - (nansum(B(and(D == 1,C == 1)))/nansum(C(D == 1) == 1)) - ...
        %         (nansum(isnan(B(and(D == 1,C == 3))))/nansum(C(D == 1) == 3));
        
        % this is percent correct
        %     CueA(I) = (nansum(B(and(D == 0,C == 3))) + nansum(isnan(B(and(D == 0,C == 1))))) ...
        %         / (nansum(C(D == 0) == 3) + nansum(C(D == 0) == 1));
        [CueA(I),CIA(I,:)] = binofit(nansum(B(and(D == 0,C == 3))) + nansum(isnan(B(and(D == 0,C == 1)))),(nansum(C(D == 0) == 3) + nansum(C(D == 0) == 1)));
        
        %     CueB(I) = (nansum(B(and(D == 1,C == 3))) + nansum(isnan(B(and(D == 1,C == 1))))) ...
        %         / (nansum(C(D == 1) == 3) + nansum(C(D == 1) == 1));
        [CueB(I),CIB(I,:)] = binofit((nansum(B(and(D == 1,C == 3))) + nansum(isnan(B(and(D == 1,C == 1))))),(nansum(C(D == 1) == 3) + nansum(C(D == 1) == 1)));
    end
    % if DB stuff is happening
    CIA(isnan(CueA),:) = [];
    CIB(isnan(CueA),:) = [];
    CueA(isnan(CueA)) = [];
    CueB(isnan(CueB)) = [];
    
    
    
    TempTrial = Trial(and(destruct(Trial,'Light')==0,destruct(Trial,'Task')==1));
    B = destruct(TempTrial,'StimulusResponse');
    C = destruct(TempTrial,'Type');
    if ~TaskTest
        D = destruct(TempTrial,'Block');
    else
        D = 2- destruct(TempTrial,'Task');
    end
    [AllA,~] = binofit(nansum(B(and(D == 0,C == 3))) + nansum(isnan(B(and(D == 0,C == 1)))),(nansum(C(D == 0) == 3) + nansum(C(D == 0) == 1)));
    [AllB,~] = binofit((nansum(B(and(D == 1,C == 3))) + nansum(isnan(B(and(D == 1,C == 1))))),(nansum(C(D == 1) == 3) + nansum(C(D == 1) == 1)));
    
    %% plot
    figure;
    subplot(1,2,1)
    Colours;
    
    % line plot
    plot([CueA;CueB],'color',Grey,'LineWidth',1,'Marker','o','MarkerSize',10,'MarkerFaceColor',White)
    hold on
    plot([0.75 1.25],[AllA AllA],'color',Black,'LineWidth',2)
    plot([1.75 2.25],[AllB AllB],'color',Black,'LineWidth',2)
    axis([0.5 2.5 0 1]);
    Ax = gca;
    Ax.YTick = [0 0.5 1];
    Ax.XTick = [1 2];
    Ax.XTickLabel = {'-45';'+45'};
    Ax.YTickLabel = {'0%';'50%';'100%'};
    [P]=signrank(CueA,CueB);
    text(0.5,0.5,num2str(P));
    
    subplot(1,2,2)
    % bar plot
    b = bar([mean(CueA) mean(CueB)]);
    b(1).FaceColor = 'flat';
    b(1).CData(1,:) = [0.5 0.5 0.5];
    b(1).CData(2,:) = [0.5 0.5 0.5];
    hold on
    try
        CI(1) = 1.96 * (std(CueA) / (length(MouseNames))^0.5);
        CI(2) = 1.96 * (std(CueB) / (length(MouseNames))^0.5);
    catch
        CI(1) = 1.96 * (std(CueA) / (length(Trials))^0.5);
        CI(2) = 1.96 * (std(CueB) / (length(Trials))^0.5);
    end
    [~,~,Temp] = normfit(CueA);
    CI(1) = mean(CueA) - Temp(1);
    [~,~,Temp] = normfit(CueB);
    CI(2) = mean(CueB) - Temp(1);
    errorbar([1 2],[mean(CueA); mean(CueB)]',[CI(2) ; CI(1)]','.k');
    Ax = gca;
    Ax.YTick = [0 0.5 1];
    Ax.YLim = [0 1];
    Ax.XTick = [1 2];
    if ~TaskTest
        Ax.XTickLabel = {'-45';'+45'};
    else
        Ax.XTickLabel = {'Discrimination';'Memory'};
    end
    Ax.YTickLabel = {'0%';'50%';'100%'};
    
    
    text(0.5,0.5,num2str([mean(CueA)-CI(1); mean(CueA); mean(CueA)+CI(1)]));
    text(1.5,0.5,num2str([mean(CueB)-CI(2); mean(CueB); mean(CueB)+CI(2)]));
    if DBTest
        if J ==1
            suptitle('DB is -15');
        else
            suptitle('DB is +15');
        end
    end
end
