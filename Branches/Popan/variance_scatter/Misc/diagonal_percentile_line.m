function [LowLine,HighLine] = diagonal_percentile_line(Data,Blocks)

B = 1;
for Block = Blocks:Blocks:100
    Lower = prctile(Data(:,3),Block-Blocks);
    Upper = prctile(Data(:,3),Block);
    % define the cells in this range
    Dindex(find(and(Data(:,3) >= Lower,Data(:,3) <= Upper))) = B;
    % what is their spread?
    Spread =  Data(Dindex==B,1) - Data(Dindex==B,2);
    [Val] = sort(Spread);
    LowVal = Val(round(0.05*length(Spread))) ./ 2;
    HighVal = Val(round(0.95*length(Spread))) ./ 2;
    LowLine(B,:) = [(((Upper + Lower) / 4) + HighVal) (((Upper + Lower) / 4) - HighVal)];
    HighLine(B,:) = [(((Upper + Lower) / 4) + LowVal) (((Upper + Lower) / 4) - LowVal)];
    B = B + 1;
end