% basically a wrapper of wind_roi. generates trial avg'd traces

function [Trace,varargout] = avg_triggered(DFFs,Trials,Trigger,varargin)
Window = [-800 2400];
FPS = 4.68;%[11.18] %  22.39  for mesoscope... don't know...
Clean = true;
DePre = false;
Sort = [];
Smooth = [];
Mirror = false;
Z = false;
FF = false;

%% PASS ARGUMENTS TO CONTROLS
for I=1:2:numel(varargin)
    eval([varargin{I} '= varargin{I+1};']);
end

if isstruct(DFFs)
    [Trials,DFFs] = rip(DFFs,'Super');
end
if isstruct(Trials)
    DFFs = {DFFs};
    Trials = {Trials};
end

%% take out triggered
Trace = [];
Range = frame(Window,FPS);% round(Window ./ (1000./FPS));
Triggers = {'Pre';'Delay';'Stimulus';'Post'};
for I = 1:length(Trials)
    if ~isempty(Smooth)
        if Smooth
            for C = 1:size(DFFs{I},1)
                %             Trace(I,:) = smooth(Trace(I,:),Smooth);
                DFFs{I}(C,:) = gaussfilt(1:length(DFFs{I}(C,:)),DFFs{I}(C,:),Smooth);
                %             Trace(I,:) = medfilt1(Trace(I,:),Smooth,'omitnan','truncate');
            end
        end
    end
    if Z
         DFFs{I} = zscore(DFFs{I}',[],'omitnan')';
    end
    if ~Clean
        TrigOn = destruct(Trials{I},strcat('Trigger.',Triggers{Trigger+1},'.Frame'));
        TempRoi = wind_roi(DFFs{I},TrigOn,'Window',Range);
        
        Trace = cat(1,Trace,nanmean(cat(3,TempRoi{:}),3));
    else
        TrigPre =  destruct(Trials{I},strcat('Trigger.',Triggers{Trigger},'.Frame')) + 3;
        TrigOn = destruct(Trials{I},strcat('Trigger.',Triggers{Trigger+1},'.Frame'))+1;
        %         if Trigger == 1
        TrigOff = destruct(Trials{I},strcat('Trigger.',Triggers{Trigger+2},'.Frame'));
        %         elseif Trigger == 2
        %             TrigOff = destruct(Trials{I},strcat('Trigger.',Triggers{Trigger-1},'.Frame'));
        %         end
        
        TempRoi = wind_roi(DFFs{I},{TrigPre;TrigOn; TrigOff},'Window',Range);
        
        if Mirror
            TempRoi(:,:,destruct(Trials{I},'Block')==0) = -TempRoi(:,:,destruct(Trials{I},'Block')==0);
        end
        
        if DePre == 1
            DP(I) = nanmean(nanmean(TempRoi(1,1:abs(Range(1)),:),2),3);
            TempRoi = TempRoi - nanmean(TempRoi(1,1:abs(Range(1)),:),2);
        end
        if ~FF
            Trace = cat(1,Trace,nanmean(TempRoi,3));
        else
            TempFF = (nanstd(TempRoi,[],3).^ 2)./ nanmean(TempRoi,3);
            Trace = cat(1,Trace,TempFF);
        end
        if length(DePre) == length(Trials) % subtract
            DP(I) = DePre(I);
            Trace(I,:) = Trace(I,:) - DP(I);
        end
    end
end
% Trace = Trace';

%% modify data
if ~isempty(Sort)
    Trace = Trace(Sort,:);
end
% if Smooth > 0
%     for I = 1:size(Trace,1)
% %         Trace(I,:) = smooth(Trace(I,:),Smooth);
%         Trace(I,:) = gaussfilt(1:length(Trace(I,:)),Trace(I,:),Smooth);
% %         Trace(I,:) = medfilt1(Trace(I,:),Smooth,'omitnan','truncate');
%     end
% end
% if DePre
%     if islogical(DePre)
%         for I = 1:size(Trace,1)
%             DP(I) = nanmean(Trace(I,1:abs(Range(1))));
%             Trace(I,:) = Trace(I,:) - DP(I);
%         end
%     else
%         for I = 1:size(Trace,1)
%             DP(I) = DePre(I);
%             Trace(I,:) = Trace(I,:) - DP(I);
%         end
%     end
% else
%     DP = [];
% end
% if ~isempty(Ind)
%     Traces = Traces(Ind,:);
% end
% if ~isempty(Percentile)
%     [~, Sort] = sort((nanmean(Traces(:,abs(Range(1))+1:end),2) - nanmean(Traces(:,1:abs(Range(1))),2)),'ascend');
% %     Trace = Trace(Sort,:); CHANGE THIS BECAUSE IT DOESN'T WORK WITH [IND]
% %     Trace = Trace(prctile(1:size(Trace,1),Percentile):end,:);
% end{
if exist('DP','var')
varargout = {DP};
else
    varargout = {[]};
end

end
%
% function plot_cells(Roi,Range,Task,Light,Sub)
% if ~Sub
%     figure;
% end
% Colours;
% if strcmp(Task,'Discrimination')
%     Colour = Blue;
% elseif strcmp(Task,'Memory')
%     Colour = Red;
% else
%     Colour = Black;
% end
%
% if Average
%     if ~isempty(Light)
%         if Light
%             patches(Roi,CI,[1:size(Roi,2)],'Colour',Colour)
%             hold on;
%             plot(Roi','Color',Colour,'LineWidth',2)
%         else
%             plot(Roi','Color',Colour,'LineWidth',2,'LineStyle','--');
%             hold on;
%         end
%     else
%         patches(Roi,CI,[1:size(Roi,2)],'Colour',Colour)
%         hold on;
%         plot(Roi','Color',Colour,'LineWidth',2)
%
%     end
% else
%     plot(Roi','Color',[0.5 0.5 0.5]);
%     hold on;
%     plot(nanmean(Roi,1),'k','LineWidth',2);
%     CI = repmat(0.2,[size(Roi,2) 1]); % just boundary for ymax
% end
%
% YMax = max(Roi(:)) + max(CI(:));
% YMin = min(Roi(:)) - max(CI(:));
% patch([abs(Range(1))+1 abs(Range(1))+1 abs(Range(1)) abs(Range(1))],...
%     [YMin YMax YMax YMin],'k')
%
% Ax = gca;
% Ax.YLim = [YMin YMax];
% Ax.XTick = [1 abs(Range(1))+1 abs(Range(1))+Range(2)+1];
% Ax.XLim = [1 abs(Range(1))+Range(2)+1];
% Ax.XTickLabel = {strcat(num2str(Window(1)),' ms');'0 ms';strcat('+',num2str(Window(2)),' ms')};
% end
