function distractor_memory(Index,varargin)
% controls for TCD being a rotation encoding dimension by contrasting
% same tasks across rotations
% AND
% tests whether previous stimulus identity is as strong as CCD in
% Discrimination task by comparing different stimuli in

%% READY
FPS = 4.68;
ReTrace = 1; % 0 is using only cross-validated scores, 2 makes already calc'c better due to averaging in not cross-validated bases
ReCalc = false;
Combine = false; % whether i 'classify' only cross-task matched stimuli or not
Balance = true;
ReCentre = false;
BinoCIs = false;
FPS = 4.68;

%% SET
for I=1:2:numel(varargin)
    eval([varargin{I} '= varargin{I+1};']);
end

if ReCalc
    % equate true for main plots
    [Index] = encode(Index,'Window',[-1000 3200],'SoftFocus',true,'Equate',false); % useful for all
    [Index] = encode(Index,'CCD',true,'Window',[-1000 3200],'SoftFocus',true,'Equate',false);
    [Index] = encode(Index,'DCD',true,'Window',[-1000 3200],'SoftFocus',true,'Equate',false);
    
    [Index] = encode(Index,'Stimulus',true,'Window',[-1000 3200],'SoftFocus',true,'Equate',false); % useful for all
    [Index] = encode(Index,'Stimulus',true,'CCD',true,'Window',[-1000 3200],'SoftFocus',true,'Equate',false);
    [Index] = encode(Index,'Stimulus',true,'DCD',true,'Window',[-1000 3200],'SoftFocus',true,'Equate',false);
    Index = rescore(Index,'ReTrace',ReTrace,'ReCentre',ReCentre,'FPS',FPS);

end


% CDs ={'Task';'Cue';'Distractor';'TaskStimulus';'CueStimulus';'DistractorStimulus'};
%
% % fill out Traces
% for S = 1:length(Index)
%     [DFF] = rip(Index(S),'S','DeNaN','Active');
%
%     for D = 1:6
%         try
%             NotNaN = ~isnan(Index(S).(strcat(CDs{D},'Basis'))(2:end));
%             Trace = ([ones(size(DFF{1}(NotNaN,:),2),1) DFF{1}(NotNaN,:)'] ...
%                 * Index(S).(strcat(CDs{D},'Basis'))([true; NotNaN]))';
%             Index(S).(strcat(CDs{D},'Trace'))(isnan(Index(S).(strcat(CDs{D},'Trace')))) = Trace(isnan(Index(S).(strcat(CDs{D},'Trace'))));
%         catch
%             Index(S).(strcat(CDs{D},'Basis')) = [];
%             Index(S).(strcat(CDs{D},'Trace')) = [];
%         end
%     end
% end
%
% % CDs ={'Task';'Cue';'Distractor'};
%
% %% GO
% %% retrace
% if ReTrace > 0
%     for S = 1:length(Index)
%         load(Index(S).Name,'Trial');
%
%         if ReTrace == 3
%             [DFF] = rip(Index(S),'S','DeNaN','Active');
%
%         end
%
%         for D = 1:6
%             try
%                 if ReTrace == 3
%                     NotNaN = ~isnan(Index(S).(strcat(CDs{D},'Basis'))(2:end));
%                     Index(S).(strcat(CDs{D},'Trace')) = ([ones(size(DFF{1}(NotNaN,:),2),1) DFF{1}(NotNaN,:)'] ...
%                         * Index(S).(strcat(CDs{D},'Basis'))([true; NotNaN]))';
%
%                 end
%
%                 Trig{1} = destruct(Trial,'Trigger.Delay.Frame');
%                 Trig{2} = destruct(Trial,'Trigger.Stimulus.Frame');
%                 Trig{3} = destruct(Trial,'Trigger.Post.Frame');
%
%                 Temp = wind_roi(Index(S).(strcat(CDs{D},'Trace')),{Trig{1+(D>3)};Trig{2+(D>3)}},'Window',frame([0 swap([3200,2000],(D > 3)+1)],FPS));
%                 Temp = -squeeze(nanmean(Temp,2));
%
%                 for T = 1:length(Trial)
%                     if ReTrace > 1
%                         % FILLS OUT ALL SCORES! FOR ALL TRIALS!
%                         Index(S).(strcat(CDs{D},'Score'))(T) = Temp(T);
%                     elseif ReTrace == 1
%                         % FILLS OUT ONLY NAN SCORES
%                         if isnan(Index(S).(strcat(CDs{D},'Score'))(T))
%                             Index(S).(strcat(CDs{D},'Score'))(T) = Temp(T);
%                         end
%                     end
%
%                     if ReCentre && (D == 2 || D == 5)
%                         Index(S).(strcat('Recentred',CDs{D},'Score')) = ...
%                             Index(S).(strcat(CDs{D},'Score')) - nanmean(Index(S).(strcat(CDs{D},'Score')));
%                     end
%                 end
%             end
%         end
%     end
% end

try
    for I = 1:length(Index)
        Index(I).CueStimulusScore = -Index(I).CueStimulusScore;
    end
end

%% reclassify
CDs ={'Task';'Cue';swap({'Cue';'RecentredCue'},ReCentre+1);'Distractor'};

for S = 1:length(Index)
    load(Index(S).Name,'Trial');
    
    for Epoch = 1:2
        for D = 1:4 % now also includes CDCUE for distractors
            % combines vs not
            % task: either all WM and all dist of combob or only WM(A) and dist (=super)
            % cue: either all cues of a combob (=context) or only of the cue which is matched (=super + WM)
            % DB: either both rotations (=rotext) or only the matched distractor (=super + Disc)
            % DB: either both rotations (=rotext) or only the matched distractor (=super + Disc)
            CombobDB = Trial(and(Index(S).Combobulation,destruct(Trial,'Task')==swap([1 1 2 2],D))).DB;
            
            [~,Selection] = selector(Trial,'NoReset','HasFrames','Nignore',swap({'Post','Cue'},Epoch));
            
            Selection = and(Selection,or(destruct(Trial,'ResponseType') == 1,destruct(Trial,'ResponseType') == 4));
            
            % restrict the DB's for [Combine 1]
            if D == 1
                % all WM of that DB and all Disc of the other DB
                Selection = and(Selection,or(and(destruct(Trial,'DB')==CombobDB,destruct(Trial,'Task')==1),...
                    and(destruct(Trial,'DB')~=CombobDB,destruct(Trial,'Task')==2)));
                % restrict the tasks
            elseif D == 2
                Selection = and(Selection,destruct(Trial,'Task')==1);
            else
                Selection = and(Selection,destruct(Trial,'Task')==2);
            end
            
            % restrict the DB for [~Combine 3,4] and [either 2]
            if D == 2 || (and(~Combine,Epoch==2) && D>2)
                Selection = and(Selection,destruct(Trial,'DB')==CombobDB);
            end
            
            % restrict the WM block for [~Combine 1,2]
            if ~Combine && D < 3
                Selection(and(destruct(Trial,'Block') ~= swap([0 1],(CombobDB == 15)+1),destruct(Trial,'Task')==1)) = false;
                %                 should be same as Index(I).Combobulation now
            end
            
            try
                if Balance
                    Class(Epoch,S,D) = ((sum(Index(S).(strcat(CDs{D},swap({'';'Stimulus'},Epoch),'Score'))(and(Selection,destruct(Trial,swap({'Task';'Block';'DB';'DB'},D))==swap([1, 1, -15, 15],D))) < 0) +...
                        sum(Index(S).(strcat(CDs{D},swap({'';'Stimulus'},Epoch),'Score'))(and(Selection,destruct(Trial,swap({'Task';'Block';'DB';'DB'},D))==swap([2, 0, +15, -15],D))) > 0)) ...
                        /...
                        (sum(~isnan(Index(S).(strcat(CDs{D},swap({'';'Stimulus'},Epoch),'Score'))(and(Selection,destruct(Trial,swap({'Task';'Block';'DB';'DB'},D))==swap([1, 1, -15, 15],D))))) + ...
                        sum(~isnan(Index(S).(strcat(CDs{D},swap({'';'Stimulus'},Epoch),'Score'))(and(Selection,destruct(Trial,swap({'Task';'Block';'DB';'DB'},D))==swap([2, 0, +15, -15],D)))))));
                    
                else
                    TempClass = [sum(Index(S).(strcat(CDs{D},swap({'';'Stimulus'},Epoch),'Score'))(and(Selection,destruct(Trial,swap({'Task';'Block';'DB';'DB'},D))==swap([1, 1, 15, 15],D))) < 0) ...
                        / sum(~isnan(Index(S).(strcat(CDs{D},swap({'';'Stimulus'},Epoch),'Score'))(and(Selection,destruct(Trial,swap({'Task';'Block';'DB';'DB'},D))==swap([1, 1, 15, 15],D)))))...
                        ...
                        sum(Index(S).(strcat(CDs{D},swap({'';'Stimulus'},Epoch),'Score'))(and(Selection,destruct(Trial,swap({'Task';'Block';'DB';'DB'},D))==swap([2, 0, -15, -15],D))) > 0) ...
                        / sum(~isnan(Index(S).(strcat(CDs{D},swap({'';'Stimulus'},Epoch),'Score'))(and(Selection,destruct(Trial,swap({'Task';'Block';'DB';'DB'},D))==swap([2, 0, -15, -15],D)))))...
                        ];
                    Class(Epoch,S,D) = nansum(TempClass) / sum(~isnan(TempClass));
                end
                
                Classified(Epoch,S,D,1) = sum(Index(S).(strcat(CDs{D},swap({'';'Stimulus'},Epoch),'Score'))(and(Selection,destruct(Trial,swap({'Task';'Block';'DB';'DB'},D))==swap([1, 1, 15, 15],D))) < 0) +...
                    sum(Index(S).(strcat(CDs{D},swap({'';'Stimulus'},Epoch),'Score'))(and(Selection,destruct(Trial,swap({'Task';'Block';'DB';'DB'},D))==swap([2, 0, -15, -15],D))) > 0);
                Classified(Epoch,S,D,2) = sum(~isnan(Index(S).(strcat(CDs{D},swap({'';'Stimulus'},Epoch),'Score'))(and(Selection,destruct(Trial,swap({'Task';'Block';'DB';'DB'},D))==swap([1, 1, 15, 15],D))))) + ...
                    sum(~isnan(Index(S).(strcat(CDs{D},swap({'';'Stimulus'},Epoch),'Score'))(and(Selection,destruct(Trial,swap({'Task';'Block';'DB';'DB'},D))==swap([2, 0, -15, -15],D)))));
                
            catch
                Class(Epoch,S,D) = nan;
                Classified(Epoch,S,D,1:2) = nan(2,1);
                
            end
        end
    end
end

%% plot just CCD cues and distractors
clearvars CIs
for Epoch = 1:2
    for D = 1:3
        if BinoCIs
            [Mus(Epoch,D), CIs(Epoch,D,:)] = binofit(nansum(squeeze(Classified(Epoch,:,D,1))),nansum(squeeze(Classified(Epoch,:,D,2))));
        else
            [Mus(Epoch,D), CIs(Epoch,D,:)] = normfit(squeeze(Class(Epoch,~isnan(Class(Epoch,:,D)),D)));
        end
    end
end

Colours;
figure;
hold on;


for Epoch = 1:2
    
    plot([1:3],Mus(Epoch,:)','LineStyle','none','Marker','o','MarkerFaceColor',White,...
        'LineWidth',2,'color',swap({Black;(Green+Blue) ./2},Epoch));
    
end
% legend('Delay','Stimulus');

for Epoch = 1:2
    if BinoCIs
        errorbar([1:3],Mus(Epoch,:)',...
            Mus(Epoch,:)'-CIs(Epoch,:,1)',Mus(Epoch,:)'-CIs(Epoch,:,2)','color',swap({Black;(Green+Blue) ./2},Epoch),'LineWidth',2);
    else
        errorbar([1:3],Mus(Epoch,:)',...
            CIs(Epoch,:,1)','color',swap({Black;(Green+Blue) ./2},Epoch),'LineWidth',2);
    end
    
end


axis([0.75 3.25 0.4 1]);
line([0.75 3.25],[0.5 0.5],'LineStyle','--','color',Black,'LineWidth',1);
Ax = gca;
Ax.XTick = [1 2 3];
Ax.XTickLabel = {'t-TCD';'c-CCD';'d-CCD'};
Ax.YTick = sort([0.4 0.5 [Mus(1,:) Mus(2,:)] 1]);
ylabel('Classification accuracy (%)');

%% real plot for later
%
% %% plot
% Colours;
% figure;
% hold on;
%
% % for Epoch = 1:2
% %     for D = 1:4
% %         [Mus(Epoch,D), CIs(Epoch,D,:)] = binofit(squeeze(Class(Epoch,:,D)));
% %     end
% % end
%
% for Epoch = 1:2
% %     errobar(squeeze(nanmean(Class(Epoch,:,:),1)),CIs(Epoch,:,1), CIs(Epoch,:,2),'color',swap({Black;(Green+Blue) ./2},Epoch));
%     plot(squeeze(nanmean(Class(Epoch,:,:),2)),'color',swap({Black;(Green+Blue) ./2},Epoch));
% end
%
% % plot([zeros(length(WMCD),1) ones(length(WMCD),1)]', [WMCD'; DBCD'],'color',Black,'Marker','o','MarkerSize',5,'MarkerFaceColor',White,'MarkerEdgeColor',Black,'LineWidth',2);
% hold on;
% if Style == 1
%     plot([zeros(length(TCD),1)+2 ones(length(TCD),1)+2]', [CCD'; DCD'],'color',Black,'Marker','o','MarkerSize',5,'MarkerFaceColor',White,'MarkerEdgeColor',Black,'LineWidth',1);
%     Medians = [nanmedian(TCD) nanmedian(DBCD) nanmedian(CCD) nanmedian(DCD)];
%     for I = 1:length(Medians)
%         line([-1.15+I -0.85+I],[Medians(I) Medians(I)],'color',Black,'LineWidth',3)
%     end
% else
%     Datas = {TCD; DBCD; CCD; DCD};
%     for Column = 1:4
%         [Mean{Column},~,CI{Column}] = normfit(Datas{Column}(~isnan(Datas{Column})));
%         errorbar(-1+Column,Mean{Column},Mean{Column}-CI{Column}(1),Mean{Column}-CI{Column}(2),'LineWidth',2,'color',Black,'Marker','o','MarkerFaceColor',Black,'MarkerSize',5);
%     end
% end
%
% axis([-0.75 3.25 (0+(Style-1).*0.5) 1])
% Ax = gca;
% Ax.XTick = [0 1 2 3];
% Ax.XTickLabel = {'WMCD';'DBCD';'CCD';'DCD'};
% Ax.YTick = [0 0.5 1];
% Ax.YTickLabel = {'0%';'50%';'100%'};
% ylabel('Classification accuracy');
%
% % %% dynamics plot
% % nanmean()


