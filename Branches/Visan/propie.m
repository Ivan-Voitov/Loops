function propie(Index)
% PIE
for I = 1:length(Index)
    Response(I,1,Index(I).Area) = sum(Index(I).DelayResponsive);
    Response(I,2,Index(I).Area) = sum(Index(I).StimulusResponsive);
    Response(I,3,Index(I).Area) = Index(I).CellCount - Response(I,2) - Response(I,1);
end
figure;
subplot(1,2,1);
pie(sum(Response(:,:,1),1),{'DelayResponsive';'StimulusResponsive';'Non-triggerable'})
title('Area M2');
subplot(1,2,2);
pie(sum(Response(:,:,2),1),{'DelayResponsive';'StimulusResponsive';'Non-triggerable'})
title('Area AM');
