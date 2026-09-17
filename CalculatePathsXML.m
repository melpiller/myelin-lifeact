function [d,X,Delta,borders,origin,framesUsed] = CalculatePathsXML( xmlstruct, edgepos, makeplot, makeplot2, TL, name)
[traceData_sheaths, traceData_lifeact] = parseData(xmlstruct);
frames_sheaths = cell2mat(traceData_sheaths(:,2));
frames_lifeact = cell2mat(traceData_lifeact(:,2));
d = cell(1,max(frames_sheaths));
X = cell(1,max(frames_sheaths));
Delta = cell(1,max(frames_sheaths));
framesUsed = [];
if makeplot
    f1 = figure;
    f2 = figure;
    f3 = figure;
end
firstbrg = 0;
borders = cell(1,max(frames_sheaths));
origin = cell(1,max(frames_sheaths));
for i=1:max(frames_sheaths)
    temp = traceData_sheaths(frames_sheaths==i,:); % get sheaths for current timeframe
    if isempty(temp)
        continue
    end
    % organize trace points, sort from image left to right
    avgxyz = cell2mat(cellfun(@(x) mean(x,1),temp(:,6),'UniformOutput',false));
    avgx = avgxyz(:,1);
    [~,I] = sort(avgx,'ascend');
    nfrag = size(temp,1);
    d{i} = NaN(2000,2);
    lnth1 = 1;
    
    organized = NaN(3,nfrag);
    for k = 1:nfrag % running in order of left to right
        flipflag = 0;
        sheathedge = cell2mat(temp(I(k),6)); 
        if sheathedge(1,1) > sheathedge(end,1) 
            sheathedge = flip(sheathedge);
            flipflag = 1;
        end
        if cell2mat(temp(I(k),5)) == 1 % is a bridge
            b=1;
            if ~firstbrg
                firstbrgtp = i;
                firstbrg = 1;
            end
        elseif cell2mat(temp(I(k),5)) == 2 % has sheath origin
            b=2;
        else
            b=0;
        end
        organized(1,k) = cell2mat(temp(I(k),3));
        organized(2,k) = b;
        organized(3,k) = flipflag;
        lifeact = traceData_lifeact{frames_lifeact==i,7}; % NOW USING VOXELS
        sheathedge = cell2mat(temp(I(k),7)); % VOXELS
%         [IDX,D] = knnsearch(lifeact,sheathedge);
        [Lia,Locb] = ismember(sheathedge(:,1),lifeact(:,1));


        % compare based on HI/LO of rest of sheath frags
        if contains(edgepos,'lo') % determine if sheath edge is top or bottom of sheath; note: imagej origin is top left, so the "low" edge has a high Y value compared to the "high" edge
            D2 = (sheathedge(Lia,2) - lifeact(Locb(Locb>0),2)).*0.06; %return scaled
        else
            D2 = (lifeact(Locb(Locb>0),2) - sheathedge(Lia,2)).*0.06;
        end
        D2(D2<0) = 0;
        
        lnth0 = lnth1;
        lnth1 = lnth0 + length(D2) -1;
        d{i}(lnth0:lnth1,1) = D2;
        d{i}(lnth0:lnth1,2) = b;
        if b==1
            borders{i} = [borders{i},lnth0,lnth1];
        end
        if b==2 && ~flipflag
            origin{i} = lnth0;
        elseif b==2 && flipflag
            origin{i} = lnth1; % use end of sheath if orientation was flipped
        end
    end
    
    % PLOT REAL LENGTHS OF FRAGMENTS IN ORDER
    if makeplot
        figure(f2);
        hold on
        if size(organized,2)==1 % deal with singletons, ugh
            if organized(3,1) % flipped
                plot([-organized(1,1) 0],[TL(i) TL(i)],'k-','LineWidth',2)
            else % not flipped
                plot([0 organized(1,1)],[TL(i) TL(i)],'k-','LineWidth',2)
            end
        else
            ori = find(organized(2,:)==2);
            flipped = organized(3,ori);
            if ~flipped
                if ~(ori==1)
                    ori = ori-1;
                end
            end
            leftedge = sum(organized(1,1:ori));
            sums = cumsum(organized(1,:));
            edges = sums-sums(ori);
            edges = [-leftedge,edges];
            for s = 2:length(edges)
                switch organized(2,s-1)
                    case 0
                        color = 'k';
                    case 1
                        color = 'r';
                    case 2
                        color = 'k';
                end
                plot([edges(s-1) edges(s)],[TL(i) TL(i)],'Color',color,'LineWidth',2)
            end
        end
        hold off
    end
    
    idx = isnan(d{i}(:,1));
    d{i}(idx,:)=[];
    
    X{i} = 0:(lnth1-1);
   
    %% PLOT RECENT CHANGE
    if i>1 && any(X{i-1})
        idx1 = ismember(X{i-1},X{i}); % length of i-1
        idx2 = ismember(X{i},X{i-1}); % length of i
        delta = d{i}(idx2,1)-d{i-1}(idx1,1);
        Delta{i} = [X{i-1}(idx1)',delta];
        framesUsed = [framesUsed; i];
    end

        %% PLOT absolute distance
    if makeplot2
        figure(f3);
        hold on
        subplot(max(frames_sheaths),1,i)
        h = plot(X{i},d{i}(:,1),'LineWidth',2);
        
        cdo = colormap('parula');
        cd = interp1(linspace(0,1,length(cdo)),cdo,d{i}(:,1));
        cd = uint8(cd'*255);
        logdx = all(cd==0);
        if any(logdx)
            cd(1,logdx) = uint8(cdo(end,1)*255);
            cd(2,logdx) = uint8(cdo(end,2)*255);
            cd(3,logdx) = uint8(cdo(end,3)*255);
        end
        cd(4,:) = 255;
        drawnow
        set(h.Edge,'ColorBinding','interpolated','ColorData',cd)
        
        ylim([0 2])
        xlim([-1200,1200])
        xticks([])
        xticklabels([])
        axis off
        box off
        
        if any(borders{i})
            xline(borders{i},'Linewidth',1.5);
        end
        xline(0,'Linewidth',1.5,'Color','r');
        hold off
    end
end
end

%% ----Local Function----
function [ parsedData_sheaths, parsedData_lifeact ] = parseData(xmlstruct)
%get length of paths list
numPaths = size(xmlstruct.paths,2);
traceName = cell(numPaths,1);
traceLength = cell(numPaths,1);
traceSWC = cell(numPaths,1);
traceColor = cell(numPaths,1);
traceFrame = cell(numPaths,1);
traceChannel = cell(numPaths,1);
tracePaths = cell(numPaths,1);
traceVoxels = cell(numPaths,1);
for i = 1:numPaths
    traceName{i,1} = xmlstruct.paths(i).attribs.name;
    traceLength{i,1} = xmlstruct.paths(i).attribs.reallength_smoothed;
    traceSWC{i,1} = str2double(xmlstruct.paths(i).attribs.swctype);
    if contains(xmlstruct.paths(i).attribs.color,'Red')
        traceColor{i,1} = 1; % meaning lifeact
    else
        traceColor{i,1} = 0;
    end
    traceFrame{i,1} = str2double(xmlstruct.paths(i).attribs.frame);
    traceChannel{i,1} = xmlstruct.paths(i).attribs.channel;
    tracePaths{i,1} = xmlstruct.paths(i).points.smoothed;
    traceVoxels{i,1} = [xmlstruct.paths(i).points.x xmlstruct.paths(i).points.y xmlstruct.paths(i).points.z];
end
%PARSE TRACE INFO
%sheath extraction
index = find(cell2mat(traceColor)==0); % sheath edges
Names = traceName(index);
Lengths = traceLength(index);
SWCs = traceSWC(index);
Colors = traceColor(index);
Paths = tracePaths(index);
Voxels = traceVoxels(index);
Channels = traceChannel(index);
Frames = traceFrame(index);

%create array to send main function name & length info
parsedData_sheaths = [Names, Frames, Lengths, SWCs, Colors, Paths, Voxels];

index = find(cell2mat(traceColor)==1); % lifeact
Names = traceName(index);
Lengths = traceLength(index);
SWCs = traceSWC(index);
Colors = traceColor(index);
Paths = tracePaths(index);
Voxels = traceVoxels(index);
Channels = traceChannel(index);
Frames = traceFrame(index);

%create array to send main function name & length info
parsedData_lifeact = [Names, Frames, Lengths, SWCs, Colors, Paths, Voxels];
end