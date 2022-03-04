function[tractInfo] = computeTractsStatistics(subjectID, configPath)
    % Add paths
    addpath(genpath('~/Documents/MATLAB/encode'))
    addpath(genpath('~/Documents/MATLAB/jsonlab'))
    addpath(genpath('~/Documents/MATLAB/vistasoft'))
    addpath(genpath('~/Documents/MATLAB/wma_tools'))

    % read configuration file to get tracks and classification file paths
    config = loadjson(configPath);

    % read tractSeg's tractogram and load the WMC .mat file
    wbfg=fgRead(config.track);
    load(config.classification)

    % limit on the size of a tract that this code will try
    streamVol=100000;

    tractInfo = cell(length(classification.names), 8)

    % get streamlines for each tract
    for i=1:length(classification.names)   
        tractName=classification.names{i};
        fprintf("Analyzing %s...", tractName)

        streamlinesIndexes=find(classification.index == i);
        tractStreamlines=wbfg.fibers(streamlinesIndexes, 1);

        input.name=tractName;
        input.fibers=tractStreamlines;

        %%%%% compute tract statistics
        %[WBtractStat]= wma_quantTract(wbFG);    
        [costFuncVec, AsymRat,FullDisp ,streamLengths, efficiencyRat ] = ConnectomeTestQ_v2(input);
        WBtractStat.avgAsymRat=mean(AsymRat, "omitnan");
        WBtractStat.stDevAsymRat=std(AsymRat, "omitnan");

        WBtractStat.avgFullDisp=mean(FullDisp, "omitnan");
        WBtractStat.stDevFullDisp=std(FullDisp, "omitnan");

        WBtractStat.avgefficiencyRat=mean(efficiencyRat, "omitnan");
        WBtractStat.stDevefficiencyRat=std(efficiencyRat, "omitnan");

        %compute basic statistics
        WBtractStat.stream_count=length(input.fibers);
        WBtractStat.length_total=sum(streamLengths, "omitnan");

        % avgerage and standard deviation for streamline lengths
        WBtractStat.avg_stream_length=mean(streamLengths, "omitnan");
        WBtractStat.stream_length_stdev=std(streamLengths, "omitnan");

        %compute volume
        volVec=[];
        for istreamlines=1:length(input.fibers)
            streamLengths(istreamlines)=sum(sqrt(sum(diff(input.fibers{istreamlines},1,2).^2)));
            volVec=horzcat(volVec,input.fibers{istreamlines});
            %prevent memory usage from getting too extreme
            if rem(istreamlines,5000)==0
                volVec=   unique(round(volVec'),'rows')';
            end
        end

        %finish volume computation
        WBtractStat.volume=length(unique(round(volVec'),'rows'));
        %kind of like density
        WBtractStat.volLengthRatio=WBtractStat.length_total/WBtractStat.volume;     

        %get histcount data for plotting lenght histogram
        [counts,edges]=histcounts(streamLengths,'BinWidth',1,'BinLimits',[1,300]);
        WBtractStat.lengthCounts=counts;    


        if streamVol>WBtractStat.volume

            %reorient fibers so endpoint clouds make sense.
            fg=bsc_reorientFiber(input);

            %cluster the endpoints
            [RASout, LPIout, RASoutEndpoint, LPIoutEndpoint] = endpointClusterProto(fg);

            %get the midpoints
            midpoints=[];
            for iFibers=1:length(input.fibers)
                fiberNodeNum=round(length(input.fibers{iFibers})/2);
                curStreamline=input.fibers{iFibers};
                midpoints(iFibers,:)=curStreamline(:,fiberNodeNum);
            end

            %compute vol stats for RAS endpoint cloud
            WBtractStat.endpointVolume1=length(unique(round(RASout),'rows'));
            WBtractStat.avgEndpointCoord1=mean(RASout,1);
            WBtractStat.endpointDensity1=WBtractStat.stream_count/WBtractStat.endpointVolume1;

            %compute endpoint distances from RAS cloud centroid
            for istreamlines=1:length(input.fibers)
                endpointDists1(istreamlines)=sum(sqrt(sum(diff([WBtractStat.avgEndpointCoord1',RASout(istreamlines,:)'],1,2).^2)));
            end

            %compute average RAS endpoint distance from centroid
            WBtractStat.avgEndpointDist1=mean(endpointDists1);
            WBtractStat.stDevEndpointDist1=std(endpointDists1);



            %compute vol stats for LPI endpoint cloud
            WBtractStat.endpointVolume2=length(unique(round(LPIout),'rows'));
            WBtractStat.avgEndpointCoord2=mean(LPIout,1);
            WBtractStat.endpointDensity2=WBtractStat.stream_count/WBtractStat.endpointVolume2;

            %compute endpoint distances from RAS cloud centroid
            for istreamlines=1:length(input.fibers)
                endpointDists2(istreamlines)=sum(sqrt(sum(diff([WBtractStat.avgEndpointCoord2',LPIout(istreamlines,:)'],1,2).^2)));
            end

            %compute average RAS endpoint distance from centroid
            WBtractStat.avgEndpointDist2=mean(endpointDists2);
            WBtractStat.stDevEndpointDist2=std(endpointDists2);



            %compute vol stats for midpoint cloud
            WBtractStat.midpointVolume=length(unique(round(midpoints),'rows'));
            WBtractStat.avgMidpointCoord=mean(midpoints,1);
            WBtractStat.midpointDensity=WBtractStat.stream_count/WBtractStat.midpointVolume;

            %compute endpoint distances from RAS cloud centroid
            for istreamlines=1:length(input.fibers)
                midpointDists(istreamlines)=sum(sqrt(sum(diff([WBtractStat.avgMidpointCoord',midpoints(istreamlines,:)'],1,2).^2)));
            end

            %compute average RAS endpoint distance from centroid
            WBtractStat.avgMidpointDist=mean(midpointDists);
            WBtractStat.stDevMidpointDist=std(midpointDists);

        else
            warning('\n Endpoint and midpoint stats not run due to overly large tract')
        end    


        results.WBFG=WBtractStat;
        results.WBFG.lengthProps=results.WBFG.lengthCounts/results.WBFG.stream_count;

        %this may make the structure too large, if so consider removing
        allStreams=input.fibers;
        streamLengths=zeros(1,length(allStreams));

        for istreamlines=1:length(allStreams)
            streamLengths(istreamlines)=sum(sqrt(sum(diff(allStreams{istreamlines},1,2).^2)));
        end

        results.WBFG.lengthData=streamLengths;

        % save results for the current tract
        tractResults.(tractName) = results;


        % avgStreamlineLength, totalLength, volume, volLengthRatio, 
        % endpoint1Density, endpoint2Density, midpointDensity

        % save results of interest in the tractInfo cell
        tractInfo{i, 1} = tractName;
        tractInfo{i, 2} = results.WBFG.avg_stream_length;
        tractInfo{i, 3} = results.WBFG.length_total;
        tractInfo{i, 4} = results.WBFG.volume;
        tractInfo{i, 5} = results.WBFG.volLengthRatio;
        tractInfo{i, 6} = results.WBFG.endpointDensity1;
        tractInfo{i, 7} = results.WBFG.endpointDensity2;
        tractInfo{i, 8} = results.WBFG.midpointDensity;
    end


    T = cell2table(tractInfo);
    T.Properties.VariableNames = {'tract', 'avg_streamline_length',...
        'total_length', 'volume', 'vol_length_ratio', 'endpoint1_density',...
        'endpoint2_density', 'midpoint_density'};
    outputFilename = sprintf('../output/statistics/%s_tract_stats.csv', subjectID);
    writetable(T, outputFilename);

end

