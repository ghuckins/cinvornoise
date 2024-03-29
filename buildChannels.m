% buildChannels.m
%      usage: channel = buildChannels(instances,stimValues,varargin)
%         by: justin gardner and taosheng liu
%       date: 07/25/14
%    purpose: Creates channels using the forward model proposed by Brouwer & Heeger (2009).
%             Input1: instances can be those returned from getInstances (see getInstances). It is 
%             a cell array for each category where each cell is a nxk matrix in which n 
%             is the number of repeats and k is the number of dimensions (e.g. voxels).
%             Input2: stimValues is a vector of stimulus value for each instance class
%             If a list of ROIs is passed in as first argument, will build channel
%             for each ROI (note the recursive call at the beginning).
%             Output:This function returns a structure that contains the
%             channel info., the meaning of some important fields are
%             explained below:
%             spanValues: all possible values in the span of
%             the features space (either 180 deg or 360 deg).
%             spanResponse: the channel responses evoked by each stimlus value in the span.
%             channelPref: the preferred stimulus value by each channel.
%             idealStimVals: specify a list of stimulus values to be used
%             for classification, by default set to the stimulus values in the training data.
%             idealStimResponse: the channel response evoked by the idealStimVals.
%             channelResponse: the theoretical channel response evoked by all the training stimuli.
%             channelWeights: the weight of the channel derived from the channelResponse and the actual instances.


function channel = buildChannels(instances,stimVals,varargin)
channel = [];
% check arguments
if any(nargin == [0])
  help buildChannels
  return
end

instanceFieldName=[]; channelFieldName=[]; model=[]; numFilters=[]; exponent=[]; algorithm=[]; dispChannels=[]; verbose=[];
% parse input arguments
[~,~,preprocessArgs] = getArgs(varargin,{'instanceFieldName=instance','channelFieldName=channel','model=sinFilter','numFilters=8','exponent=7','algorithm=pinv','dispChannels=0','verbose=0','fitNoiseModel=0','noiseModelGridSearchOnly=0','noiseModelFitTolerence=1','noiseModelGridSteps=10','fitNoise=0','channelXform=[]'});

% see if we are passed in a cell array of rois. If so, then call buildClassifier
% sequentially on each roi and put the output into the field specified by classField
if isfield(instances{1},instanceFieldName) && isfield(instances{1},'name')
  for iROI = 1:length(instances)
    if ~isfield(instances{iROI}.(instanceFieldName),'instances')
      disp(sprintf('(buildChannels) No instances found in %s for %s',instanceFieldName,instances{iROI}.name));
    else
      % put the output into the roi with the field specified by classField
      disppercent(-inf,sprintf('(buildChannels) Building %s channels for ROI %s',algorithm,instances{iROI}.name));
      instances{iROI}.(channelFieldName) = buildChannels(instances{iROI}.(instanceFieldName).instances,stimVals,varargin{:});
      disppercent(inf);
    end
  end
  channel = instances;
  return
end

% preprocess instances
[instances channel] = preprocessInstances(instances,'args',preprocessArgs);

% initialize matrices
instanceMatrix=[];
stimValVector=[];

% check that instance and stimVals match
if size(instances, 2)~=length(stimVals)
  disp(sprintf('(buildChannels) Number of stimulus values much match the number of classes in instances'));
  keyboard
end

% turn into an instance matrix
for istim=1:length(instances)
  stimValVector=[stimValVector, repmat(stimVals(istim),1,size(instances{istim},1))];
  instanceMatrix=[instanceMatrix; instances{istim}];
end

channel.instanceMatrix = instanceMatrix;

if max(stimVals)-min(stimVals) <=180
  channel.span=180; multiplier=2; %TSL:note the mulitpler trick (original *2 is actually correct)
else
  channel.span=360; multiplier=1;
end
oneTimeWarning('buildChannelsFeatureSpace',['(buildChannels) Assume feature space spanned by stimuli/channel is ',num2str(channel.span)]);

% get channel responses
channel.spanValues=0:1:channel.span-1;
[channel.spanResponse channel.channelPref]=getChannelResponse(channel.spanValues,multiplier,'model',model,'numFilters',numFilters,'exponent',exponent,'channelXform',channelXform);
if ~isequal(channel.channelPref, stimVals)
  warning('(buildChannels) Channels being built have different preferences than the stimulus. The current implementation is likely incorrect under such a setting');
end
channel.idealStimVals=stimVals;
[channel.idealStimResponse temp]=getChannelResponse(stimVals,multiplier,'model',model,'numFilters',numFilters,'exponent',exponent,'channelXform',channelXform);
[channel.channelResponse temp]=getChannelResponse(stimValVector,multiplier,'model',model,'numFilters',numFilters,'exponent',exponent,'channelXform',channelXform);

% get channel weights
channel.channelWeights=getChannelWeights(channel.channelResponse, instanceMatrix,'algorithm',algorithm);
if(fitNoise)
  [channel.rho channel.sigma channel.tao channel.omega]=getNoiseParam(channel.channelResponse, instanceMatrix,channel.channelWeights);
  [channel.posterior channel.posterior_mean channel.posterior_std] = getPosterior(channel,instanceMatrix)
end
a = channel.channelWeights;
save('channelweights05.mat','a');
% channel.channelWeights=channel.channelWeights./repmat(sum(channel.channelWeights,1),size(channel.channelWeights,1),1); % this will normalize the weights, not sure if it's correct 

% pack up into a structure to return
channel.info.model=model;
channel.info.numVoxels = size(instanceMatrix,2);
channel.info.numFilters=numFilters;
channel.info.exponent=exponent;
channel.info.algorithm=algorithm;

% FIX, FIX, instanceMatrixOnlyOne is for testing only
%inst = [];
%for istim=1:length(instances)
%  inst = [inst; instances{istim}(1,1:8)];
%end
%inst = inst-repmat(mean(inst),size(inst,1),1);
%resp = channel.idealStimResponse;
%resp([1 3 5 7],end+1) = 1;
%resp([2 4 6 8],end+1) = 1;
%resp = channel.channelResponse;
% and  one for mean response
%w = ((resp'*resp)^-1)*resp'*inst;
%ifit = resp*w;
%plot(ifit(:),inst(:),'k.');
%sqrt(sum((ifit(:) - inst(:)).^2))

%inst1 = inst([1 3 5 7],:);
%inst2 = inst([2 4 6 8],:);
%resp1 = resp([1 3 5 7],:);
%resp2 = resp([2 4 6 8],:);
%w1 = pinv(resp1)*inst1;
%w2 = pinv(resp2)*inst2;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% fit van Bergen et al. NN 18:1728-30 noise model
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if fitNoiseModel
  channel = channelNoiseModelFit(instanceMatrix,channel,'noiseModelGridSearchOnly',noiseModelGridSearchOnly,'noiseModelFitTolerence',noiseModelFitTolerence,'noiseModelGridSteps',noiseModelGridSteps);
end

% display
% if dispChannels
%   smartfig('Channels','reuse'); clf;
%   plot(channel.spanValues, channel.spanResponse,'linewidth',2);
%   for i=1:length(channel.channelPref)
%     thisLegend{i}=strcat('c',num2str(i));
%   end
%   legend(thisLegend);
%   xlabel('Span in degree');
%   ylabel('Response (arb unit)');
%   title('Response of each channel to all stim values');
% end

%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%   getChannelWeights   %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%
function channelWeights = getChannelWeights(channelResponse,instanceMatrix,varargin)

getArgs(varargin,{'algorithm=pinv'});

if strcmp(algorithm,'pinv')
  channelWeights = pinv(channelResponse)*instanceMatrix;
else
  disp(sprintf('(buildChannels:getChannelWeights) Unknown algorithm %s.',algorithm));
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%     getNoiseParam     %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [rho sigma tao omega] = getNoiseParam(channelResponse,instanceMatrix,channelWeights)
rho_0 = 0.1;
sigma_0 = 0.3;
tao_0 = 0.7*ones(1,size(instanceMatrix,2));
x_0 = [rho_0,sigma_0,tao_0];
f = @(x)likelihood(x(1),x(2),x(3:end),channelResponse,instanceMatrix,channelWeights);
A = [-eye(length(x_0));eye(length(x_0))];
A(end,1) = 1;
b = -0.001*ones(size(A,1),1); %avoid singularity
b(length(x_0)+2:end) = 10;
b(length(x_0) + 1) = 0.5;
lb = [0,0.2,0.6*ones(1,size(instanceMatrix,2))];
ub = [0.4,0.6,1.4*ones(1,size(instanceMatrix,2))];
options = optimoptions('fmincon','MaxFunEvals',10000,'Algorithm','sqp');
x = fmincon(f,x_0,A,b,[],[],lb,ub,[],options);
rho = x(1);
sigma = x(2);
tao = x(3:end);
omega = rho*tao'*tao + (1-rho)*diag(diag(tao'*tao))+sigma^2*channelWeights'*channelWeights; 


function nll = likelihood(rho,sigma,tao,channelResponse,instanceMatrix,channelWeights)
global thisError
%rho = 0;
sigma = 0;
omega = rho*tao'*tao + (1-rho)*diag(diag(tao'*tao))+sigma^2*channelWeights'*channelWeights; 
%omega = sigma*eye(size(channelWeights,2));
%omegaInv = inv(omega);
nll = 0;
thisError = instanceMatrix - channelResponse*channelWeights;
[cholsky, p] = chol(omega);
if p == 0
    nll = nll + 1/2*size(channelResponse,1)*(log(2*pi) + 2*sum(log(diag(cholsky)))); %2*sum(log(diag(chol(omega)))) is the logdet(omega)
    nll = nll + 1/2*sum(dot(thisError',(omega\thisError')));
else
    nll = 1000;
end
    


%nll = 0;
%thisError = instanceMatrix - channelResponse*channelWeights;
%nll = nll + 1/2*size(channelResponse,1)*log(2*pi*det(omega));
%nll = nll + 1/2*size(channelResponse,1)*(log(2*pi) + 2*sum(log(diag(chol(omega))))); %2*sum(log(diag(chol(omega)))) is the logdet(omega)
%nll = nll + 1/2*sum(dot(thisError',(omega\thisError')));
%%disp(sigma)
%%disp(rho)
%%disp(mean(abs(tao)))
%%disp(nll)
%%if(isnan(sigma))
%%  keyboard
%%end
%nll = nll + 1/2*thisError(i,:)*omegaInv*thisError(i,:)';

%disp(nll)

%omega = rho*tao'*tao + (1-rho)*diag(diag(tao'*tao))+sigma^2*channelWeights'*channelWeights; 
%omegaInv = inv(omega);
%nll2 = 0;
%thisError = instanceMatrix - channelResponse*channelWeights;
%for i = 1:size(channelResponse,1)
%  nll2 = nll2 - log(sqrt(2*pi*norm(omega)));
%  nll2 = nll2 + 1/2*thisError(i,:)*omegaInv*thisError(i,:)';
%end
%disp(nll-nll2)

function [posterior posterior_mean posterior_std] = getPosterior(channel,instanceMatrix)
omegaInv = inv(channel.omega);
N_trials = size(instanceMatrix,1);
posterior = zeros(N_trials,channel.span);
posterior_mean = zeros(N_trials,1);
posterior_std = zeros(N_trials,1);
if(channel.span == 180)
  multiplier = 2;
else
  multiplier = 1;
end
angles = deg2rad(1:multiplier:360);
for i = 1:N_trials
  for j = 1:channel.span
    thisError = instanceMatrix(i,:)' - channel.channelWeights'*channel.spanResponse(j,:)';
    posterior(i,j) = exp(-0.5*thisError'*omegaInv*thisError);
  end
  posterior(i,:) = posterior(i,:)/sum(posterior(i,:)); %normalization
  posterior_mean(i) = circ_mean(angles',posterior(i,:)')/(2*pi)*(360/multiplier);
  posterior_std(i) = circ_std(angles',posterior(i,:)')/(2*pi)*(360/multiplier);
end



%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%   getChannelResponse   %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [channelResponse channelOrientPref] = getChannelResponse(orientationVec,multiplier,varargin)

getArgs(varargin,{'model=sinFilter','numFilters=8','exponent=2','filterPhaseOffset=0','channelXform=[]'});

if strcmp(model,'sinFilter')
  [channelResponse channelOrientPref] = sinFilter(orientationVec,multiplier,numFilters,exponent,filterPhaseOffset);
  % convert channel response using channelXform
  if ~isempty(channelXform)
    channelResponse = channelResponse*channelXform;
  end
elseif strcmp(model,'stickFilter')
  [channelResponse channelOrientPref] = stickFilter(orientationVec,multiplier,numFilters,exponent,filterPhaseOffset);
else
  disp(sprintf('(docinvor) Unknown filter type: %s',model));
end

%%%%%%%%%%%%%%%%%%%
%%   sinFilter   %%
%%%%%%%%%%%%%%%%%%%
function [filterOut filterOrientPref] = sinFilter(orientation,multiplier,numFilters,filterExponent,filterPhaseOffset)

numOrientations=length(orientation);

% get filter phases (evenly spaced) starting at filterPhaseOffset
filterPhase = filterPhaseOffset:360/numFilters:(359+filterPhaseOffset);

% get orientation and filter phase in radians
orientation = d2r(orientation(:)*multiplier);
filterPhase = d2r(filterPhase(:));

% handle multiple phases (i.e. multiple filters)
orientation = repmat(orientation,1,numFilters);
filterPhase = repmat(filterPhase',numOrientations,1);

% sinusoid
filterOut = cos(orientation-filterPhase);

% rectify
filterOut = filterOut.*(filterOut>0);

% apply exponent
filterOut = filterOut.^filterExponent;

% return filterOrientPref (which is just the filterPhase in deg divided by 2)
filterOrientPref = r2d(filterPhase(1,:)/multiplier);

%%%%%%%%%%%%%%%%%%%%%
%    sitckFilter    %
%%%%%%%%%%%%%%%%%%%%%
function [filterOut filterOrientPref] = stickFilter(orientation,multiplier,numFilters,filterExponent,filterPhaseOffset)

numOrientations=length(orientation);

% get filter phases (evenly spaced) starting at filterPhaseOffset
filterPhase = filterPhaseOffset:360/numFilters:(359+filterPhaseOffset);

% get orientation and filter phase in radians
orientation = d2r(orientation(:)*multiplier);
filterPhase = d2r(filterPhase(:));

% handle multiple phases (i.e. multiple filters)
orientation = repmat(orientation,1,numFilters);
filterPhase = repmat(filterPhase',numOrientations,1);

% delta function
filterOut = double((orientation-filterPhase) == 0);

% return filterOrientPref (which is just the filterPhase in deg divided by 2)
filterOrientPref = r2d(filterPhase(1,:)/multiplier);
