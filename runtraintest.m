function asdf = runtraintest(whichparam,fixedparam,paramrange,amporwidth)

totaldata = [];
numreps = 100;

if whichparam == 'k' %kappa
  for j = 1:numreps
      data = [];
      for i = 1:length(paramrange)
        data = [data ; traintest(strcat('secondkappa=',num2str(4+paramrange(i))))];%fixedparam is noise for both
      end  
      totaldata = cat(3,totaldata,data);
  end
  xax = 'difference in kappa';
elseif whichparam == 'n' %noise level
  for j = 1:numreps
      data = [];
      for i = 1:length(paramrange)
        data = [data ; traintest(strcat('firstnoise=',num2str(fixedparam)), strcat('secondnoise=',num2str(paramrange(i))))];%fixedparam is amount of noise for low noise data
      end  
      totaldata = cat(3,totaldata,data);
  end
  xax = 'high noise level';
elseif whichparam == 'd' %noisy data amount
    for j = 1:numreps
      data = [];
      for i = 1:length(paramrange)
          data = [data ; traintest(100,paramrange(i),0.05,fixedparam,4,4)];%fixedparam is amount of noise for high noise data
      end
      totaldata = cat(3,totaldata,data);
    end  
    xax = 'noisy data amt';
elseif whichparam == 'a' %all data amount (i.e. a/2 trials for low noise, a/2 trials for high noise)
    for j = 1:numreps
      data = [];
      for i = 1:length(paramrange)
          data = [data ; traintest(strcat('firstreps=',int2str(paramrange(i)/2)),strcat('secondreps=',int2str(paramrange(i)/2)),'firstnoise=0.05',strcat('secondnoise=',num2str(fixedparam)))];%fixedparam is noise level for noisy data
      end
      totaldata = cat(3,totaldata,data);
    end
    xax = 'total data amt';
elseif whichparam == 'g' %gain width
    for j = 1:numreps
      data = [];
      for i = 1:length(paramrange)
          data = [data ; traintest('firstnoise= 0.2','secondnoise= 0.2','firstgain= 0','secondgain= 1', strcat('secondsig=',int2str(paramrange(i))))];%fixedparam is noise level for noisy data
      end
      totaldata = cat(3,totaldata,data);
    end
    xax = 'gain width';
elseif whichparam == 'c' %center or off-center gain
    for j = 1:numreps
      data = [];
      for i = 1:length(paramrange)
          data = [data ; traintest('firstnoise= 0.2','secondnoise= 0.2','firstgain= 1','secondgain= 1', strcat('firstsig=',int2str(paramrange(i))),strcat('secondsig=',int2str(paramrange(i))),'firstcenter=1','secondcenter=0')];%fixedparam is noise level for noisy data
      end
      totaldata = cat(3,totaldata,data);
    end
    xax = 'gain width';
elseif whichparam == 'w' %different neuron weights
    for j = 1:numreps
      data = [];
      for i = 1:length(paramrange)
          data = [data ; traintest('opp1=0','opp2=1',strcat('firstnoise=',num2str(paramrange(i))),strcat('secondnoise=',num2str(paramrange(i))))];%fixedparam is noise level for noisy data
      end
      totaldata = cat(3,totaldata,data);
    end
    xax = 'gain width';
end

means = mean(totaldata,3);
stdevs = std(totaldata,0,3);

hold off;

if strcmpi(amporwidth, 'amp')
    errorbar(paramrange,means(:,1),stdevs(:,1),'b');
    hold on;
    errorbar(paramrange,means(:,3),stdevs(:,3),'c');
    errorbar(paramrange,means(:,5),stdevs(:,5),'r');
    errorbar(paramrange,means(:,7),stdevs(:,7),'m');
    legend('train low, test low','train both, test low','train high, test high','train both, test high');
    title('amplitude')
    xlabel(xax)
elseif strcmpi(amporwidth, 'width')
    errorbar(paramrange,means(:,2),stdevs(:,2),'b');
    hold on;
    errorbar(paramrange,means(:,4),stdevs(:,4),'c');
    errorbar(paramrange,means(:,6),stdevs(:,6),'r');
    errorbar(paramrange,means(:,8),stdevs(:,8),'m');
    legend('train low test low','train both, test low','train high, test high','train both, test high');
    ylabel('half width (deg)')
    xlabel(xax)
end

    
    
           

    
            
    