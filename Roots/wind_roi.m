function [WindRoi, Range] = wind_roi(DFF,TrigOff,varargin)
% Get many roi time series at the trigger sites at the trigger
% spits out a matrix which is blablabla

% if trigger is two columns, window gets added -/+ to that range.
% in all cases, trials are out in cells (Roi). each cell is matrix cell *
% range.

%% SET CONTROLS
Window = [-22 44];
if ~iscell(TrigOff) % if i am not cutting
    NumTriggers = size(TrigOff,1); else; NumTriggers = size(TrigOff{1},1);
end

%% PASS ARGUMENTS TO CONTROLS
for I=1:2:numel(varargin)
    eval([varargin{I} '= varargin{I+1};']);
end

%% get data
%for every trial
for I = 1:NumTriggers
    if ~iscell(TrigOff) % if i am not cutting
        % is TrigOff two columns or one?
        if size(TrigOff,2) == 1
            Range(I,:) = [TrigOff(I)+Window(1) TrigOff(I)+Window(2)];
        else
            Range(I,:) = [TrigOff(I,1)+Window(1) TrigOff(I,2)+Window(2)];
        end
        if Range(I,1) > 0 && Range(I,2) < length(DFF)
            WindRoi{I} = DFF(:,Range(I,1):Range(I,2));
        else
            WindRoi{I} = nan;
        end
    else
        if length(TrigOff) == 3 % cut both sides
            Range(I,:) = [max(TrigOff{2}(I)+Window(1),TrigOff{1}(I)) min(TrigOff{2}(I)+Window(2),TrigOff{3}(I))];
            if Range(I,1) > 0 && Range(I,2) < length(DFF)
                WindRoi(1:size(DFF,1),1:(abs(Window(1))+Window(2)+1),I) = nan;
                Left = TrigOff{2}(I) - Range(I,1);
                WindRoi(:,(abs(Window(1))+1)-Left:(abs(Window(1))+1),I) = DFF(:,(Range(I,1):Range(I,1)+Left));
                Right = Range(I,2) - TrigOff{2}(I);
                WindRoi(:,(abs(Window(1))+1):(abs(Window(1))+1+Right),I) = DFF(:,(Range(I,2)-Right:Range(I,2)));
            else
                WindRoi(:,:,I) = nan(size(DFF,1),abs(Window(1))+1+Window(2));
            end
        elseif nanmean(TrigOff{2}((1:end-1))) > nanmean(TrigOff{1}((1:end-1))) % forward cut
            Range(I,:) = [TrigOff{1}(I)+Window(1) min(TrigOff{1}(I)+Window(2),TrigOff{2}(I))];
            WindRoi(:,:,I) = nan(size(DFF,1),(-Window(1))+1+Window(2));
            if Range(I,1) > 0 && Range(I,2) < length(DFF) && Range(I,1) < Range(I,2)% if it is not outside some range
                WindRoi(:,1:(Range(I,2)-Range(I,1)+1),I) = DFF(:,Range(I,1):Range(I,2));
                if TrigOff{2}(I) == Range(I,2) % if it chose the second, need to pad
                    WindRoi(:,(Range(I,2)-Range(I,1)+1)+1:end,I) = nan;
                end
%             else
%                 WindRoi(:,:,I) = nan(size(DFF,1),abs(Window(1))+1+Window(2));
            end
        elseif nanmean(TrigOff{2}(2:end-1)) < nanmean(TrigOff{1}(2:end-1)) % backward cut
            Range(I,:) = [max(TrigOff{1}(I)+Window(1),TrigOff{2}(I)) TrigOff{1}(I)+Window(2)];
            WindRoi(:,:,I) = nan(size(DFF,1),(-Window(1))+1+Window(2));
            if Range(I,1) > 0 && Range(I,2) < length(DFF)
                WindRoi(:,end-(Range(I,2)-Range(I,1)):end,I) = DFF(:,Range(I,1):Range(I,2));
                if TrigOff{2}(I) == Range(I,1) % if it chose the second, need to pad
                    Difference = abs((diff(Range(I,:))-Window(2)) + Window(1));
                    WindRoi(:,:,I) = cat(2,repmat(nan,[size(WindRoi,1) Difference]),WindRoi(:,end-(Range(I,2)-Range(I,1)):end,I));
                end
            end
        end
    end
end
