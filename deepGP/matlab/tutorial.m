% TUTORIAL Demonstration of deep GPs in various scenarios.
%
% DESC Demonstration of deep GPs in various scenarios.
%
% COPYRIGHT: Andreas C. Damianou, 2013
%
% DEEPGP

%% --------------   TOY UNSUPERVISED LEARNING DEMO ------------------------%
clear; close all
fprintf(1,['', ...
 '#####  Toy unsupervised (dimensionality reduction) demo: ####\n', ...
 '\n', ...
 'The deep GPs are first tested on toy data, created by stampling\n', ...
 'from a three-level stack of GPs. The true hierarchy is depicted\n', ...
 'in the demo, once the deep GP is trained. In short, from the top latent\n', ...
 'layer (X2) two intermediate latent signals are generated (XA and XB). \n', ...
 'These, in turn, together generate 10-dimensional observations\n', ...
 '(YA, YB) through sampling of another GP. These observations are then\n', ...
 'used to train the following models: a deep GP, a simple stacked PCA\n', ...
 'and a stacked Isomap method. From these models, only the deep GP\n', ...
 'marginalises the latent spaces and, in contrast to the other two,\n', ...
 'it is not given any information about the dimensionality of each true\n', ...
 'signal in the hierarchy; instead, this is learnt automatically\n', ...
 'through ARD.\n', ...
 '\n', ...
 'The deep GP finds the correct dimensionality for each\n', ...
 'hidden layer, but it also discovers latent signals which are closer\n', ...
 'to the real ones.\n', ...
 '\n', ...
  'The model can be parametrized in many ways, and the demo here considers\n',...
 'a basic parameterization. You can experiment with different latent space\n', ...
 'initialisations, different kernels (linear, non-linear, etc).\n',...
 'For other possible options check ''hsvargplvm_init.m'' and the various demos.\n']);

fprintf('\n# Press any key to start demo...\n')
pause
clear; close all
demToyUnsupervised; % Call to the demo

fprintf(1, '\n\nWe can print the model with ''hsvargplvmDisplay(model)''.\n');
fprintf('Press any key to display model:\n')
pause
hsvargplvmDisplay(model)

fprintf('\n\n');


%% -----------------    TOY REGRESSION DEMO -------------------------------%
fprintf(1,['', ...
 '#####  Toy regression demo: ####\n', ...
 'This is a simple regression demo which uses a toy dataset of\n', ...
 'input-output pairs [X0, Y] generated as follows: given an initial equally\n', ...
 'spaced input X_0, we feed this to a GP from which we sample outputs\n',...
 'X_1. These are in turn fed to another GP from which we sample outputs\n', ...
 'Y. Deep GPs (that use sparse GP apprpoximations by default) are compared\n', ...
 'to full (non-sparse) GPs (aka ''ftc'') and to sparse GPs with the ''fitc''\n', ...
 'approximation.\n', ...
 '\n', ...
 'The above experiment is run multiple times with random sets, and the\n',...
 'results are plotted for every trial.\n',...
 '\n', ...
 'Modeling-wise, this demo differs from the unsupervised learning one in that\n', ...
 'the deep GP has observed inputs on the top layer. Then, the kernel used for\n', ...
 'the mapping between the top layer and the one below, couples all inputs.\n',...
 '\n', ...
 'The models can be parametrized in many ways, and the demo here considers\n',...
 'a basic parameterization. You can experiment with different latent space\n', ...
 'initialisations, different kernels (linear, non-linear, etc).\n',...
 'For other possible options check ''hsvargplvm_init.m'' and the various demos.\n', ...
 '\n', ...
 'Here we set a large number of iterations for the deep GPs, since their convergence\n', ...
 'is much slower (the other baselines are run until convergence). But you can still\n', ...
 'get reasonable results even by reducing a lot the number of iterations\n', ...
 'with initVardist and itNo, e.g. itNo = [5000 2000]; (or even less).\n', ...
 '\n', ...
 'NOTE!!! For a quicker regression demo check: demToyRegressionSimple.m\n']);
 
fprintf('\n# Press any key to start demo...\n')
pause
clear; close all
pause(1)

% File which stores the results
fName = './RESULT_demoRegressionErrors.txt';

% Initialise the error vectors
eGP = []; eGPfitc = []; eRecGP = []; eDeepGP = []; eDeepGPNoCovars = [];
eDeepGPIn =[]; eRecDeepGP = []; eRecDeepGPNoCovars = []; eMean = []; eLinReg = [];
for experimentNo=[1:15];
	keep('fName', 'experimentNo', 'eMean', 'eLinReg', 'eGP', 'eGPfitc', 'eRecGP', 'eDeepGP', 'eDeepGPNoCovars', 'eDeepGPIn', 'eRecDeepGP', 'eRecDeepGPNoCovars');
	% Different random seed depending on the experiment id
    randn('seed', 6000+experimentNo); rand('seed', 6000+experimentNo);
    errorInRun = 0; % Flag
	try  
		demToyRegression; % Run the main demo
	catch e
        if strcmp(e.identifier, 'hsvagplvm:checkSNR:lowSNR')
            % If the previous optimisation resulted in low SNR and threw
            % an error, try again but this time initialise the variational
            % distribution for longer and with higher SNR.
            fprintf(1, ['\n\n### Low SNR in experimentNo = ' num2str(experimentNo) ' !! Trying again...\n\n'])
            keep('fName', 'experimentNo', 'eMean', 'eLinReg', 'eGP', 'eGPfitc', 'eRecGP', 'eDeepGP', 'eDeepGPNoCovars', 'eDeepGPIn', 'eRecDeepGP', 'eRecDeepGPNoCovars');
            randn('seed', 6000+experimentNo); rand('seed', 6000+experimentNo);
            initVardistIters = [2100 1600 1600];  itNo = [2000 repmat(1000, 1,13)];
            initSNR = {150, 350};
            errorInRun = 0; % Flag
            try
                demToyRegression
            catch e
                % If for a second time there's a problem with SNR, give up.
                errorInRun = 1; fprintf(1, ['Error in experimentNo = ' num2str(experimentNo) ': ' e.message])
            end
        else
            errorInRun = 1; fprintf(1, ['Error in experimentNo = ' num2str(experimentNo) ': ' e.message])
        end
	end
	if ~errorInRun
        % Print on screen and in a file the diagnostics and errors
		hsvargplvmShowSNR(model);
		ff = fopen(fName, 'w');
		eMean = [eMean errorMean]; fprintf(ff, 'errorMean = ['); fprintf(ff, '%.4f ', eMean); fprintf(ff,'];\n');
		eLinReg = [eLinReg errorLinReg]; fprintf(ff, 'errorLinReg = ['); fprintf(ff, '%.4f ', eLinReg); fprintf(ff,'];\n');
		eGPfitc = [eGPfitc errorGPfitc]; fprintf(ff, 'errorGPfitc = ['); fprintf(ff, '%.4f ', eGPfitc); fprintf(ff,'];\n');
    	        eDeepGP = [eDeepGP errorDeepGP]; fprintf(ff, 'errorDeepGP = ['); fprintf(ff, '%.4f ', eDeepGP); fprintf(ff,'];\n');
		eDeepGPNoCovars = [eDeepGPNoCovars errorDeepGPNoCovars]; fprintf(ff, 'errorDeepGPNoCovars = ['); fprintf(ff, '%.4f ', eDeepGPNoCovars); fprintf(ff,'];\n');
		eDeepGPIn = [eDeepGPIn errorDeepGPIn]; fprintf(ff, 'errorDeepGPIn = ['); fprintf(ff, '%.4f ', eDeepGPIn); fprintf(ff,'];\n');
		eRecDeepGP = [eRecDeepGP errorRecDeepGP]; fprintf(ff, 'errorRecDeepGP = ['); fprintf(ff, '%.4f ', eRecDeepGP); fprintf(ff,'];\n');
		eRecDeepGPNoCovars = [eRecDeepGPNoCovars errorRecDeepGPNoCovars]; fprintf(ff, 'errorRecDeepGPNoCovars = ['); fprintf(ff, '%.4f ', eRecDeepGPNoCovars); fprintf(ff,'];\n');
		fclose(ff);
	end
end

% Plots
fprintf('\n\n');
tt = 1:length(eMean);
plotFields = {'eMean','eLinReg','eGP', 'eGPfitc', 'eDeepGP'};
symb = getSymbols(length(plotFields));
for i=1:length(plotFields)
	plot(tt, eval(plotFields{i}), [symb{i} '-']); hold on;
	fprintf(1,'Mean error %s: %.4f\n', plotFields{i}, mean(eval(plotFields{i})))
end
legend(plotFields);

fprintf('\n\n');

%%  CLASSIFICATION Demo
fprintf(1,['', ...
 '#####  Classification demo: ####\n', ...
 'This demo shows classification using deep GPs.\n', ...
 'There are many ways to do classification in deep GPs:\n', ...
 'a) Data are given as inputs on the top level, labels are given\n', ...
 '   as outputs on the bottom level. This is similar to the regression setting.\n', ...
 '   The drawback is that what we would really want to do, is to have a\n', ...
 '   more appropriate likelihood in the bottom layer (e.g. sigmoid).\n', ...
 'b) MRD-style: one modality is the data, the other is the class-labels.\n', ...
 '   Then the latent space in the top layer is learned to separate the classes.\n', ...
 '   See the related MRD (Manifold Relevance Determination) demo in the\n', ...
 '   vargplvm package (which is a dependency for the present one). You can\n', ...
 '   form a deep-style MRD and infer the labels for new data points by\n', ...
 '   conditioning on the deep latent space.\n', ...
 'In this demo we take approach a).\n']);
 
fprintf('\n# Press any key to start demo...\n')
pause
clear; close all
pause(1)

demHsvargplvmClassification


%% --------  Collection of demos on digit data (demonstration) ----------------------%
fprintf(1,['', ...
 '#####  Digits demo collection: ####\n', ...
 'This is a collection of demos on the digit data. For this demonstration\n', ...
 'we use the pre-trained model discussed in the paper (5 level hierarchy).\n']);

fprintf('\n# Press any key to start demo...\n')
pause
clear; close all
demDigitsDemonstration
