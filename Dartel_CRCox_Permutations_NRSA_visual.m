%% 5b. Apply DARTEL to permutation native space images
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

%% SETUP VARIABLES
% Here is where you'll need to put in your environment and experiment
% specific information. I moved my T1s into a single directory, in part to
% simplify things and in part to not confuse the outputs of this script
% with any other output.
%
% SPM12 can work with either img/hdr or nii files. Most subsequent steps
% will yield nii files.
spmdir = 'C:/Users/mbmhscc4/MATLAB/Toolboxes/spm12/';
addpath(spmdir);
rootdir = 'D:\MRI\SoundPicture\data\DARTEL\';
OriginalT1 =  fullfile(rootdir, {
   'MD106_050913_T1W_IR_1150_SENSE_3_1.img,1'
   'MD106_050913B_T1W_IR_1150_SENSE_3_1.img,1'
   'MRH026_201_T1W_IR_1150_SENSE_3_1.img,1'
   'MRH026_202_T1W_IR_1150_SENSE_3_1.img,1'
   'MRH026_203_T1W_IR_1150_SENSE_3_1.img,1'
   'MRH026_204_T1W_IR_1150_SENSE_3_1.img,1'
   'MRH026_205_T1W_IR_1150_SENSE_3_1.img,1'
   'MRH026_206_T1W_IR_1150_SENSE_3_1.img,1'
   'MRH026_207_T1W_IR_1150_SENSE_3_1.img,1'
   'MRH026_208_T1W_IR_1150_SENSE_3_1.img,1'
   'MRH026_209_T1W_IR_1150_SENSE_3_1.img,1'
   'MRH026_210_T1W_IR_1150_SENSE_3_1.img,1'
   'MRH026_211_T1W_IR_1150_SENSE_3_1.img,1'
   'MRH026_212_T1W_IR_1150_SENSE_3_1.img,1'
   'MRH026_213_T1W_IR_1150_SENSE_3_1.img,1'
   'MRH026_214_T1W_IR_1150_SENSE_3_1.img,1'
   'MRH026_215_T1W_IR_1150_SENSE_3_1.img,1'
   'MRH026_216_T1W_IR_1150_SENSE_3_1.img,1'
   'MRH026_217_T1W_IR_1150_SENSE_3_1.img,1'
   'MRH026_218_T1W_IR_1150_SENSE_3_1.img,1'
   'MRH026_219_T1W_IR_1150_SENSE_3_1.img,1'
   'MRH026_220_T1W_IR_1150_SENSE_3_1.img,1'
   'MRH026_221_T1W_IR_1150_SENSE_3_1.img,1'
});
TPM = strcat(fullfile(spmdir, 'tpm','TPM.nii'), {',1';',2';',3';',4';',5';',6'});
clear matlabbatch
% Concatenating the warping and averaging.

Dartel_FlowFields  = spm_file(OriginalT1, 'prefix', 'u_rc1', 'suffix', '_Template', 'ext', '.nii');
permutationsdir = 'D:\MRI\SoundPicture\results\WholeBrain_RSA\wholebrain\semantic\featurenorms\cosine\centeredc\avg\visual\bysession\L1L2\visualization\permutations_tuned\solutionmaps\afni\nodestrength';
resultsdir = 'D:\MRI\SoundPicture\results\WholeBrain_RSA\wholebrain\semantic\featurenorms\cosine\centeredc\avg\visual\bysession\L1L2\visualization\final\solutionmaps\afni\nodestrength';
% 'D:\MRI\SoundPicture\results\ATLSearchlight\visual\permutations\solutionmaps\afni\error_centered_flipped'
% 'D:\MRI\SoundPicture\results\ATLSearchlight\visual\final\solutionmaps\afni\error_centered_flipped\rmean_dartel_C.nii'

Results = cell(100,1);
WarpedResults = cell(100,1);
for r = 1:100
    Results{r} = fullfile(permutationsdir, arrayfun(@(x) sprintf('%03d_%02d_C.nii', r, x), (1:23)', 'Unif', 0));
    WarpedResults{r}  = spm_file(Results{r}, 'prefix', 'w', 'path', permutationsdir);
end
AverageWarpedResults = 'mean_dartel_C.nii';
OutputDirectory = permutationsdir;

% Prepare for the averaging ...
n = numel(WarpedResults);
cmd = strcat('(', strjoin(arrayfun(@(x) sprintf('i%d',x), 1:n, 'Unif', 0), '+'), sprintf(')/%d',n));

%% WARP
matlabbatch{1}.spm.tools.dartel.crt_warped.flowfields = Dartel_FlowFields;
matlabbatch{1}.spm.tools.dartel.crt_warped.images = Results;
matlabbatch{1}.spm.tools.dartel.crt_warped.jactransf = 0;
matlabbatch{1}.spm.tools.dartel.crt_warped.K = 6;
matlabbatch{1}.spm.tools.dartel.crt_warped.interp = 1;

spm_jobman('run', matlabbatch)

%% Move output
% manual step, at the moment

%% CONCATENATE
WarpedResultsM = cat(2,WarpedResults{:})';
WarpedResultsBySubject = cell(23,1);
matlabbatch = cell(23, 1);
for s = 1:23
    WarpedResultsBySubject{s} = sprintf('%d_dartel.nii', s);
    matlabbatch{s}.spm.util.cat.vols = WarpedResultsM(:,s);
    matlabbatch{s}.spm.util.cat.name = WarpedResultsBySubject{s};
    matlabbatch{s}.spm.util.cat.dtype = 0;
end
spm_jobman('run', matlabbatch)

%% Resample % 
clear matlabbatch
matlabbatch = cell(23, 1);
for s = 1:23
    matlabbatch{s}.spm.spatial.coreg.write.ref = {fullfile(resultsdir, 'rmean_visual.nii')};
    matlabbatch{s}.spm.spatial.coreg.write.source = {fullfile(permutationsdir, WarpedResultsBySubject{s})};
    matlabbatch{s}.spm.spatial.coreg.write.roptions.interp = 4;
    matlabbatch{s}.spm.spatial.coreg.write.roptions.wrap = [0 0 0];
    matlabbatch{s}.spm.spatial.coreg.write.roptions.mask = 0;
    matlabbatch{s}.spm.spatial.coreg.write.roptions.prefix = 'r';
end

spm_jobman('run', matlabbatch)

%% GZIP
% ----
clear matlabbatch
ResampledWarpedResultsBySubject = spm_file(fullfile(permutationsdir, WarpedResultsBySubject), 'prefix', 'r');
matlabbatch{1}.cfg_basicio.file_dir.file_ops.cfg_gzip_files.files = ResampledWarpedResultsBySubject;
matlabbatch{1}.cfg_basicio.file_dir.file_ops.cfg_gzip_files.outdir = {''};
matlabbatch{1}.cfg_basicio.file_dir.file_ops.cfg_gzip_files.keep = false;

spm_jobman('run', matlabbatch)