function scatter_pretty(Activity,Correlation,CentralCorrelation)
Colours;
figure;

if ~isempty(Activity)
    subplot(2,2,[1 3]);
    [~, ~] = tight_fig(1, 1, 0.02, [0.1 0.1], [0.1 0.1],1,600,600);
    scatter_sym((Activity.Normal),(Activity.Shifted),'Labels',{'Discrimination';'Memory'},'Colours',{Blue;Red});
    axis([(0.007) (0.7) (0.007) (0.7)])
    
    [~, ~] = tight_fig(1, 1, 0.02, [0.1 0.1], [0.1 0.1],1,600,600);
    scatter_sym(log(Activity.Normal),log(Activity.Shifted),'Labels',{'Discrimination';'Memory'},'Colours',{Blue;Red});
    title('Average delay activity per task');
end

% subplot(4,2,[5 7]);
% scatter_sym(Correlation.Normal,Correlation.Shifted,'Labels',{'Discrimination';'Memory'},'Colours',{Blue;Red});
% title('Pairwise noise correlations per task');
%%
% if ~isempty(Correlation)
%     % Correlation.ControlMeanFR2 = cat(1,Correlation.ControlMeanFR(:,1),Correlation.ControlMeanFR(:,2));
%     % Correlation.Control2 = cat(1,Correlation.Control(:,1),Correlation.Control(:,2));
% %     subplot(2,1,1);
% %     scatter_asym([Correlation.MeanFR(:,1) Correlation.Normal(:,1)],[Correlation.ShuffledMeanFR(:,1) Correlation.Shuffled(:,1)],'Colour',Blue,'Axis',[0 0.20 -0.2 0.35]);
% %     title('Discrimination task correlations vs average firing rate');
% %     Ax = gca;
% %     Ax.YTick = [-0.18 0.4];
% %     Ax.YLim = [-0.18 0.4];
% %     Ax.YTickLabel = [-0.18 0.4];
% %     Ax.XTick = [0.007 0.5];
% %     Ax.XLim = [0.007 0.5];
% %     Ax.XTickLabel = [0.007 0.5];
% %     subplot(2,1,2);
%     scatter_asym([(Correlation.MeanFR(:,2)) Correlation.Normal(:,2)],[(Correlation.MeanFR(:,1)) Correlation.Normal(:,1)],'Colour',Red,'Axis',[0 0.25 -0.2 0.35]);
%     title('Memory task  task correlations vs average firing rate');
%     Ax = gca;
%     Ax.YTick = [-0.25 0.4];
%     Ax.YLim = [-0.25 0.4];
%     Ax.YTickLabel = [-0.25 0.4];
%     Ax.XTick = [];
%     Ax.XLim = [0.04 0.8];
% %     Ax.XLim = [-2.6 -0.26];
% %     Ax.XTickLabel = [0.007 0.5];
% end
%%
% subplot(4,2,[6 8])
% scatter_sym(CentralCorrelation.Normal,CentralCorrelation.Shifted,'Labels',{'Discrimination';'Memory'},'Colours',{Blue;Red});
% title('Pairwise noise correlations of activitiy-matched pairs per task');
% %
% figure;
% % supplement to supplement?
% label_by_label(Activity.Odd,[],{'Odd Discrimination Activity';'Odd Memory Activity'});
% label_by_label(Activity.CrossedMemory,[],{'Odd Discrimination Activity';'Even Discrimination Activity'});
% label_by_label(Activity.CrossedDiscrimination,[],{'Odd Memory Activity';'Even Memory Activity'});

end
