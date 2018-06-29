%% 5. Apply DARTEL to Functional/Statistical/arbitrary native space images
% This is really just the same as (4), except that you may not want to
% average the output.
%
% INPUTS:
% DARTEL flow fields (deformation maps)
% An output directory path.
% Some native space images to be warped.
%  ---> Note that this is a list of lists (or rather cell array of cell
%  arrays), where each sub-list will have the same number of elements as
%  there are flow fields. So, you can think of it like: if you want to warp
%  the T1 and EPI data for each subject, the outter list would be 2
%  elements long (one for the T1, one for the EPI), and each inner list
%  would have the relevant volumes for each subject.
%
% OUTPUTS:
% Files prefixed with w, which are the DARTEL group-space warped version of
% the input.
% A file prefixed with wMean, which is the average of the first set of
% outputs.
%
% ---> Here is where you can inspect how clean the average group anatomy
% after DARTEL warping.
clear matlabbatch
matlabbatch = cell(1, 1); % Concatenating the warping and averaging.

% SET VARIABLES
% -------------
Dartel_FlowFields  = spm_file(OriginalT1, 'prefix', 'u_rc1', 'suffix', '_Template', 'ext', '.nii');
% HACK: This will break on anyone elses machine ...
% resultdir = 'D:\MRI\SoundPicture\results\ATLSearchlight\visual\final\solutionmaps\afni\error_centered_flipped';
resultdir = 'D:\MRI\SoundPicture\results\WholeBrain_RSA\wholebrain\semantic\featurenorms\cosine\centeredc\avg\visual\bysession\L1L2\visualization\final\solutionmaps\afni\nodestrength';
Results = fullfile(resultdir, arrayfun(@(x) sprintf('%02d_C.nii', x), (1:23)', 'Unif', 0));
% Results = spm_file(X,'prefix','r');
WarpedResults  = spm_file(Results, 'prefix', 'w');

AverageWarpedResults = 'mean_dartel_C.nii';
OutputDirectory = resultdir;

cd(OutputDirectory);

% Prepare for the averaging ...
n = 23;
cmd = strcat('(', strjoin(arrayfun(@(x) sprintf('i%d',x), 1:n, 'Unif', 0), '+'), sprintf(')/%d',n));

%% WARP
% ----
matlabbatch{1}.spm.tools.dartel.crt_warped.flowfields = Dartel_FlowFields;
matlabbatch{1}.spm.tools.dartel.crt_warped.images = {Results};
matlabbatch{1}.spm.tools.dartel.crt_warped.jactransf = 0;
matlabbatch{1}.spm.tools.dartel.crt_warped.K = 6;
matlabbatch{1}.spm.tools.dartel.crt_warped.interp = 1;

spm_jobman('run', matlabbatch)

%% AVERAGE
% -------
clear matlabbatch
for i = 1
    AverageWarpedResults = 'mean_visual.nii';
    matlabbatch{i}.spm.util.imcalc.input = WarpedResults; %
    matlabbatch{i}.spm.util.imcalc.output = AverageWarpedResults; %
    matlabbatch{i}.spm.util.imcalc.outdir = {OutputDirectory}; %
    matlabbatch{i}.spm.util.imcalc.expression = cmd; %
    matlabbatch{i}.spm.util.imcalc.options.dmtx = 0; %
    matlabbatch{i}.spm.util.imcalc.options.mask = 0; %
    matlabbatch{i}.spm.util.imcalc.options.interp = 1; %
    matlabbatch{i}.spm.util.imcalc.options.dtype = 16;
end
spm_jobman('run', matlabbatch)


%% RESAMPLE
%% --------
for i = 1
    AverageWarpedResults = 'mean_visual.nii';
    voxsiz = [3 3 3]; % new voxel size {mm}
    V = spm_vol(AverageWarpedResults);
    bb        = spm_get_bbox(V);
    VV(1:2)   = V;
    VV(1).mat = spm_matrix([bb(1,:) 0 0 0 voxsiz])*spm_matrix([-1 -1 -1]);
    VV(1).dim = ceil(VV(1).mat \ [bb(2,:) 1]' - 0.1)';
    VV(1).dim = VV(1).dim(1:3);
    spm_reslice(VV,struct('mean',false,'which',1,'interp',0)); % 1 for linear
end
%%
cd(rootdir);