function stats = traintest(firstreps, secondreps,firstnoise,secondnoise)

efirst = specifyCinvorExperiment('stimLevel',8,strcat('trialPerStim=',num2str(firstreps)));
esecond = specifyCinvorExperiment('stimLevel',8,strcat('trialPerStim=',num2str(secondreps)));
mfirst = setCinvorModelOld(efirst,strcat('noise=',num2str(firstnoise)));
msecond = setCinvorModelOld(esecond,strcat('noise=',num2str(secondnoise)));

%generate first data
firsttrain=getCinvorInstancesOld(mfirst,efirst);
firsttest=getCinvorInstancesOld(mfirst,efirst);

%generate second data
secondtrain=getCinvorInstancesOld(msecond,esecond);
secondtest=getCinvorInstancesOld(msecond,esecond);

firstchannels = buildChannels(firsttrain,efirst.stimVals,'dispChannels=1','fitNoise',0);
secondchannels = buildChannels(secondtrain,efirst.stimVals,'dispChannels=1','fitNoise',0);
bothchannels = buildChannels(combineinstances(firsttrain,secondtrain),efirst.stimVals,'dispChannels=1','fitNoise',0);


train1test1 = testChannels(firsttest,efirst.stimVals,firstchannels,'fitNoise=0','dor2=0');
train2test2 = testChannels(secondtest,efirst.stimVals,secondchannels,'fitNoise=0','dor2=0');
trainbothtest1 = testChannels(firsttest,efirst.stimVals,bothchannels,'fitNoise=0','dor2=0');
trainbothtest2 = testChannels(secondtest,efirst.stimVals,bothchannels,'fitNoise=0','dor2=0');

%figure;
%hold on;

[a avg11 b stims11] = dispChannelOutput(train1test1,firstchannels,'MarkerFaceColor','b','suppressPlot=1');
[a avg1b b stims1b] = dispChannelOutput(trainbothtest1,bothchannels,'MarkerFaceColor','c','suppressPlot=1');
[a avg22 b stims22] = dispChannelOutput(train2test2,secondchannels,'MarkerFaceColor','r','suppressPlot=1');
[a avg2b b stims2b] = dispChannelOutput(trainbothtest2,bothchannels,'MarkerFaceColor','m','suppressPlot=1');
title(strcat('1 noise = ',num2str(firstnoise),'2 noise = ',num2str(secondnoise)));
%legend({'train 1, test 1','train both, test 1', 'train 2 test 2', 'train both test 2'});

%fit each set of outputs to von mises
vm11 = fitVonMises(stims11,avg11,'dispFit=0');
vm1b = fitVonMises(stims1b,avg1b,'dispFit=0');
vm22 = fitVonMises(stims22,avg22,'dispFit=0');
vm2b = fitVonMises(stims2b,avg2b,'dispFit=0');

%get it to return function widths

stats = [vm11.params.amp, vm11.params.halfWidthAtHalfHeight, vm1b.params.amp, vm1b.params.halfWidthAtHalfHeight,vm22.params.amp, vm22.params.halfWidthAtHalfHeight,vm2b.params.amp, vm2b.params.halfWidthAtHalfHeight];
