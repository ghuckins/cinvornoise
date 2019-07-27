noiselevels = [0.,0.05,0.1,0.5,1];

vals = [0,0,0,0];

%xform = rand(8,8);
xform = [         0    0.8000    0.7600         0    0.0400         0    0.7600    0.8000
   0.8000         0    0.8000    0.7600         0    0.0400         0    0.7600
   0.7600    0.8000         0    0.8000    0.7600         0    0.0400         0
        0    0.7600    0.8000         0    0.8000    0.7600         0    0.0400
   0.0400         0    0.7600    0.8000         0    0.8000    0.7600         0
        0    0.0400         0    0.7600    0.8000         0    0.8000    0.7600
   0.7600         0    0.0400         0    0.7600    0.8000         0    0.8000
   0.8000    0.7600         0    0.0400         0    0.7600    0.8000         0];

e = specifyCinvorExperiment('stimlevel',8,'trialPerStim=21');

for i=1:length(noiselevels)
    j = 0;
    m = setCinvorModel(e,strcat('noise=',num2str(noiselevels(i))))
    while j < 100
        total = 0;
        trainInstances = getCinvorInstances(m,e);
        testInstances = getCinvorInstances(m,e);
        channel = buildChannels(trainInstances,e.stimVals,'dispChannels=1','fitNoise',0,'channelXform',xform);
        channelOutput = testChannels(testInstances,e.stimVals,channel,'fitNoise=0','dor2=0');
        [statsStr averageResponse steResponse shiftedStimVal] = dispChannelOutput(channelOutput,channel,'MarkerFaceColor','b','suppressPlot','True');
        total = total + abs(dot(averageResponse,shiftedStimVal));
        j = j + 1
    end
    vals(i) = total/100.;       
end

vals