%% DARTEL warp pipeline in SPM12
% The DARTEL procedure produces impressive alignment across subjects, but
% is a multistep process that generates many files and involves a variety
% of SPM functionality.
%
% In the following, I have scripted this process for *SPM12*. It includes
% the following processing steps:
%
% 1. Segmentation of the T1 into (at minimum) grey and white matter.
% Segmentation operates independently on each subject, and so in principle
% could be done in parallel on CSF to save time. As it stands, this step
% takes a while for 20+ subjects.
%
% 2. Building DARTEL templates which warp each subject's T1 to a group
% space---not a common template like MNI, but a group space defined
% essentially by a group average. This step requires the Grey and
% White-matter maps for all subjects at once, and so cannot easily be
% parallelized. This is the most time consuming step, and there's not much
% to be done about it.
%
% 3. Warping native data to MNI, using a combination of the output from (2)
% and an affine transformation.
%
% 4. Warping the individual T1 images to the group space, and averaging.
% This average map will both give a sense of how well the subjects have
% been aligned (which corresponds to the sharpness and clarity of the gyrii
% after averaging), and will also provide an underlay for presenting
% group-aligned results.
%
% 5a. Warping functional results to group space. This is the same procedure
% as in (4). It includes a resampling step to get the warped data back to
% original functional resolution, in case that's something you want to do.
%
% 5b. This is essentially the same as 5a, except applied to a set of 4-D
% datasets. It also includes a resampling step, as well as a gzip step.
% Gzipping big files not only saves disk space, but can speed up loading
% times since reading from disk is slower than the decompression for large
% enough files.
%
% The output from 4 and 5a,b could be moved to MNI space with a standard
% affine, I believe. Or (I *think*) the process in 4 and 5 could just be
% replaced with the process in 3, which applied the Dartel warp followed by
% an afffine. I'm not totally confident about what is best in this regard. 
% - Chris Cox, 16/10/2017
%
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
TPM = fullfile(spmdir, 'tpm','TPM.nii');

%% 1. Segmentation
% DARTEL will use the grey and white matter segmentations while iteratively
% aligning brains to one another and ultimately to a MNI template. So,
% segmentation is step 1. This step operates on the T1's. For the most part
% these are the default options, except that the first two tissue types
% (grey and white matter, respectively) have been flagged so that they
% output segmentations in a particular way that the DARTEL tool expects.
%
% INPUTS:
% OriginalT1
%
% OUTPUTS:
% Nifti files prefixed with c1-3, and rc1-2 (for DARTEL).
matlabbatch = SetupSegmentation(OriginalT1, TPM);
spm_jobman('run', matlabbatch)

%% 2. Build DARTEL Templates
% INPUTS:
% Files prefixed rc1 and rc2 for all subjects, which are the grey- and
% white-matter segmentations.
%
% All parameters are left at their defaults.
%
% OUTPUTS:
% Files called Template_{0..6}.nii, where each template is inceasingly
% sharp and well aligned across subjects.
%
% Files prefixed u_rc1, which are the deformation maps for each subject.
% These can be used to move images in each subject's native space into the
% DARTEL group space.
DartelImport_GreyMatter  = spm_file(OriginalT1, 'prefix', 'rc1', 'ext', '.nii', 'number', 1);
DartelImport_WhiteMatter = spm_file(OriginalT1, 'prefix', 'rc2', 'ext', '.nii', 'number', 1);

matlabbatch = SetupDartel(DartelImport_GreyMatter, DartelImport_WhiteMatter);

spm_jobman('run', matlabbatch)

%% 3. To MNI
% It appears that this step permits the following: based on the flow fields
% (deformation maps) for each subject, the Template_6.nii final output from
% the DARTEL pipeline, and a normalized MNI image (which SPM takes to be
% the TPM.nii map shipped with the distribution), native space images can
% be taken through the series of transformations, first to group space and
% then to MNI space. The MNI space transformation, as I understand it, is a
% basic affine transform by default.
%
% INPUTS:
% DARTEL deformation maps (flow fields) for each subject.
% DARTEL Template_6.nii
% Whatever it is you would like to pass through DARTEL group space into MNI
% common space.
% 
% OUTPUTS:
% Files with prefix sw which are warped to MNI space and smoothed.
%
% ---> The default blur of the MNI-normalized images is [8,8,8] mm.

Dartel_FlowFields  = spm_file(OriginalT1, 'prefix', 'u_rc1', 'suffix', '_Template', 'ext', '.nii');
Native_GreyMatter  = spm_file(OriginalT1, 'prefix', 'c1', 'ext', '.nii');
Dartel_Template6 = fullfile(rootdir,'Template_6.nii');
OriginalT1_noIndex = spm_file(OriginalT1, 'ext', '.img');

matlabbatch = SetupMNI( ...
    Dartel_Template6, ...
    Dartel_FlowFields, ...
    {Native_GreyMatter,OriginalT1_noIndex}, ...
    'fwhm', [4,4,4]);

spm_jobman('run', matlabbatch(1))

%% Interlude

% % % From here on, it becomes pretty project specific % % %


%% 4. Apply DARTEL to T1s (and average the warps)
% This rather than going all the way to MNI space, as in the prior step, it
% is possible to project any native space image into the DARTEL group space
% for your study.
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

% WARP
% ----
Dartel_FlowFields  = spm_file(OriginalT1, 'prefix', 'u_rc1', 'suffix', '_Template', 'ext', '.nii');
[matlabbatch,warp_prefix] = ApplyDartel(Dartel_FlowFields, {OriginalT1});
spm_jobman('run', matlabbatch)

% AVERAGE
% -------
WarpedT1  = spm_file(OriginalT1, 'prefix', 'w');
AveragedWarpedT1 = 'wMean_T1W_IR_1150_SENSE_3_1.nii';
OutputDirectory = rootdir;
matlabbatch = AverageImages( WarpedT1, AveragedWarpedT1, OutputDirectory );

spm_jobman('run', matlabbatch)

%% EXTRA: Coregister oblique images to T1 (maybe this can be skipped)

SubjectCode =  {...
    'MD106_050913';'MD106_050913B';'MRH026_201';'MRH026_202';'MRH026_203'; ...
    'MRH026_204';'MRH026_205';'MRH026_206';'MRH026_207';'MRH026_208'; ...
    'MRH026_209';'MRH026_210';'MRH026_211';'MRH026_212';'MRH026_213'; ...
    'MRH026_214';'MRH026_215';'MRH026_216';'MRH026_217';'MRH026_218'; ... 
    'MRH026_219';'MRH026_220';'MRH026_221'};

y = repmat({'right';'left'},ceil(numel(SubjectCode)/2),1);

OutputDirectory = {''};

matlabbatch = cell(numel(SubjectCode),2);
for i = 1:numel(SubjectCode)
    ImagesToAverage = fullfile( ...
        'D:\MRI\SoundPicture\data\RickRaw', ...
        sprintf('%d_%syes', i+1, y{i}), ... % subject directory
        sprintf('%s_WIP_RUN_1_DE_SENSE_7_1_short', SubjectCode{i}), ... % run directory
        arrayfun(@(x) sprintf('u%04d.img',x), 1:172, 'Unif', 0)); % filenames
    MeanEPI = fullfile( ...
        'D:\MRI\SoundPicture\data\CoregistrationAttempt', ...
        sprintf('mean%s.img',SubjectCode{i}));
    
    ResultsToCoregister = {};
    
    matlabbatch{i,1} = AverageImages(ImagesToAverage, MeanEPI, OutputDirectory);
    matlabbatch{i,2} = SetupCoregistration(OriginalT1{1},MeanEPI);
end
% Average
spm_jobman('run', matlabbatch(:,1));
% Coregister
spm_jobman('run', matlabbatch(:,2));

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
resultdir = 'D:\MRI\SoundPicture\results\RSA_Toolbox_Analysis\audio\final\Maps';
% Results = fullfile(resultdir, arrayfun(@(x) sprintf('%02d_C.nii', x), (1:23)', 'Unif', 0));
Results = spm_file(X,'prefix','r');
WarpedResults  = spm_file(Results, 'prefix', 'w');

Results = cellfun(@transpose, mat2cell(Results,ones(4,1),23), 'unif', 0);
WarpedResults = cellfun(@transpose, mat2cell(WarpedResults,ones(4,1),23), 'unif', 0);
AverageWarpedResults = 'mean_dartel_C.nii';
OutputDirectory = resultdir;

cd(OutputDirectory);

% Prepare for the averaging ...
n = 23;
cmd = strcat('(', strjoin(arrayfun(@(x) sprintf('i%d',x), 1:n, 'Unif', 0), '+'), sprintf(')/%d',n));

% WARP
% ----
matlabbatch{1}.spm.tools.dartel.crt_warped.flowfields = Dartel_FlowFields;
matlabbatch{1}.spm.tools.dartel.crt_warped.images = Results;
matlabbatch{1}.spm.tools.dartel.crt_warped.jactransf = 0;
matlabbatch{1}.spm.tools.dartel.crt_warped.K = 6;
matlabbatch{1}.spm.tools.dartel.crt_warped.interp = 1;

spm_jobman('run', matlabbatch)

% AVERAGE
% -------
clear matlabbatch
matlabbatch = cell(4,1);
for i = 1:4
    AverageWarpedResults = sprintf('mean_%s_rMap_mask_%s.nii', Modality, Conditions{i});
    matlabbatch{i}.spm.util.imcalc.input = WarpedResults{i}; %
    matlabbatch{i}.spm.util.imcalc.output = AverageWarpedResults; %
    matlabbatch{i}.spm.util.imcalc.outdir = {OutputDirectory}; %
    matlabbatch{i}.spm.util.imcalc.expression = cmd; %
    matlabbatch{i}.spm.util.imcalc.options.dmtx = 0; %
    matlabbatch{i}.spm.util.imcalc.options.mask = 0; %
    matlabbatch{i}.spm.util.imcalc.options.interp = 1; %
    matlabbatch{i}.spm.util.imcalc.options.dtype = 16;
end
spm_jobman('run', matlabbatch)

% RESAMPLE
% --------
for i = 1:3
    AverageWarpedResults = sprintf('mean_%s_rMap_mask_%s.nii', Modality, Conditions{i});
    voxsiz = [3 3 3]; % new voxel size {mm}
    V = spm_vol(AverageWarpedResults);
    bb        = spm_get_bbox(V);
    VV(1:2)   = V;
    VV(1).mat = spm_matrix([bb(1,:) 0 0 0 voxsiz])*spm_matrix([-1 -1 -1]);
    VV(1).dim = ceil(VV(1).mat \ [bb(2,:) 1]' - 0.1)';
    VV(1).dim = VV(1).dim(1:3);
    spm_reslice(VV,struct('mean',false,'which',1,'interp',0)); % 1 for linear
end

cd(rootdir);

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
% Files prefixed with rw, which are the resampled versions of the above.
% 
% N.B. Final output will be rw*.nii.gz files. However, the full resolution
% and uncompressed w files will remain. These might be huge, so if you are
% happy with the resampled versions, it might be good to delete them. At
% the very least, be aware that the w files also exist and are large.
%
% N.B. Currently, I warp and then concatenate. This is less efficient in
% terms of disk space. In this case, I am concatenating such that there is
% one file per subject, each containing N solutions based on N permutations
% of the training set. I did it this way because, up to this point, I've
% only applied Dartel warps to 3D datasets. So I warp each 3D dataset, then
% concatenate them, which doubles the most disk hungry step. The native
% space data is at a lower resolution than after warping. So, in short, I
% should be concatenating first... but I have not tested that.
%
% ---> Here is where you can inspect how clean the average group anatomy
% after DARTEL warping.
clear matlabbatch

% SET VARIABLES
% -------------
Dartel_FlowFields  = spm_file(OriginalT1, 'prefix', 'u_rc1', 'suffix', '_Template', 'ext', '.nii');
% HACK: This will break on anyone elses machine ...
resultdir = 'D:\MRI\SoundPicture\results\ATLSearchlight\audio\permutations\solutionmaps\afni\error_centered_flipped';
Results = cell(100,1);
WarpedResults = cell(100,1);
for r = 1:100
    Results{r} = fullfile(resultdir, arrayfun(@(x) sprintf('%03d_%02d_C.nii', r, x), (1:23)', 'Unif', 0));
    WarpedResults{r}  = spm_file(Results{r}, 'prefix', 'w', 'path', resultdir);
end
OutputDirectory = resultdir;

% CONCATENATE
% -----------
ResultsM = cat(2,Results{:})';
ResultsBySubject = cell(23,1);
matlabbatch = cell(23, 1);
for s = 1:23
    ResultsBySubject{s} = sprintf('%02d_orig.nii', s);
    matlabbatch{s}.spm.util.cat.vols = ResultsM(:,s);
    matlabbatch{s}.spm.util.cat.name = ResultsBySubject{s};
    matlabbatch{s}.spm.util.cat.dtype = 0;
end
spm_jobman('run', matlabbatch)

% WARP
% ----
matlabbatch{1}.spm.tools.dartel.crt_warped.flowfields = Dartel_FlowFields;
matlabbatch{1}.spm.tools.dartel.crt_warped.images = ResultsBySubject;
matlabbatch{1}.spm.tools.dartel.crt_warped.jactransf = 0;
matlabbatch{1}.spm.tools.dartel.crt_warped.K = 6;
matlabbatch{1}.spm.tools.dartel.crt_warped.interp = 1;

spm_jobman('run', matlabbatch)


% RESAMPLE
% --------
clear matlabbatch
matlabbatch = cell(23, 1);
for s = 1:23
    % HACK: This will break on anyone elses machine ...
    matlabbatch{s}.spm.spatial.coreg.write.ref = {'D:\MRI\SoundPicture\results\ATLSearchlight\visual\final\solutionmaps\afni\error_centered_flipped\rmean_dartel_C.nii'};
    matlabbatch{s}.spm.spatial.coreg.write.source = {fullfile(resultdir, WarpedResultsBySubject{s})};
    matlabbatch{s}.spm.spatial.coreg.write.roptions.interp = 4;
    matlabbatch{s}.spm.spatial.coreg.write.roptions.wrap = [0 0 0];
    matlabbatch{s}.spm.spatial.coreg.write.roptions.mask = 0;
    matlabbatch{s}.spm.spatial.coreg.write.roptions.prefix = 'r';
end

spm_jobman('run', matlabbatch)

% GZIP
% ----
ResampledWarpedResultsBySubject = spm_file(fullfile(resultdir, WarpedResultsBySubject), 'prefix', 'r');
matlabbatch{1}.cfg_basicio.file_dir.file_ops.cfg_gzip_files.files = ResampledWarpedResultsBySubject;
matlabbatch{1}.cfg_basicio.file_dir.file_ops.cfg_gzip_files.outdir = {''};
matlabbatch{1}.cfg_basicio.file_dir.file_ops.cfg_gzip_files.keep = false;

spm_jobman('run', matlabbatch)