function Explanations = intrinsic_dimensionality(Index,varargin)
%% READY 
FPS = 4.68;
NumComponents = 20;
Equate = true;

%% SET 
for I=1:2:numel(varargin)
    eval([varargin{I} '= varargin{I+1};']);
end

[DFFs,~] = rip(Index,'S','DeNaN','Active');

% % seems like the right thing to do
% DFFs = soft_focus(DFFs,Index);

%% GO
rng(111);

for Session = 1:length(Index)
    
    Loaded = load(Index(Session).Name,'Trial');
    
    if Equate
        for Condition = 1:6
            if Condition < 3 % TASK
                [CountTrial] = selector(Loaded.Trial,Index(Session).Combobulation,'NoReset','HasFrames','Post','Nignore');
                Number(Condition) = length(CountTrial(destruct(CountTrial,'Task')==swap([2,1],Condition)));
            else
                CountTrial = Loaded.Trial;
                TempDB = CountTrial(and(Index(Session).Combobulation,destruct(CountTrial,'Task')==(1+(Condition<5)))).DB;
                CountTrial = CountTrial(and(destruct(CountTrial,'DB')==TempDB,destruct(CountTrial,'Task')==(1+(Condition<5))));
                CountTrial = selector(CountTrial,'NoReset','HasFrames','Nignore','Post');
                Number(Condition) = length(CountTrial(destruct(CountTrial,'ResponseType')==swap([1;2],Condition-(2*((Condition>4)+1)))));
                
            end
        end
    end
        
    for Condition = 1:6
        if Condition < 3 % TASK
            % basically super
            Trial = selector(Loaded.Trial,Index(Session).Combobulation,'NoReset','HasFrames','Post','Nignore');
            Trial = Trial(destruct(Trial,'Task')==swap([2,1],Condition));
            
            if Equate
                [A,B] = min(Number(1:2));
                if Condition ~= B % + 2
                    Trial = Trial(randperm(length(Trial)));
%                     Trial = Trial(end:-1:1);
                    Trial = Trial(1:A);
                end
            end
        else % CR/FA in either task
            % basically context
            Trial = Loaded.Trial;
            TempDB = Trial(and(Index(Session).Combobulation,destruct(Trial,'Task')==(1+(Condition<5)))).DB;
            Trial = Trial(and(destruct(Trial,'DB')==TempDB,destruct(Trial,'Task')==(1+(Condition<5))));
            Trial = selector(Trial,'NoReset','HasFrames','Nignore','Post');
            Trial = Trial(destruct(Trial,'ResponseType')==swap([1;2],Condition-(2*((Condition>4)+1))));
            
            if Equate
                [A,~] = min(Number(3+((Condition>4)*2):4+((Condition>4)*2)));
                if Condition == 3 || Condition == 5 %(CR)
                    Trial = Trial(randperm(length(Trial)));
%                     Trial = Trial(end:-1:1);
                    Trial = Trial(1:A);
                end
            end
        end
        
        for Trigger = 1:2
            TempActivities = [];
            
            Triggers = [destruct(Trial,'Trigger.Delay.Frame'), ...
                destruct(Trial,'Trigger.Stimulus.Frame'), ...
                destruct(Trial,'Trigger.Post.Frame')];
            try
                Activities = wind_roi(DFFs{Session},{Triggers(:,0+Trigger); Triggers(:,1+Trigger)},...
                    'Window',frame([0 swap([3200 2000],Trigger)],FPS));
                for K = 1:size(Activities,3)
                    TempActivities = cat(2,TempActivities,Activities(:,:,K));
                end
                
                TempRemove = all(isnan(TempActivities));
                [~,~,~,~,TempExplanations] = pca(TempActivities(:,~TempRemove) ,'numcomponents',NumComponents,'Centered',true);
                Explanations(Session,Condition,Trigger,1:NumComponents) = TempExplanations(1:NumComponents);
            catch
                Explanations(Session,Condition,Trigger,1:NumComponents) = nan;
            end
        end
    end
end
% clean
Remove = false(length(Index),1);
for S = 1:length(Index)
   if any(isnan(straighten(Explanations(S,:,:,:)))) 
       Remove(S) = true;
   end
end
Explanations(Remove,:,:,:) =[];

%% PLOT
Colours;
figure;
suptitle('Intrinsic dimensionality')
for Trigger = 1:2
    for Condition = 1:3
        subplot(2,3,Condition+((Trigger-1)*3))
        
        % this bit only for legend
        plot(nanmean(squeeze(Explanations(:,((Condition-1)*2)+1,Trigger,1:20)))','color',swap({Blue; Grey},(Condition>1)+1),'LineWidth',2);
        hold on;
        plot(nanmean(squeeze(Explanations(:,((Condition-1)*2)+2,Trigger,1:20)))','color',swap({Red; Black},(Condition>1)+1),'LineWidth',2);
        
        P(Trigger,Condition) = signrank(Explanations(:,((Condition-1)*2)+1,Trigger,1),  Explanations(:,((Condition-1)*2)+2,Trigger,1));
        text(10,15,num2str(P(Trigger,Condition)));
        
%         plot((squeeze(Explanations(:,((Condition-1)*2)+1,Trigger,1:20)))','color',swap({Blue; Black},(Condition>1)+1),'LineStyle',':');
%         plot((squeeze(Explanations(:,((Condition-1)*2)+2,Trigger,1:20)))','color',swap({Red; Red},(Condition>1)+1),'LineStyle',':');
        
        for PC = 1:size(nanmean(squeeze(Explanations(:,((Condition-1)*2)+1,Trigger,1:20))),2)
            [Mu1(PC), CI1(PC)] = normfit(squeeze(Explanations(:,((Condition-1)*2)+1,Trigger,PC)));
            [Mu2(PC), CI2(PC)] = normfit(squeeze(Explanations(:,((Condition-1)*2)+2,Trigger,PC)));
        end

        plot(Mu1,'color',swap({Blue; Grey},(Condition>1)+1),'LineWidth',2);
        patches(Mu1,CI1,[1:20],'Colour',swap({Blue; Grey},(Condition>1)+1));
        plot(Mu2,'color',swap({Red; Black},(Condition>1)+1),'LineWidth',2);
        patches(Mu2,CI2,[1:20],'Colour',swap({Red; Black},(Condition>1)+1));

        axis([0 21 0 40]);
        if Trigger == 1 && Condition == 1
            ylabel({'Delay activity';'variance explained'});
        elseif Trigger == 2 && Condition == 1
            ylabel({'Stimulus activity';'variance explained'});
        end
        if Condition == 1
            legend({'Discrimination';'WM'});
        elseif Condition > 1
             legend({'pre-CR';'pre-FA'});
        end
        if Trigger == 2
            xlabel('PC');
        end
        if Condition == 2
           text(5,30,'Discrimination task'); 
        elseif Condition == 3
                       text(5,30,'WM task'); 
        end
        
    end
end



% %%
% plot((squeeze(Explanations(:,1,1:20)))','color',Blue,'LineStyle',':');
% hold on;
% plot((squeeze(Explanations(:,2,1:20)))','color',Red,'LineStyle',':');
% plot(nanmean(squeeze(Explanations(:,1,1:20)))','color',Blue,'LineWidth',2);
% plot(nanmean(squeeze(Explanations(:,2,1:20)))','color',Red,'LineWidth',2);
% axis([0 21 0 40])
% subplot(1,2,2)
% plot((squeeze(Explanations(:,3,1:20)))','color',Purple,'LineStyle',':');
% hold on;
% plot((squeeze(Explanations(:,4,1:20)))','color',Brown,'LineStyle',':');
% plot(nanmean(squeeze(Explanations(:,3,1:20)))','color',Purple,'LineWidth',2);
% plot(nanmean(squeeze(Explanations(:,4,1:20)))','color',Brown,'LineWidth',2);
% axis([0 21 0 40])
