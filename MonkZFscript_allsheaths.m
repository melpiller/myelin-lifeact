function [SD] = MonkZFscript_allsheaths(makeplot)
path = 'D:\GitHubRepos\Call_ParanodalBridge_2022\MonkZFtraces\allsheaths';
cd(path);
fldr = dir(path);
files = {fldr(3:end).name};
n = length(files);
alltimeSheaths = NaN(n,160);
alltimeBrgs = NaN(n,160);
colors = parula;
SD = struct; %all sheath data

if makeplot
    figure(1);
end
for f = 1:n
    name = files{f};
    SD(f).name = name(1:12);
    xmlstruct = parseXML_SingleCell(name);
    timeline = gettimeline(name(1:12));

    parsedData_sheaths = parseData(xmlstruct);
    sheathnames = parsedData_sheaths(:,1);
    frames = cell2mat(parsedData_sheaths(:,2));
    bridges = cell2mat(parsedData_sheaths(:,3));
    lastframe = max(frames);
    numsheaths = NaN(1,lastframe);
    numbrgs = numsheaths;
    
    brgnames_All = sheathnames(contains(sheathnames,'b'));
    brgsUniq = unique(cellfun(@(x) x(1:3),brgnames_All,'UniformOutput',false));
    SD(f).brgPD = zeros(length(brgsUniq),lastframe);
    
    for i = 1:lastframe
        numsheaths(i) = sum(frames==i);
        numbrgs(i) = sum(bridges(frames==i));
        
        if i>1 && ~(numsheaths(i-1)==0) && numsheaths(i)==0
            numsheaths(i) = numsheaths(i-1);
            numbrgs(i) = numbrgs(i-1);
            SD(f).brgPD(:,i) = SD(f).brgPD(:,i-1);
        elseif i==lastframe && any(contains(parsedData_sheaths(frames==i),'placeholder'))
            numsheaths(i) = numsheaths(i-1);
            numbrgs(i) = numbrgs(i-1);
            SD(f).brgPD(:,i) = SD(f).brgPD(:,i-1);
        else
            brgnames_Curr = sheathnames(bridges & frames==i);
            brgExist_idx = ismember(brgsUniq,cellfun(@(x) x(1:3),brgnames_Curr,'UniformOutput',false));
            SD(f).brgPD(brgExist_idx,i) = 1;
        end
    end
    peak = max(numsheaths);
    idx = find(numsheaths==peak);
    peakedge = idx(end);
    SD(f).peakedge = peakedge;
    adjTL = timeline - timeline(peakedge);
    SD(f).adjTL = adjTL;
    
    [~,firstTPbrgs] = max(SD(f).brgPD,[],2);
    [~,lastTPbrgs] = max(flip(SD(f).brgPD,2),[],2);
    lastTPbrgs = lastframe + 1 - lastTPbrgs; % first tp not observed
    lastTPbrgs(ismember(lastTPbrgs,lastframe)) = NaN;
    SD(f).gainloss = [firstTPbrgs lastTPbrgs];
    SD(f).gainlossAdj(:,1) = SD(f).adjTL(firstTPbrgs);
    for a = 1:length(lastTPbrgs)
        if isnan(lastTPbrgs(a))
            SD(f).gainlossAdj(a,2) = NaN;
        else
            SD(f).gainlossAdj(a,2) = SD(f).adjTL(lastTPbrgs(a));
        end
    end
    
    % adjusted timeline to peak of sheaths
    %RAW
%     if makeplot
%         figure(1);
%         hold on
%         tempcolor = colors(round(256/n*f),:);
%         plot(adjTL,numsheaths,'LineStyle','-','Color',tempcolor,'LineWidth',2)
%         plot(adjTL,numbrgs,'LineStyle',':','Color',tempcolor,'LineWidth',2)
%         hold off
%         [~,scaledidx] = ismember(round(adjTL),-29:130);
%         alltimeSheaths(f,scaledidx) = numsheaths;
%         alltimeBrgs(f,scaledidx) = numbrgs;
%     end
    
    tempcolor = colors(round(256/n*f),:);
    SD(f).cellcolor = tempcolor;
    %PROPORTIONAL
    if makeplot
        figure(1);
        hold on
        plot(adjTL,numsheaths./max(numsheaths),'LineStyle','-','Color',tempcolor,'LineWidth',2)
        plot(adjTL,numbrgs./numsheaths,'LineStyle',':','Color',tempcolor,'LineWidth',2)
        hold off
        [~,scaledidx] = ismember(round(adjTL),-29:130);
        alltimeSheaths(f,scaledidx) = numsheaths;
        alltimeBrgs(f,scaledidx) = numbrgs;
    end
end

% fill curves with missing timepoints
temp = ~isnan(alltimeSheaths);
idx = cell2mat(arrayfun(@(x) find(temp(x,:),1,'last'),1:size(alltimeSheaths,1),'UniformOutput',false));
filledSheaths = fillmissing(alltimeSheaths(:,30:end),'linear',2);
filledBrgs = fillmissing(alltimeBrgs(:,30:end),'linear',2);
for i=1:length(idx)
    if idx(i)<110
        filledSheaths(i,idx(i)-29:81)=NaN;
        filledBrgs(i,idx(i)-29:81)=NaN;
    end
end

% add means to adjusted timeline numbers plot
%RAW
% if makeplot
%     figure(1);
%     hold on
%     plot(0:80,mean(filledSheaths(:,1:81),'omitnan'),'LineStyle','-','Color','k','LineWidth',2)
%     plot(0:80,mean(filledBrgs(:,1:81),'omitnan'),'LineStyle',':','Color','k','LineWidth',2)
%     figQuality(gcf,gca,[4.6,2.5])
%     xlim([-25 75])
%     xticks([-25 0 25 50 75])
% end

%PROPORTIONAL
if makeplot
    figure(1);
    hold on
    plot(0:80,mean(filledSheaths(:,1:81)./max(filledSheaths,[],2),'omitnan'),'LineStyle','-','Color','k','LineWidth',2)
    plot(0:80,mean(filledBrgs(:,1:81)./filledSheaths(:,1:81),'omitnan'),'LineStyle',':','Color','k','LineWidth',2)
    figQuality(gcf,gca,[4.6,2.5])
    xlim([-25 75])
    xticks([-25 0 25 50 75])
end

allgainloss = [];
for f = 1:size(SD,2)
    allgainloss = [allgainloss; SD(f).gainlossAdj];
end
if makeplot
    figure
    hold on
    histogram(allgainloss(:,1),0:10:80);
    histogram(allgainloss(:,2),0:10:80);
    % plot(pdf(pd_nonpar_gain,0:1:80));
    % plot(pdf(pd_nonpar_loss,0:1:80));
    hold off
end
end        

function [ parsedData_sheaths ] = parseData(xmlstruct)
%get length of paths list
numPaths = size(xmlstruct.paths,2);
traceName = cell(numPaths,1);
traceColor = cell(numPaths,1);
traceFrame = cell(numPaths,1);
for i = 1:numPaths
    traceName{i,1} = xmlstruct.paths(i).attribs.name;
    if contains(xmlstruct.paths(i).attribs.color,'Orange')
        traceColor{i,1} = 1; % meaning bridge
    else
        traceColor{i,1} = 0;
    end
    traceFrame{i,1} = str2double(xmlstruct.paths(i).attribs.frame);
end

%PARSE TRACE INFO
%sheath extraction
parsedData_sheaths = [traceName, traceFrame, traceColor];
end