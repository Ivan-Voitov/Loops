function cell_numbers_table(Meso)




for Session = 1:length(Meso)
    Temp = load(Meso(Session).Name,'MaskNumber');
    MaskNumber(Session) = Temp.MaskNumber;
    ProcessedNumber(Session) = Meso(Session).CellCount;
    ActiveNumber(Session) = sum(Meso(Session).Active);
    UsedNumber(Session) = sum(~isnan(Meso(Session).Basis)) - 1;
end

Numbers = cat(1,MaskNumber,ProcessedNumber,ActiveNumber,UsedNumber);
for K = 1:size(Numbers,1)
    [Mean(K),~,CI(K,:)] = normfit(Numbers(K,:));
end
MaskNumber = [CI(1,1) Mean(1) CI(1,2)];
ProcessedNumber = [CI(2,1) Mean(2) CI(2,2)];
ActiveNumber = [CI(3,1) Mean(3) CI(3,2)];
UsedNumber = [CI(4,1) Mean(4) CI(4,2)];

disp(strcat({'number of masks was '},num2str(MaskNumber(2)),'+/-',num2str(MaskNumber(3)-MaskNumber(2))))
disp(strcat({'number of Active cells was '},num2str(ActiveNumber(2)),'+/-',num2str(ActiveNumber(3)-ActiveNumber(2))))