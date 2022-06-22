function [Stat] = opto_bar(Trial,varargin)
Areas = [{'AM'} {'M2'} {'S1'} {'V1'} {'iAM'} {'iM2'}];
Flag = false;
TwoTime = true;
Rotate = false;
EnMouse = false;
%% Define parameters
for I=1:2:numel(varargin)
    eval([varargin{I} '= varargin{I+1};']);
end

if EnMouse
    for I = 1:length(Trial); MouseNames{I} = Trial(I).MouseName; end
    Sessions = unique(MouseNames);
    for I = 1:length(Trial); S(I) = find(strcmp(Trial(I).MouseName,Sessions)); end
    for Mouse = 1:length(Sessions); Trials{Mouse} = Trial(S==Mouse); end
else
    Trials = {Trial};
end

%% get performance
Times = [{'EarlyDelayOnset'} {'LateDelayOnset'} {'StimulusOnset'}];
for Mouse = 1:length(Trials)
    for Time = 1:(3 - TwoTime)
        [ES{Time,Mouse},CI{Time,Mouse},LightSig{Time,Mouse},TaskSig{Time,Mouse}] = performance(selector(Trials{Mouse},'Post','NoReset',Times{Time+(Time == 2 && TwoTime)}),'Responses','OptoDelta',1+EnMouse);
    end
end

% if enmouse'd
if size(ES,2) >1
    for Time = 1:(3 - TwoTime)
        Temp = cat(1,ES{Time,:});
        for K = 1:8
            TempTemp = cat(3,Temp{:,K});
            for Mouse = 1:size(TempTemp,3)
               if any(isnan(TempTemp(:,:,Mouse)))
                   TempTemp(:,:,Mouse) = nan;
               end
            end
            TempES{Time}{K} = nanmean(TempTemp,3);
        end
    end
end

if Rotate
    plot_rotated(ES,CI,Areas);
    % elseif Extend
    %     plot_extend(ES,CI,Areas);
else ~Rotate
    plot_default(ES,CI,Areas,TwoTime,Flag);
end

Stat.Light = LightSig;
Stat.Task = TaskSig;

end
%%
function plot_rotated(ES,CI,Areas)
%% plot
Colours;
[Axes, ~] = tight_fig(length(Areas),2, [0.08 0.02], [0.1 0.1], [0.1 0.01],1,600,200*length(Areas));

for Row = 1:length(Areas)
    for Time = 1:2 %
        Number = ((Row-1)*2)+ Time;
        % instead of C needs to be 'find' index of Areas
        set(gcf, 'currentaxes', Axes(Number)); %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        XMat = [2.5 2.5 0.5 0.5];
        %         if Row+2<6
        %             % mem?
        %             YMat = [-CI{Time}(2,1,2,1) CI{Time}(2,1,2,2) CI{Time}(2,1,2,2) -CI{Time}(2,1,2,1)];
        %         else
        %             YMat = [-CI{Time}(2,1,1,1) CI{Time}(2,1,1,2) CI{Time}(2,1,1,2) -CI{Time}(2,1,1,1)];
        %         end
        %         patch(XMat,YMat,[0.3 0.3 0.3],'EdgeColor','none');
        if Time ==2
            Time = 3;
        end
        b = bar([[ES{1}(1,Time,Row+2) ES{2}(1,Time,Row+2)];[ES{1}(2,Time,Row+2) ES{2}(2,Time,Row+2)]]'); % CHANGE
        
        
        
        
        b(1).FaceColor = 'flat';
        b(1).CData(1:1:end,:) = repmat(Blue,[2 1]);
        b(2).FaceColor = 'flat';
        b(2).CData(1:1:end,:) = repmat(Red,[2 1]);
        hold on
        
        for k1 = 1:2
            ctr(k1,:) = bsxfun(@plus, b(1).XData, [b(k1).XOffset]');
        end
        %         errorbar(ctr',[ES{Type}(1,:,Row+2);ES{Type}(2,:,Row+2)]',...
        %             [CI{Type}(1,:,Row+2,1); CI{Type}(2,:,Row+2,1)]' ,...
        %             [CI{Type}(1,:,Row+2,2); CI{Type}(2,:,Row+2,2)]' ,...
        %             '.k','LineWidth',1);
        
        errorbar(ctr',[[ES{1}(:,Time,Row+2)]';[ES{2}(:,Time,Row+2)]'],...
            [[CI{1}(:,Time,Row+2,1)]';[ CI{2}(:,Time,Row+2,1)]'] ,...
            [[CI{1}(:,Time,Row+2,2)]';[ CI{2}(:,Time,Row+2,2)]'] ,...
            '.k','LineWidth',1);
        
        
        if Time == 1
            %             ytickformat(Axes(Number), 'percentage');
            %             ylabel('\Delta from baseline');
            axis([0.5 2.5 -20 30])
            set(Axes(Number), 'YTick', [-20, 0, 15, 30], 'YLim', [-20, 30]);
            
            
        elseif Time == 3
            
            axis([0.5 2.5 -20 60])
            set(Axes(Number), 'YTick', [-20, 0, 30, 60], 'YLim', [-20, 60]);
            
        end
        %         if Row ~=1
        %                         set(Axes(Number), 'YTick', [], 'YLim', [-20, 60]);
        %
        %         end
        Axes(Number).XTick = [];
    end
    
end

end
%%
function plot_default(ES,CI,Areas,TwoTime,Flag)
%% plot

Colours;
[Axes, ~] = tight_fig(3, length(Areas), [0.08 0.02], [0.1 0.1], [0.1 0.01],1,200*length(Areas),600);

for C = 1:length(Areas)
    for Type = 1:3
        %         TrueType = Type; if Type == 3-TwoTime; TrueType = 3;end
        TrueType = Type;
        Number = (C+(length(Areas) * (Type-1)));
        % instead of C needs to be 'find' index of Areas
        set(gcf, 'currentaxes', Axes(Number)); %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
        %         % cant really do this because thickenss different for different
        %         % tasks
        %         XMat = [3.5-TwoTime 3.5-TwoTime 0.5 0.5];
        %
        %         if C+Flag+2<6
        %             % this is trippy... 2 because that was what was subtracted for
        %             % calculating first 3 area silencings
        %             YMat = [-CI{1}{2}(TrueType) CI{1}{Type}(2,1,2,2) CI{1}{Type}(2,1,2,2) -CI{1}{Type}(2,1,2,1)];
        %         else
        %             YMat = [-CI{1}{1}(2,1,1,1) CI{1}{Type}(2,1,1,2) CI{1}{Type}(2,1,1,2) -CI{1}{Type}(2,1,1,1)];
        %         end
        %         patch(XMat,YMat,[0.3 0.3 0.3],'EdgeColor','none');
        
        if TrueType == 3
            % flip all
            for Ti = 1:3-TwoTime
                for Ta = 1:2
                    ES{Ti}{C+2+Flag}(Ta,TrueType) = -ES{Ti}{C+2+Flag}(Ta,TrueType) ;
                    CI{Ti}{C+2+Flag}(Ta,TrueType,:) = CI{Ti}{C+2+Flag}(Ta,TrueType,[2 1]) ;
                end
            end
        end
        
        
        % disc...
        if TwoTime
            b = bar([ES{1}{C+2+Flag}(:,TrueType)'; ES{2}{C+2+Flag}(:,TrueType)']);
        else
            b = bar([ES{1}{C+2+Flag}(:,TrueType)'; ES{2}{C+2+Flag}(:,TrueType)';ES{3}{C+2+Flag}(:,TrueType)']);
        end
        b(1).FaceColor = 'flat';
        b(1).CData(1:1:end,:) = repmat(Blue,[3-TwoTime 1]);
        b(2).FaceColor = 'flat';
        b(2).CData(1:1:end,:) = repmat(Red,[3-TwoTime 1]);
        hold on
        
        for k1 = 1:2
            ctr(k1,:) = bsxfun(@plus, b(1).XData, [b(k1).XOffset]');
        end
        if TwoTime
            errorbar(ctr',[ES{1}{C+2+Flag}(:,TrueType)'; ES{2}{C+2+Flag}(:,TrueType)'],...
                [CI{1}{C+2+Flag}(:,TrueType,1)'; CI{2}{C+2+Flag}(:,TrueType,1)'],...
                [CI{1}{C+2+Flag}(:,TrueType,2)'; CI{2}{C+2+Flag}(:,TrueType,2)'],...
                '.k','LineWidth',1);
        else
            errorbar(ctr',[ES{1}{C+2+Flag}(:,TrueType)'; ES{2}{C+2+Flag}(:,TrueType)' ; ES{3}{C+2+Flag}(:,TrueType)'],...
                [CI{1}{C+2+Flag}(:,TrueType,1)'; CI{2}{C+2+Flag}(:,TrueType,1)';CI{3}{C+2+Flag}(:,TrueType,1)'],...
                [CI{1}{C+2+Flag}(:,TrueType,2)'; CI{2}{C+2+Flag}(:,TrueType,2)';CI{2}{C+2+Flag}(:,TrueType,2)'],...
                '.k','LineWidth',1);
        end
        if Type == 1 || Type == 2
            %             ytickformat(Axes(Number), 'percentage');
            %             ylabel('\Delta from baseline');
                        if length(Areas) == 6
                axis([0.5 3.5-TwoTime -20 50])
                set(Axes(Number), 'YTick', [-20, 0, 25,50], 'YLim', [-20, 50]);
            else
            axis([0.5 3.5-TwoTime -20 40])
            set(Axes(Number), 'YTick', [-20, 0, 20, 40], 'YLim', [-20, 40]);
                        end
            
        elseif Type == 3
            if length(Areas) == 6
                axis([0.5 3.5-TwoTime -20 70])
                set(Axes(Number), 'YTick', [-20, 0, 35,70], 'YLim', [-20, 70]);
            else
            axis([0.5 3.5-TwoTime -20 60])
            set(Axes(Number), 'YTick', [-20, 0, 20,40, 60], 'YLim', [-20, 60]);
            end
        end
        if C ~=1
            set(Axes(Number), 'YTick', []);
        end
        Axes(Number).XTick = [];
        if Type == 1
            title(Areas{C})
        end
        if C == 1
            ylabel(swap({'Cue (D%)';'Probe (D%)';'Target (D%)'},Type));
        end
        axis square
    end
end
end
%%
function plot_mice(ES,Areas,TwoTime)

Colours;
[Axes, ~] = tight_fig(3, length(Areas), [0.08 0.02], [0.1 0.1], [0.1 0.01],1,200*length(Areas),600);

for C = 1:length(Areas)
    for Type = 1:3

        Number = (C+(length(Areas) * (Type-1)));
        % instead of C needs to be 'find' index of Areas
        set(gcf, 'currentaxes', Axes(Number)); %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
        % calc
        for Mouse = 1:size(ES,2)
            for Ti = 1:3-TwoTime
                for Ta = 1:2
%                     TempEffect(Mouse,Ti,Ta) = ES{1,:}{
                end
            end
        end
        
        % plot
        if Type == 3
            % flip all
            for Ti = 1:3-TwoTime
                for Ta = 1:2
                    ES{Ti}{C+2+Flag}(Ta,Type) = -ES{Ti}{C+2+Flag}(Ta,Type) ;
                    CI{Ti}{C+2+Flag}(Ta,Type,:) = CI{Ti}{C+2+Flag}(Ta,Type,[2 1]) ;
                end
            end
        end
       
        % disc...
        if TwoTime
            b = bar([ES{1}{C+2+Flag}(:,Type)'; ES{2}{C+2+Flag}(:,Type)']);
        else
            b = bar([ES{1}{C+2+Flag}(:,Type)'; ES{2}{C+2+Flag}(:,Type)';ES{3}{C+2+Flag}(:,Type)']);
        end
        b(1).FaceColor = 'flat';
        b(1).CData(1:1:end,:) = repmat(Blue,[3-TwoTime 1]);
        b(2).FaceColor = 'flat';
        b(2).CData(1:1:end,:) = repmat(Red,[3-TwoTime 1]);
        hold on
        
        for k1 = 1:2
            ctr(k1,:) = bsxfun(@plus, b(1).XData, [b(k1).XOffset]');
        end
        if TwoTime
            errorbar(ctr',[ES{1}{C+2+Flag}(:,Type)'; ES{2}{C+2+Flag}(:,Type)'],...
                [CI{1}{C+2+Flag}(:,Type,1)'; CI{2}{C+2+Flag}(:,Type,1)'],...
                [CI{1}{C+2+Flag}(:,Type,2)'; CI{2}{C+2+Flag}(:,Type,2)'],...
                '.k','LineWidth',1);
        else
            errorbar(ctr',[ES{1}{C+2+Flag}(:,Type)'; ES{2}{C+2+Flag}(:,Type)' ; ES{3}{C+2+Flag}(:,Type)'],...
                [CI{1}{C+2+Flag}(:,Type,1)'; CI{2}{C+2+Flag}(:,Type,1)';CI{3}{C+2+Flag}(:,Type,1)'],...
                [CI{1}{C+2+Flag}(:,Type,2)'; CI{2}{C+2+Flag}(:,Type,2)';CI{2}{C+2+Flag}(:,Type,2)'],...
                '.k','LineWidth',1);
        end
        if Type == 1 || Type == 2
            %             ytickformat(Axes(Number), 'percentage');
            %             ylabel('\Delta from baseline');
            if length(Areas) == 6
                axis([0.5 3.5-TwoTime -20 50])
                set(Axes(Number), 'YTick', [-20, 0, 25,50], 'YLim', [-20, 50]);
            else
                axis([0.5 3.5-TwoTime -20 40])
                set(Axes(Number), 'YTick', [-20, 0, 20, 40], 'YLim', [-20, 40]);
            end
            
        elseif Type == 3
            if length(Areas) == 6
                axis([0.5 3.5-TwoTime -20 70])
                set(Axes(Number), 'YTick', [-20, 0, 35,70], 'YLim', [-20, 70]);
            else
                axis([0.5 3.5-TwoTime -20 60])
                set(Axes(Number), 'YTick', [-20, 0, 20,40, 60], 'YLim', [-20, 60]);
            end
        end
        
        if C ~=1
            set(Axes(Number), 'YTick', []);
        end
        Axes(Number).XTick = [];
    end
end



end
