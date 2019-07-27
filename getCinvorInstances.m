% getCinvorResponses.m
%
%      usage: instances = getCinvorInstances(m,e)
%         by: justin gardner
%       date: 05/17/16
%    purpose: 
%
function instances = getCinvorInstances(m,e)

% check arguments
if ~any(nargin == [1 2])
  help simulateCinvorResponses
  return
end

% simulate bold responses
% Generate fMRI response, input is the model and experiment (m and e
% structures). For each stimulus value, generate individual trial reponses
% for each voxel. Note the response to a fixed stimulus value would be
% identical across repeats in without any noise. To generate different
% responses across trials, noise is added. The noiseRatio variable controls the
% magnitude of noise. Also note no time-domain convolution is used as we are not
% modeling fMRI response over time, just the neural responses summed across neurons within a voxel.
% JG: note that most of the code here has been moved into setCinvorModel so as not
% to repeat the computation.
instances={};

for iStimVal = 1:e.stimLevel
  % additive, noise is added on to pure voxel responses to get response
  taumat = m.tau*ones(1,m.nVoxels);
  bigsig = m.rho*taumat'*taumat + (1-m.rho)*diag(diag(taumat'*taumat));
  instances{iStimVal}=m.voxelResponse{iStimVal} + mvnrnd(zeros(1,m.nVoxels),bigsig,e.trialPerStim); 
end

% scale by amplitude
%instances = cellfun(@(x) mtimes(x,m.amplitude),instances,'UniformOutput',false);


