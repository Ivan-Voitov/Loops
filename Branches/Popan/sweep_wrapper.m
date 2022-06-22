function [Sweep,Explanations] = sweep_wrapper(Input,varargin)
GreyLine = cell(1,3);
RedLine = cell(1,3);

ReCalc = true;
AreaSplit = true;
Equate = true;
Smooth = 0;

%% PASS ARGUMENTS TO CONTROLS
for I=1:2:numel(varargin)
    eval([varargin{I} '= varargin{I+1};']);
end

%% recalc
if ReCalc
    [Input] = encode(Input,'SoftFocus',true,'Smooth',Smooth,'Equate',Equate);
    [InputTrain] = encode(Input,'SoftFocus',true,'Folds',1,'Smooth',Smooth,'Equate',Equate);
    [Input] = encode(Input,'SoftFocus',true,'CCD',true,'Smooth',Smooth,'Equate',Equate);
    [InputTrain] = encode(InputTrain,'SoftFocus',true,'CCD',true,'Folds',1,'Smooth',Smooth,'Equate',Equate);
    [Input] = encode(Input,'SoftFocus',true,'CCD',true,'Stim',true,'Smooth',Smooth,'Equate',Equate);
    [InputTrain] = encode(InputTrain,'SoftFocus',true,'CCD',true,'Stim',true,'Folds',1,'Smooth',Smooth,'Equate',Equate);  
    GreyLine = {cat(1,InputTrain.TaskClass);cat(1,InputTrain.CueClass);cat(1,InputTrain.CueStimulusClass)};
    RedLine = {cat(1,Input.TaskClass);cat(1,Input.CueClass);cat(1,Input.CueStimulusClass)};
end

%% get data
if isstruct(Input)
    % SoftFocus <> Focus
    [Sweep{1}, Explanations{1}] = sweep_decoding(Input,'CCD',false,'Stim',false,...
        'Focus',true,'Equate',Equate,'Smooth',Smooth,...
        'SweepCells',false,'SweepExclusion',true,'SweepRaw',true,'DEBUG',false);
    [Sweep{2}, Explanations{2}] = sweep_decoding(Input,'CCD',true,'Stim',false,...
        'Focus',true,'Equate',Equate,'Smooth',Smooth,...
        'SweepCells',false,'SweepExclusion',true,'SweepRaw',true,'DEBUG',false);
    [Sweep{3}, Explanations{3}] = sweep_decoding(Input,'CCD',true,'Stim',true,...
        'Focus',true,'Equate',Equate,'Smooth',Smooth,...
        'SweepCells',false,'SweepExclusion',true,'SweepRaw',true,'DEBUG',false);

%     %DEBUG
%     figure;Colours;plot(nanmean(Sweep{2}.Raw(:,[1 10 20]),1),'color',Orange);
%     hold on;plot(nanmean(Sweep{3}.Raw(:,[1 10 20]),1),'color',Silver);
%     plot(nanmean(Sweep{2}.Exclude(:,[1 50 100]),1),'color',Orange);
%     plot(nanmean(Sweep{3}.Exclude(:,[1 50 100]),1),'color',Silver);
%     Ax=  gca; axis([0.75 3.25 0.4 1])
%     %
    if isempty(RedLine{1})
        RedLine{Fig}{1} = cat(1,Input.Class);
        RedLine{Fig}{2} = cat(1,Input.CueClass);
        RedLine{Fig}{3} = cat(1,Input.CueStimulusClass);
    end
elseif iscell(Input)
    Sweep{1} = Input{1}{1};
    Explanations{1} = Input{2}{1};
    Sweep{2} = Input{1}{2};
    Explanations{2} = Input{2}{2};
    Sweep{3} = Input{1}{3};
    Explanations{3} = Input{2}{3};
end

%% plot
Colours;
%define some index here
if ~AreaSplit
    AreaIndex = ones(size(Sweep{1}.Cells,1),1);
else
    AreaIndex = destruct(Input,'Area');
end

for Area = 1:1+AreaSplit
    
    
    for Fig = 1:3 % TCD / CCD
        figure;
        % ToPlot1= {Sw  eep.Cells(destruct(Meso,'Area')==Area,:);Sweep.Raw(destruct(Meso,'Area')==Area,:)};
        % ToPlot2 = {Explanations.Cells(destruct(Meso,'Area')==Area,:);Explanations.Raw(destruct(Meso,'Area')==Area,:)};
        ToPlot1= {Sweep{Fig}.Cells(AreaIndex==Area,:);Sweep{Fig}.Raw(AreaIndex==Area,:);Sweep{Fig}.Exclude(AreaIndex==Area,:)};
        ToPlot2 = {Explanations{Fig}.Cells(AreaIndex==Area,:);Explanations{Fig}.Raw(AreaIndex==Area,:);Explanations{Fig}.Exclude(AreaIndex==Area,:)};
%         ToPlot1= {Sweep{Fig}.Cells;Sweep{Fig}.Raw;Sweep{Fig}.Exclude};
%         ToPlot2 = {Explanations{Fig}.Cells;Explanations{Fig}.Raw;Explanations{Fig}.Exclude};

        
        Y1 = {'Classification accuracy'};
        X = {'Cells';'PCs';'PCs'};
        Y2 = {'Variance explained'};
        for P = 1:length(ToPlot1)
            subplot(2,length(ToPlot1),P);
            % sweep / class
            for II = 1:size(ToPlot1{P},2)
                Temp = fitdist(ToPlot1{P}(:,II),'normal');
                Temp = paramci(Temp);
                CI(II,:) = Temp(:,1);
            end
            
            try
                Temp = fitdist(RedLine{Fig}(AreaIndex==Area),'normal');
                Temp = paramci(Temp);
                
                %     (std(RedLine{Fig})) / (sqrt(length(RedLine{Fig})));
                fill([swaparoo([100 20 100],P) swaparoo([100 20 100],P) 1 1],[Temp(1,1) Temp(2,1) Temp(2,1) Temp(1,1)],Red,'EdgeColor','none','FaceAlpha',0.2);
                hold on;
                line([1 swaparoo([100 20 100],P)],[round(nanmean(RedLine{Fig}(AreaIndex==Area)),2) round(nanmean(RedLine{Fig}(AreaIndex==Area)),2)],'LineWidth',1,'color',Red);
            end
            
            patches([],CI,1:swaparoo([100 20 100],P),'Colour',[0.8 0.8 0.8],'FaceAlpha',1); hold on

            if ~isempty(GreyLine{Fig})
                Temp = fitdist(GreyLine{Fig}(AreaIndex==Area),'normal');
                Temp = paramci(Temp);
                %     (std(RedLine{Fig})) / (sqrt(length(RedLine{Fig})));
                fill([swaparoo([100 20 100],P) swaparoo([100 20 100],P) 1 1],[Temp(1,1) Temp(2,1) Temp(2,1) Temp(1,1)],Grey,'EdgeColor','none','FaceAlpha',0.2);
                hold on;
                patches([],CI,1:swaparoo([100 20 100],P),'Colour',[0.8 0.8 0.8],'FaceAlpha',1); hold on
                line([1 swaparoo([100 20 100],P)],[round(nanmean(GreyLine{Fig}(AreaIndex==Area)),2) round(nanmean(GreyLine{Fig}(AreaIndex==Area)),2)],'LineWidth',1,'color',Grey);
            end
            
            
            plot(nanmean(ToPlot1{P},1),'LineWidth',2,'color','k');
            
            Ax = gca;
            try
                Ax.YTick = [0.5 round(nanmean(RedLine{Fig}(AreaIndex==Area)),2) 1];
            catch
                Ax.YTick = [0.5 1];
            end
            Ax.YLim = [0.5 1];
            Ax.XLim = [1 swaparoo([100 20 100],P)];
            %     title(Titles{P});
            ylabel(Y1);
            xlabel(X{P});
            Ax.XTick = [1 swaparoo([100 20 100],P)/2 swaparoo([100 20 100],P)];
            try
            Ax.YTickLabel = {strcat(num2str(50),'%'); strcat(num2str(round(nanmean(RedLine{Fig}(AreaIndex==Area))*100)),'%'); strcat(num2str(100),'%')};
            catch
                            Ax.YTickLabel = {strcat(num2str(50),'%'); strcat(num2str(100),'%')};
            end
            subplot(2,length(ToPlot2),P + length(ToPlot1));
            % explained
            for II = 1:size(ToPlot2{P},2)
                Temp = fitdist(ToPlot2{P}(:,II),'normal');
                Temp = paramci(Temp);
                CI(II,:) = Temp(:,1);
            end
            patches([],CI,1:swaparoo([100 20 100],P),'Colour',Black); hold on
            plot(nanmean(ToPlot2{P},1),'LineWidth',2,'color','k');
            
            Ax = gca;
            Ax.YTick = [0 100];
            Ax.YLim = [0 100];
            Ax.XLim = [1 swaparoo([100 20 100],P)];
            %     line([1 20+(80*(P==1))],[round(nanmean(RedLine{Fig}),2) round(nanmean(RedLine{Fig}),2)],'LineWidth',3,'color',Red);
            %     title(Titles{P});
            ylabel(Y2);
            xlabel(X{P});
            Ax.XTick = [1 swaparoo([100 20 100],P)/2 swaparoo([100 20 100],P)];
            Ax.YTickLabel = {strcat(num2str(0),'%'); strcat(num2str(100),'%')};
        end
    end
end