function [LowLine,HighLine] = percentile_line(Data,Blocks,Diagonal)
B = 1;
for Block = Blocks:Blocks:100
    % define the cells in this range
    % what is their spread?
    if Diagonal
        Lower = prctile(Data(:,3),Block-Blocks);
        Upper = prctile(Data(:,3),Block);
        Dindex(find(and(Data(:,3) >= Lower,Data(:,3) <= Upper))) = B;
        Spread =  Data(Dindex==B,1) - Data(Dindex==B,2);
    else % this is -- X range Y values
        Lower = prctile(Data(:,1),Block-Blocks);
        Upper = prctile(Data(:,1),Block);
        Dindex(find(and(Data(:,1) >= Lower,Data(:,1) <= Upper))) = B;
        Spread =  Data(Dindex==B,2);
    end

    [Val] = sort(Spread);
    try
           LowVal = Val(round(0.025*length(Spread))) ./ (Diagonal+1);
    catch
        LowVal = Val(1);
    end
    HighVal = Val(round(0.975*length(Spread))) ./ (Diagonal+1);
    if Diagonal
    LowLine(B,:) = [(((Upper + Lower) / 4) + HighVal) (((Upper + Lower) / 4) - HighVal)];
    HighLine(B,:) = [(((Upper + Lower) / 4) + LowVal) (((Upper + Lower) / 4) - LowVal)];
    else
            LowLine(B,:) = [((Upper + Lower) / 2) LowVal];
            HighLine(B,:) = [((Upper + Lower) / 2) HighVal];

    end
    B = B + 1;
end