function channelresponse = firstsecond(firstreps, secondreps,firstnoise,secondnoise)

efirst = specifyCinvorExperiment('stimlevel',8,strcat('trialPerStim=',num2str(firstreps)));
esecond = specifyCinvorExperiment('stimlevel',8,strcat('trialPerStim=',num2str(secondreps)));
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

figure;
hold on;

dispChannelOutput(train1test1,firstchannels,'MarkerFaceColor','b');
dispChannelOutput(trainbothtest1,bothchannels,'MarkerFaceColor','c');
dispChannelOutput(train2test2,secondchannels,'MarkerFaceColor','r');
dispChannelOutput(trainbothtest2,bothchannels,'MarkerFaceColor','m');
title(strcat('1 noise = ',num2str(firstnoise),'2 noise = ',num2str(secondnoise)));
%legend({'train 1, test 1','train both, test 1', 'train 2 test 2', 'train both test 2'});


