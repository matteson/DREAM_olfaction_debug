%% For reproducibility
sigma = 1;
rng('default')

%% load something as the "ground truth"
simulatedGround  = readtable('../Data/CecchiG_DREAM95olf_s1.txt','delimiter','\t');
simulatedPredict = simulatedGround;

%% Generate a correlated, but noisy set of predictions
simulatedPredict.value = simulatedGround.value  + sigma * randn(size(simulatedGround.value ));
writetable(simulatedPredict,'simulatedPredictions.txt','Delimiter','\t');

% call to sed to fix the first variable name
!sed -i '' -e s/x_oid/#oID/g simulatedPredictions.txt

% score the estimates using the DREAM provided script
!perl DREAM_Olfaction_scoring_Q1.pl simulatedPredictions.txt temp.txt ../Data/CecchiG_DREAM95olf_s1.txt

%% Read in the table of values produced by th DREAM scoring
dreamScored = readtable('temp.txt','delimiter','\t');

%% Calculate the correlations directly in MATLAB

descriptorList = unique(simulatedPredict.descriptor);

agg = 0;
for descriptor = 1:length(descriptorList)
    % for each descriptor
    mask = strcmp(descriptorList{descriptor}, simulatedPredict.descriptor);
    
    corrValues = zeros(49,1);
    for subject = 1:49
        % for each subject get the correlation of the descriptor across all
        % the odors
        subjectMask = (simulatedPredict.individual == subject);
        corrValues(subject) =  corr(simulatedPredict.value(mask & subjectMask),simulatedGround.value(mask & subjectMask));
    end
    
    % the corrValues variable contains the by subject correlations for the
    % descriptor, for intnsity and valence, this is the final value in
    % scoring. For the other 19 descriptors we need to average over the
    % all the descriptors, so we aggregate and divide after this loop.
    if descriptor == 1
        avgIntensity = mean(corrValues);
    elseif descriptor == 2
        avgValence = mean(corrValues);
    else
        agg = agg + mean(corrValues);
    end
end

avg19Other = agg/(length(descriptorList) - 2);

mScored = table(avgIntensity,avgValence,avg19Other);
%% Output the two tables, scored different ways
mScored
dreamScored