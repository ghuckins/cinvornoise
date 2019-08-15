function asdf = runtraintest(whichparam,fixedparam,paramrange,amporwidth)

data = [];

if whichparam == 'n' %noise level
  for i = 1:length(paramrange)
        data = [data ; traintest(200,200,fixedparam,paramrange(i))];%fixedparam is amount of noise for low noise data
  end  
  xax = 'high noise level';
elseif whichparam == 'd' %noisy data amount
    for i = 1:length(paramrange)
        data = [data ; traintest(100,paramrange(i),0.05,fixedparam)];%fixedparam is amount of noise for high noise data
    end
    xax = 'noisy data amt';
elseif whichparam == 'a' %all data amount (i.e. a/2 trials for low noise, a/2 trials for high noise)
    for i = 1:length(paramrange)
        data = [data ; traintest(paramrange(i)/2,paramrange(i)/2, 0.05, fixedparam)];%fixedparam is noise level for noisy data
    end
    xax = 'total data amt';
end

hold off;

if strcmpi(amporwidth, 'amp')
    plot(paramrange,data(:,1),'b');
    hold on;
    plot(paramrange,data(:,3),'c');
    plot(paramrange,data(:,5),'r');
    plot(paramrange,data(:,7),'m');
    legend('train low test low','train both, test low','train high, test high','train both, test high');
    title('amplitude')
    xlabel(xax)
elseif strcmpi(amporwidth, 'width')
    plot(paramrange,data(:,2),'b');
    hold on;
    plot(paramrange,data(:,4),'c');
    plot(paramrange,data(:,6),'r');
    plot(paramrange,data(:,8),'m');
    legend('train low test low','train both, test low','train high, test high','train both, test high');
    title('half width')
    xlabel(xax)
end

    
    
           

    
            
    