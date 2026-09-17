function data = LifeactTracking(makeplot,makeplot2)
timeline = 0:0.25:8; % Edit to reflect start:interval:end time duration (in hours) of video to analyze
path = 'C:\...'; % Replace with desired path
cd(path);
files = dir(path);
files = files(3:end,:);
files = files(~[files.isdir]);
files = files(~contains({files.name},'.mat'));
for f = 1:size(files,1)
    name = files(f).name;
    varname = matlab.lang.makeValidName(name);
    if exist(fullfile(path,[varname '.mat']),'file')
        load([varname '.mat']);
    else
        xmlstruct = parseXML_SingleCell(name);
        save(fullfile(path,[varname '.mat']),'xmlstruct');
    end
    if contains(name,'lo')
        edgepos = 'lo';
    elseif contains(name,'hi')
        edgepos = 'hi';
    end

    % get path data and Delta distance between sheath & lifeact
    [~,~,Delta,~,~,framesUsed] = CalculatePathsXML(xmlstruct,edgepos,makeplot,makeplot2,timeline,name);
    TL = timeline(1:max(framesUsed));
    
    sz = cellfun(@size,Delta,'UniformOutput',false);
    maxsz = max(cell2mat(sz));
    Dall = [];
    for i = 1:length(Delta)
        if any(Delta{i})
            Dadj = NaN(1,maxsz);
            Dadj(1:size(Delta{i},1)) = movmean(Delta{i}(:,2),50)';
            Dall = [Dall;Dadj];
        end
    end
    
    data{f,1} = TL;
    data{f,2} = abs(Dall);

end


end
%% local functions
function filled_indexed  = averageSheathTLs(cellinput,universalTL,roundedTL)
    TLidx = [];
    idxFL= [];
    indexed = [];
    filled_indexed = [];
    
    [~,TLidx(1,:)] = ismember(universalTL,roundedTL);
    for k = 1:length(universalTL)
        if TLidx(1,k)==0
            indexed(1,k) = NaN;
            continue
        else
            indexed(1,k) = cellinput(TLidx(1,k));
        end
    end
    idxFL(1) = find(~isnan(indexed),1,'first');
    idxFL(2) = find(~isnan(indexed),1,'last');
    filled_indexed = fillmissing(indexed,'linear');
    filled_indexed(1:idxFL(1)) = NaN;
    filled_indexed(idxFL(2):end) = NaN;
    filled_indexed(filled_indexed<0) = 0;
end

% Output data in ans represents difference between lifeact signal and
% bottom of sheath throughout imaging timecourse

% To estimate Lifeact signal variability, use output data in ans to 
% quantify the sum absolute value of changes in this distance during the 
% measured period, averaged along the length of the sheath
