function [ShiftedLabels] = shift_labels(Labels,varargin)
%
if strcmp(varargin,'Random')
    Mode = 2;
else
    Mode = 1;
end

%
% ShiftedLabels = logical(Labels - 1);
% ShiftedLabels = Labels-1;
% ShiftedLabels = Labels;

% correct for nans
% if sum(isnan(Labels)) ~= 0
%     TempLabels = Labels;
%     for I = 2:length(TempLabels)
%         if isnan(TempLabels(I))
%             TempLabels(I) = TempLabels(I-1);
%         end
%     end
% else
%     TempLabels = Labels;
% end

if Mode == 1 % half-way through next
    [Ind,~,Value] = find(diff(TempLabels));
    Ind(end+1) = length(TempLabels);
    Value(end+1) = -sign(Value(end));
    I = 0;
    II = 1;
    for Block = 1:length(Ind)
        III = round((Ind(Block)-I)/2)+I;
        ShiftedLabels(II:III) = (Value(Block) == 1);%-1 > false, +1 > true
        II = III+1;
        I = Ind(Block);
    end
    ShiftedLabels = double(ShiftedLabels)+1;

elseif Mode == 2 % random distance
    ShiftedLabels = circshift(Labels,round(rand*length(Labels)));
end


