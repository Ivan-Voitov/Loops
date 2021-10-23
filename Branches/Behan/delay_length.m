function [Model] = delay_length(TrialOff,TrialOn,varargin)
%% PASS ARGUMENTS TO EXPERIMENT CONTROLS
PerfType = 'Response';
Triple = false;
Mice = false;
Split = false;
ToPlot = [1 2 3 4 5 6];
Fit = 1;
Tom = false;
Inset = true;
BinSize = 32;
D = false;
Truncate = 0;
Axes = [];
Centroids = 5;
Sub = false;

for I = 1:2:numel(varargin)
    if ~exist(varargin{I},'var')
        sprintf('Warning: one of the ParseArgs did not exist \r');
    end
    eval([varargin{I} '= varargin{I+1};']);
end

%% Selection
if isempty(TrialOn)
    Flag = false;
else
    Flag = true;
end
Duration = round((3200 - Truncate)./ 16.667);

for J = 1:(Flag+1)
    
    
    if J == 1; Trial = TrialOff; else; Trial = TrialOn; end
    try
        DelayLine = destruct(Trial,'Trigger.Stimulus.Line');
    catch
       DelayLine = destruct(Trial,'DelayLine'); 
    end
    DelayLine = DelayLine - min(DelayLine) + 1;
    DelayLine(DelayLine > Duration) = nan;
    % mice names
    try
        for I = 1:length(Trial); MouseNames{I} = Trial(I).MouseName; end
        MouseNames = unique(MouseNames);
    catch
        for I = 1:length(Trial); MouseNames{I} = Trial(I).Mouse; end
        MouseNames = unique(MouseNames);
    end
    %% do feature extraction
    % define selections
    SelectionAll = cell(6,Duration); % 6 trial types times 192 bins
    SelectionMice = cell(6,Centroids,length(MouseNames)); % 5 centroids, and n mice
    SelectionSplit = cell(6,Duration,length(MouseNames));  % 6 trial types times 192 bins
    
    % populate nans to selections
    [SelectionAll{:}] = deal(nan(length(Trial),1));
    [SelectionMice{:}] = deal(nan(length(Trial),1));
    [SelectionSplit{:}] = deal(nan(length(Trial),1));
    
    [~,Xc] = hist(double(DelayLine),Centroids);
    Xb = [0 Xc+Xc(1)-1];
    
    T = zeros(length(Trial),1);
    M = zeros(length(Trial),1);
    
    for I = 1:length(Trial)
        % trial types
        if Trial(I).Task == 2 && Trial(I).Type == 1 % per dist
            T(I) = 1;
        elseif Trial(I).Task == 2 && Trial(I).Type == 2 % per probe
            T(I) = 2;
        elseif  Trial(I).Task == 2 && Trial(I).Type == 3 % per tar
            T(I) = 3;
        elseif Trial(I).Task == 1 && Trial(I).Type == 1 % mem dist
            T(I) = 4;
        elseif Trial(I).Task == 1 && Trial(I).Type == 2 % mem probe
            T(I) = 5;
        elseif  Trial(I).Task == 1 && Trial(I).Type == 3 % mem tar
            T(I) = 6;
        end
        
        % mice
        try
            M(I) = find(strcmp(Trial(I).MouseName,MouseNames));
        catch
            M(I) = find(strcmp(Trial(I).Mouse,MouseNames));
        end
        % SelectionAll and SelectionSplit
        for II = 1:size(SelectionAll,2) %192
            if DelayLine(I) == II
                SelectionAll{T(I),II}(I) = true;
                SelectionSplit{T(I),II,M(I)}(I) = true;
            else
                SelectionAll{T(I),II}(I) = false;
                SelectionSplit{T(I),II,M(I)}(I) = false;
            end
        end
        
        % SelectionMice
        for II = 1:size(SelectionMice,2) %5
            if DelayLine(I) > Xb(II) && DelayLine(I) <= Xb(II+1)
                SelectionMice{T(I),II,M(I)}(I) = true;
            else
                SelectionMice{T(I),II,M(I)}(I) = false;
            end
        end
        
        % Responses
        if strcmp(PerfType,'Performance') && ~Fit
            if Trial(I).Type == 1
                Weight(I) = 0.45;
            elseif Trial(I).Type == 3
                Weight(I) = 3.55;
            end
        else
            Weight(I) = 1;
        end
        
        if strcmp(PerfType,'Response') || strcmp(PerfType,'Performance') 
            Responses(I) = double(~isnan(Trial(I).StimulusResponse));
        elseif strcmp(PerfType,'Correct') 
            % correctness
            if (Trial(I).Type == 3 && Trial(I).StimulusResponse == 1) || (Trial(I).Type == 1 && isnan(Trial(I).StimulusResponse))
                Responses(I) = 1;
            elseif Trial(I).Type == 2
                Responses(I) = nan;
            else
                Responses(I) = 0;
            end
            if T(I) ~= 2 && T(I)~= 5 % 1 and 3 > 1, 4 and 6 > 4
                if T(I) == 3 || T(I) == 6
                    IsTarget(I) = true;
                else
                    IsTarget(I) = false;
                end
                T(I) = ((T(I)>3)*3) +1;
            end
        end
    end
    
    %% define lines
    if ~D
        for Type = ToPlot % for each type
            if Mice
                % for the centroids
                for C = 1:size(SelectionMice,2)
                    for Mouse = 1:size(SelectionMice,3)
                        [PerfMice{J}(Type,C,Mouse), CIMice{J}(Type,C,Mouse,:)] =  binofit(sum(Responses(SelectionMice{Type,C,Mouse} == 1)),nansum(SelectionMice{Type,C,Mouse} == 1));
                    end
                end
            end
            if ~Split
                if Fit == 1 % line regression
                    LineAll{J}{Type} = fitglm(DelayLine(T==Type),Responses(T==Type),'linear','Distribution','normal','Dispersion', true,'Weights',Weight(T==Type));
%                     LineAll{J}{Type} = fitglm(DelayLine(T==Type),Responses(T==Type),'linear','Distribution','normal','Dispersion', true);
                    [PerfAll{J}(Type,:), CIAll{J}(Type,:,:)] = predict(LineAll{J}{Type},[0:1:Duration]');
                elseif Fit == 2 % glm logit link
                    LineAll{J}{Type} = fitglm(DelayLine(T==Type),Responses(T==Type),'linear','Distribution','binomial','Dispersion', true,'Weights',Weight(T==Type));
                    [PerfAll{J}(Type,:), CIAll{J}(Type,:,:)] = predict(LineAll{J}{Type},[0:1:Duration]');
                elseif Fit == 3 % binomial identity link
                    LineAll{J}{Type} = fitglm(DelayLine(T==Type),Responses(T==Type),'linear','Link','identity','Distribution','binomial','Dispersion', true,'Weights',Weight(T==Type));
                    [PerfAll{J}(Type,:), CIAll{J}(Type,:,:)] = predict(LineAll{J}{Type},[0:1:Duration]');
                else
                    if ~strcmp(PerfType,'Performance')
                        for II = 1:BinSize
                            [PerfAll{J}(Type,II), CIAll{J}(Type,II,:)] = binofit(nansum(Responses...
                                (and(T==Type,ceil(DelayLine/(Duration/BinSize))==II))),nansum(and(T==Type,ceil(DelayLine/(Duration/BinSize))==II)));
                        end
                    else
                        % make the trials which are 'target' in T == 1 and
                        % T == 4 weighted more
                        for II = 1:BinSize
                            
                            [X, CIAll{J}(Type,II,:)] = binofit(nansum(Responses...
                                (and(T==Type,ceil(DelayLine/(Duration/BinSize))==II))),nansum(and(T==Type,ceil(DelayLine/(Duration/BinSize))==II)));
                            
                            [Temp1, ~] = binofit(nansum(Responses...
                                (and(and(T==Type,IsTarget'),ceil(DelayLine/(Duration/BinSize))==II))),nansum(and(and(T==Type,IsTarget'),ceil(DelayLine/(Duration/BinSize))==II)));
                            
                            [Temp2, ~] = binofit(nansum(Responses...
                                (and(and(T==Type,~IsTarget'),ceil(DelayLine/(Duration/BinSize))==II))),nansum(and(and(T==Type,~IsTarget'),ceil(DelayLine/(Duration/BinSize))==II)));
                            %                             PerfAll{J}(Type,II) = ((Temp1 + Temp2) / 2);
                            PerfAll{J}(Type,II) = 1 - (1-Temp1) - (1-Temp2);
                            
                            CIAll{J}(Type,II,:) = CIAll{J}(Type,II,:) + (PerfAll{J}(Type,II)-X);
                        end
                    end
                end
            else
                % if split
                for Mouse = 1:size(SelectionMice,3)
                    %                     try
                    %                         LineSplit{Type,Mouse} = fitglm(DelayLine(and(T==Type,M == Mouse)),Responses(and(T==Type,M == Mouse)),'linear','Distribution','binomial','Weights',Weight(T==Type));
                    %                     catch
                    
                    if Fit == 1
                        LineSplit{Type,Mouse} = fitglm(DelayLine(and(T==Type,M == Mouse)),Responses(and(T==Type,M == Mouse)),'linear','Distribution','normal','Dispersion', true);
                        %                     end
                        [PerfSplit{J}(Type,Mouse,:), CISplit{J}(Type,Mouse,:,:)] = predict(LineSplit{Type,Mouse},[0:1:Duration]');
                    elseif Fit == 2
                        LineSplit{Type,Mouse} = fitglm(DelayLine(and(T==Type,M == Mouse)),Responses(and(T==Type,M == Mouse)),'linear','Distribution','binomial','Dispersion', true);
                        [PerfSplit{J}(Type,Mouse,:), CISplit{J}(Type,Mouse,:,:)] = predict(LineSplit{Type,Mouse},[0:1:Duration]');
                    end
                end
            end
        end
        
        %% fill in shit
        if ~Mice
            PerfMice{J} = [];
            CIMice{J} = [];
        end
        if Split
            PerfSplit{J} = PerfSplit{J} .* 100;
            CISplit{J} = CISplit{J} .* 100;
            PerfAll{J} = [];
            CIAll{J} = [];
        else
            PerfAll{J} = PerfAll{J} .* 100;
            CIAll{J} = CIAll{J} .* 100;
            PerfMice{J} = PerfMice{J} .* 100;
            CIMice{J} = CIMice{J} .* 100;
            PerfSplit{J} = [];
            CISplit{J} = [];
        end
    elseif D
        for C = 1:size(SelectionMice,2)
            for Mouse = 1:size(SelectionMice,3)
                X = nanmean( Responses(SelectionMice{1,C,Mouse} == 1));
                Y = nanmean( Responses(SelectionMice{3,C,Mouse} == 1));
%                 if C == 5 && Mouse == 7
%                     Y =  0.95;
%                 end
                PerD{J}(Mouse,C) = norminv(Y) - norminv(X);
                X = nanmean( Responses(SelectionMice{4,C,Mouse} == 1));
                Y = nanmean( Responses(SelectionMice{6,C,Mouse} == 1));
                MemD{J}(Mouse,C) = norminv(Y) - norminv(X);
            end
            X = nanmean( Responses(any(cat(2,SelectionMice{4,C,:})')));
            Y = nanmean( Responses(any(cat(2,SelectionMice{6,C,:})')));
            DMemD{J}(C) = norminv(Y) - norminv(X);
            X = nanmean( Responses(any(cat(2,SelectionMice{1,C,:})')));
            Y = nanmean( Responses(any(cat(2,SelectionMice{3,C,:})')));
            DPerD{J}(C) = norminv(Y) - norminv(X);
        end
        MemD{J}(end+1,:) = DMemD{J}(:);
        PerD{J}(end+1,:) = DPerD{J}(:);
    end
    try
        if ~Split
            Model{J} = LineAll;
        else
            Model{J} = LineSplit;
        end
    catch
        Model{J} = [];
    end
    
    %% hack fix
    if Fit && strcmp(PerfType,'Performance')
        for Type = [1 4]
            PerfAll{J}(Type,:) = 100 - PerfAll{J}(Type,:) - (100-PerfAll{J}(Type+2,:));
        end
    end
    %% PLOT
    if Triple; plot_triple(Flag,J,PerfAll{J},CIAll{J},PerfSplit{J},CISplit{J},Xc,PerfMice{J},Mice,Fit,BinSize,Split,ToPlot,Truncate); end
    if D; plot_d(Flag,J,MemD{J},PerD{J},Xc); end
    if Tom; [Axes] = plot_tom(Axes,Flag,J,PerfAll{J},CIAll{J},PerfSplit{J},CISplit{J},Xc,PerfMice{J},Mice,Fit,BinSize,Split,ToPlot,Truncate); end
    if ~Tom && ~Triple && ~D; plot_single(Axes,Flag,J,PerfAll{J},CIAll{J},PerfSplit{J},CISplit{J},Xc,PerfMice{J},Mice,Fit,BinSize,Split,swaparoo({ToPlot;[1 4]},and(Fit , strcmp(PerfType,'Performance'))+1),Truncate); end
    
    %% do the inset
    if Inset && Fit
        for Type = ToPlot
            for Permute = 1:5
                [TempDelayLine,Ind] = datasample(DelayLine(T==Type),length(DelayLine(T==Type)));
                TempResponses = Responses(T==Type); TempResponses = TempResponses(Ind);
                TempWeights = Weight(T==Type); TempWeights = TempWeights(Ind);
                TempLine = fitglm(TempDelayLine,TempResponses,'linear','Distribution','Normal','Dispersion', true,'Weights',TempWeights);
                ParamInset(J,Type,Permute,:) = TempLine.Coefficients.Estimate;
                %             DelogedParamInset(J,Type,Permute,:) = exp(TempLine.Coefficients.Estimate);
            end
        end
    end
end
%%
if Inset && Fit && Flag
    Colours;
    for Type = ToPlot
        %         figure;
        
        for F = 1:2
            %         subplot(2,1,F); hold on;
            [A(Type,F), ~, B(Type,F,:)] = normfit(squeeze(ParamInset(1,Type,:,F)));
            [AA(Type,F), ~, BB(Type,F,:)] = normfit(squeeze(ParamInset(2,Type,:,F)));
            B(Type,F,:) = B(Type,F,:) - A(Type,F);
            BB(Type,F,:) = BB(Type,F,:) - AA(Type,F);
        end
    end
    
    A = A * 100;
    B = B*100;
    AA = AA * 100;
    BB = BB*100;
    
    for F = 1:2
        figure;
        b = bar([[A([1],F) AA([1],F)]; [A([4],F) AA([4],F)]])
        
        b(1).FaceColor = 'flat';
        b(1).CData(1:1:end,:) = [Blue;Red];%repmat(Blue,[2 1]);
        b(2).FaceColor = 'flat';
        b(2).CData(1:1:end,:) = [Blue;Red];%repmat(Red,[2 1]);
        hold on
        for k1 = 1:2
            ctr(k1,:) = bsxfun(@plus, b(1).XData, [b(k1).XOffset]');
        end
        
        errorbar(ctr',[[A([1],F) AA([1],F)]; [A([4],F) AA([4],F)]],...
            [[B([1],F,1) BB([1],F,1)]; [B([4],F,1) BB([4],F,1)]],...
            [[B([1],F,2) BB([1],F,2)]; [B([4],F,2) BB([4],F,2)]],...
            'k');
    end
    %         histogram(squeeze(ParamInset(1,Type,:,F)),100,'Normalization','pdf'...
    %             ,'FaceColor',Brown,'EdgeColor','none');
    %         histogram(squeeze(ParamInset(2,Type,:,F)),100,'Normalization','pdf'...
    %             ,'FaceColor',Silver,'EdgeColor','none');
    %         [P] = ranksum(squeeze(ParamInset(1,Type,:,F)),squeeze(ParamInset(2,Type,:,F)));
    %         if F == 1
    %             title(strcat({'Intercept with a p = '},{num2str(P)},{''}));
    %         else
    %             title(strcat({'Slope with a p = '},{num2str(P)},{''}));
    %         end
end
%     if Type == 1
%         sgtitle('Discrimination Task');
%     elseif Type == 4
%        sgtitle('Memory Task');
%     end
%
%     end
% end
end

%% d prime
function plot_d(Flag,J,MemD,PerD,Xc)
    XPositions = round((Xc.* 16.6667) +800);

if J == 1
    [~, ~] = tight_fig(1, 1, 0.02, [0.12 0.05], [0.18 0.1],1,600,600);
    hold on;
    Ax = gca;
    Ax.YColor = 'k';
    Ax.YTick = [0 1 2 3 4 5];
    Ax.YTickLabel = [0 1 2 3 4 5];
    Ax.FontSize = 16;
    axis([800 4000 0 5]);
    Ax.XTick =  round((Xc.* 16.6667) +800);
    Ax.XTickLabel = round((Xc.* 16.6667) +800);
    ylabel('d''','FontSize',16);
    xlabel('Delay length (ms)','FontSize',16);
end

if J == 2 || (~Flag)
    Colours;
else
    [Red,Blue] = deal([0.5 0.5 0.5]);
end

for Z = 1:10
    if Z == size(MemD,1)
        plot( round((Xc.* 16.6667) +800),MemD(Z,:),'color',Red,'LineWidth',4,...
            'Marker','o','MarkerSize',10,'MarkerFaceColor',Red);
        plot( round((Xc.* 16.6667) +800),PerD(Z,:),'color',(Blue),'LineWidth',4,...
            'Marker','o','MarkerSize',10,'MarkerFaceColor',(Blue));
    else
        %         plot( round((Xc.* 16.6667) +800),MemD(Z,:),'color',Red + (([rand rand rand] - 0.5).* 0.39),'LineWidth',1.5,...
        %         'Marker','o','MarkerFaceColor',[1 1 1]);
        plot( round((Xc.* 16.6667) +800),MemD(Z,:),'color',(Red+[1 1 1])./2,'LineStyle','--','LineWidth',1,...
            'Marker','o','MarkerFaceColor',(Red+[1 1 1])./2);
        plot( round((Xc.* 16.6667) +800),PerD(Z,:),'color',(Blue+[1 1 1])./2,'LineStyle','--','LineWidth',1,...
            'Marker','o','MarkerFaceColor',(Blue+[1 1 1])./2);
    end
end

for Com = 1:length(Xc)-1
    [P] = signrank(MemD(1:9,Com),MemD(1:9,Com+1),'tail','right');
    text(XPositions(Com),0.5,num2str(P));
    [P] = signrank(PerD(1:9,Com),PerD(1:9,Com+1),'tail','right');
    text(XPositions(Com),2.5,num2str(P));
end

end

%% split type
function plot_triple(Flag,J,PerfAll,CIAll,PerfSplit,CISplit,Xc,PerfMice,Mice,Fit,BinSize,Split,ToPlot,Truncate)
if J == 1
    [Axes, ~] = tight_fig(1,3, 0.02, [0.12 0.05], [0.06 0.034],1,1200,600);
end
for Triple = [1 2 3]
    set(gcf, 'currentaxes', Axes(Triple));
    hold on;
    if J == 1
        Ax = gca;
        if ~Truncate
            Ax.XTick = [800 1600 2400 3200 4000];
            Ax.XTickLabel = [800 1600 2400 3200 4000];
        else
            Ax.XTick = [800 (4000-Truncate)];
            Ax.XTickLabel = [800 (4000-Truncate)];
        end
        Ax.YColor = 'k';
        axis([800 4000 0 100]);
    end
    if ~Fit
        XRange = [800+((3200-Truncate)/(BinSize*2)):((3200-Truncate)/BinSize):4000-Truncate];
    else
        XRange = [800:16.6667:4001];
    end
    if J == 2 || (~Flag)
        Colours;
    else
        [Red,Blue] = deal([0.5 0.5 0.5]);
    end
    if J == 1
        if Triple == 1
            Ax.YColor = 'k';
            Ax.YTick = [0 50 100];
            Ax.YTickLabel = [0 50 100];
            Ax.FontSize = 16;
            % ytickformat(Ax, 'percentage');
            ylabel('Response probability (%)','FontSize',16);
        end
        Ax.FontSize = 16;
        
        xlabel('Delay length (ms)','FontSize',16);
    end
    for I = [Triple (Triple + 3)]
        if I < 4
            Colour = Blue;
        else
            Colour = Red;
        end
        if ~Split
            fill([XRange XRange(end:-1:1)], [CIAll(I,:,1) CIAll(I,end:-1:1,2)],Colour,...
                'EdgeColor','none','FaceAlpha',0.2);
            plot(XRange,PerfAll(I,:)','Color',Colour,'LineWidth',2);
        else
            for Mouse = 1:size(PerfSplit,2)
                fill([XRange XRange(end:-1:1)], [squeeze(CISplit(I,Mouse,:,1))' squeeze(CISplit(I,Mouse,end:-1:1,2))'],Colour,...
                    'EdgeColor','none','FaceAlpha',0.2);
                plot(XRange,squeeze(PerfSplit(I,Mouse,:))','Color',Colour,'LineWidth',3);
            end
        end
    end
end
end
%% all together
function plot_single(Axes,Flag,J,PerfAll,CIAll,PerfSplit,CISplit,Xc,PerfMice,Mice,Fit,BinSize,Split,ToPlot,Truncate)
if J == 1
    if isempty(Axes)
        if ~Flag
            [~, ~] = tight_fig(1, 1, 0.02, [0.12 0.05], [0.18 0.1],1,400,600);
        else
            [~, ~] = tight_fig(1, 1, 0.02, [0.12 0.1], [0.18 0.1],1,600,600);
        end
    end
    hold on;
end
if ~Fit
    XRange = [800+((3200-Truncate)/(BinSize*2)):((3200-Truncate)/BinSize):4000-Truncate];
else
    XRange = [800:16.6667:4001-Truncate];
end

if J == 2 || (~Flag)
    Colours;
else
    [Red,Blue] = deal([0.5 0.5 0.5]);
end
for I = ToPlot
    if I < 4
        Colour = Blue;
    else
        Colour = Red;
    end
    if ~Split
        if J == 2 || ~(Flag)
            fill([XRange XRange(end:-1:1)], [CIAll(I,:,1) CIAll(I,end:-1:1,2)],Colour,...
                'EdgeColor','none','FaceAlpha',0.2);
        end
        if I == 1 || I == 4
            plot(XRange,PerfAll(I,:)','Color',Colour,'LineWidth',2,'LineStyle','--');
        elseif I == 2 || I == 5
            plot(XRange,PerfAll(I,:)','Color',Colour,'LineWidth',2,'LineStyle','--');
        else
            plot(XRange,PerfAll(I,:)','Color',Colour,'LineWidth',2);
        end
    else
        for Mouse = 1:size(PerfSplit,2)
            if J == 2 || ~(Flag)
                fill([XRange XRange(end:-1:1)], [squeeze(CISplit(I,Mouse,:,1))' squeeze(CISplit(I,Mouse,end:-1:1,2))'],Colour,...
                    'EdgeColor','none','FaceAlpha',0.2);
            end
            if I == 1 || I == 4
                plot(XRange,squeeze(PerfSplit(I,Mouse,:))','Color',Colour,'LineWidth',2,'LineStyle','--');
            else
                plot(XRange,squeeze(PerfSplit(I,Mouse,:))','Color',Colour,'LineWidth',2);
            end
        end
    end
    
    if Mice
        for II = 1:9
            scatter((Xc.*16.667)+800+((rand.*50)-25),PerfMice(I,:,II),30,Colour,'MarkerFaceColor',Colour);
        end
    end
end

% Ax = gca;
if J == 1 && isempty(Axes)
    Ax = gca;
    if ~Truncate
        Ax.XTick = [800 1600 2400 3200 4000];
        Ax.XTickLabel = [800 1600 2400 3200 4000];
    else
        Ax.XTick = [800 (4000-Truncate)];
        Ax.XTickLabel = [800 (4000-Truncate)];
    end
    Ax.YColor = 'k';
    Ax.YTick = [0 50 100];
    Ax.YTickLabel = [0 50 100];
    Ax.FontSize = 16;
    if ~Flag
        ylabel('Response probability (%)','FontSize',16);
    end
    xlabel('Delay length (ms)','FontSize',16);
end
axis([800 4000-Truncate 0 100]);

end
%% with subplot of probe response
function [Axes] = plot_tom(Axes,Flag,J,PerfAll,CIAll,PerfSplit,CISplit,Xc,PerfMice,Mice,Fit,BinSize,Split,ToPlot,Truncate)
TempFlag = true;
%% plot
if J == 1 || (~Flag)
    [Axes(1), ~] = tight_fig(1, 1, 0.02, [0.46 0.05], [0.22 0.1],1,400,600);
    [Axes(2), ~] = tight_fig(1, 1, 0.02, [0.12 0.72], [0.22 0.1],0,400,600);
    if Flag
        [Red,Blue] = deal([0.5 0.5 0.5]);
    else
        Colours;
    end
else
    Colours;
end
% top
set(gcf, 'currentaxes', Axes(1)); %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if J == 1
    
    Ax = gca;
    if ~Truncate
        Ax.XTick = [800 1600 2400 3200 4000];
        Ax.XTickLabel = [800 1600 2400 3200 4000];
    else
        Ax.XTick = [800 (4000-Truncate)];
        Ax.XTickLabel = [800 (4000-Truncate)];
    end
    axis([800 4000 0 100]);
    hold on;
    Ax.YTick = [0 50 100];
    Ax.YColor = 'k';
    Ax.YTickLabel = [0 50 100];
    Ax.FontSize = 16;
    ylabel('Response probability (%)','FontSize',16);
    
end
if ~Fit
    XRange = [800+((3200-Truncate)/(BinSize*2)):((3200-Truncate)/BinSize):4000-Truncate];
else
    XRange = [800:16.6667:4001-Truncate];
end
if max(ToPlot) <= 3 && any(ToPlot==3)
    % disc
    ToDo1 = [1 3]; ToDo2 = [2];
elseif min(ToPlot) >= 4 && any(ToPlot==6)
    % mem
    ToDo1 = [4 6]; ToDo2 = [5];
elseif any(ToPlot==6)
    % both
    ToDo1 = [1 3 4 6]; ToDo2 = [2 5];
else
    % correct
    ToDo1 = [1 4]; ToDo2 = [2 5];
end
for I = ToDo1
    if I < 4
        Colour = Blue;
    else
        Colour = Red;
    end
    if ~Split
%         if ~TempFlag
%             if J == 2 || (~Flag)
                fill([XRange XRange(end:-1:1)], [CIAll(I,:,1) CIAll(I,end:-1:1,2)],Colour,...
                    'EdgeColor','none','FaceAlpha',0.2);
%             end
            if I == 1 || I == 4
                plot(XRange,PerfAll(I,:)','Color',Colour,'LineWidth',2,'LineStyle','--');
            else
                plot(XRange,PerfAll(I,:)','Color',Colour,'LineWidth',2);
            end
%         else
%             errorbar([1400 2600],[PerfAll(I,1); PerfAll(I,2)]',[CIAll(I,:,:) ; CIAll(I,:,:)],'.k');
%             
%         end
    else
        for Mouse = 1:size(PerfSplit,2)
            if J == 2 || ~(Flag)
                fill([XRange XRange(end:-1:1)], [squeeze(CISplit(I,Mouse,:,1))' squeeze(CISplit(I,Mouse,end:-1:1,2))'],Colour,...
                    'EdgeColor','none','FaceAlpha',0.2);
            end
            if I == 1 || I == 4
                plot(XRange,squeeze(PerfSplit(I,Mouse,:))','Color',Colour,'LineWidth',2,'LineStyle','--');
            else
                plot(XRange,squeeze(PerfSplit(I,Mouse,:))','Color',Colour,'LineWidth',2);
            end
        end
    end
end
% bottom
set(gcf, 'currentaxes', Axes(2));
if J == 1
    Ax = gca;
    axis([800 4000 0 20]);
    hold on;
    Ax.YTick = [0 20];
    Ax.YColor = 'k';
    Ax.YTickLabel = [0 20];
    Ax.FontSize = 16;
    ylabel({'Probe response';' probability (%)'},'FontSize',16);
    if Fit
        XRange = [800:16.6667:4001-Truncate];
    else
        XRange = [800+((3200-Truncate)/(BinSize*2)):((3200-Truncate)/BinSize):4000-Truncate];
    end
    xlabel('Delay length (ms)','FontSize',16);
    if ~Truncate
        Ax.XTick = [800 1600 2400 3200 4000];
        Ax.XTickLabel = [800 1600 2400 3200 4000];
    else
        Ax.XTick = [800 (4000-Truncate)];
        Ax.XTickLabel = [800 (4000-Truncate)];
    end
end
for I = ToDo2
    if I < 4
        Colour = Blue;
    else
        Colour = Red;
    end
    if ~Split
    if J == 2 || (~Flag)
        fill([XRange XRange(end:-1:1)], [CIAll(I,:,1) CIAll(I,end:-1:1,2)],Colour,...
            'EdgeColor','none','FaceAlpha',0.2);
    end
    plot(XRange,PerfAll(I,:)','Color',Colour,'LineWidth',2,'LineStyle','--');
    else
        for Mouse = 1:size(PerfSplit,2)
            if J == 2 || ~(Flag)
                fill([XRange XRange(end:-1:1)], [squeeze(CISplit(I,Mouse,:,1))' squeeze(CISplit(I,Mouse,end:-1:1,2))'],Colour,...
                    'EdgeColor','none','FaceAlpha',0.2);
            end
                plot(XRange,squeeze(PerfSplit(I,Mouse,:))','Color',Colour,'LineWidth',2,'LineStyle','--');
        end
    end
end
end