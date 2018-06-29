function [job] = SetupSegmentation(OriginalT1, TPM)
% SETUPSEGMENTATION Return job description for segmenting T1 images
%
% This function implements all the defaults/recommendations as of SPM12 and
% based on whatever reading of docs I did (as of mid-2017).
%
% This function does not launch any SPM procedures. It only returns the
% instructions. Execute the output with spm_jobman('run', jobs).
%
% Inputs
%  OriginalT1 : A cell array of file paths pointing to T1 images.
%  TPM : A string expressing the path to the tissue probability maps to
%        inform segmentation (distributed with SPM).
%
% Output
%  job : A structure that SPM can interpret with spm_jobman('run', {job}).
%
    p = inputParser();
    addRequired(p, 'OriginalT1', @iscell);
    addRequired(p, 'TPM', @ischar);
    parse(p, OriginalT1, TPM);
    
    job = cell(1);
    job{1}.spm.spatial.preproc.channel.vols = OriginalT1;
    job{1}.spm.spatial.preproc.channel.biasreg = 0.001;
    job{1}.spm.spatial.preproc.channel.biasfwhm = 60;
    job{1}.spm.spatial.preproc.channel.write = [0 0];
    job{1}.spm.spatial.preproc.tissue(1).tpm = spm_file(TPM, 'number', 1);
    job{1}.spm.spatial.preproc.tissue(1).ngaus = 1;
    job{1}.spm.spatial.preproc.tissue(1).native = [1 1]; % The second bit ensures that we get rc1
    job{1}.spm.spatial.preproc.tissue(1).warped = [0 0];
    job{1}.spm.spatial.preproc.tissue(2).tpm = spm_file(TPM, 'number', 2);
    job{1}.spm.spatial.preproc.tissue(2).ngaus = 1;
    job{1}.spm.spatial.preproc.tissue(2).native = [1 1]; % The second bit ensures that we get rc2
    job{1}.spm.spatial.preproc.tissue(2).warped = [0 0];
    job{1}.spm.spatial.preproc.tissue(3).tpm = spm_file(TPM, 'number', 3);
    job{1}.spm.spatial.preproc.tissue(3).ngaus = 2;
    job{1}.spm.spatial.preproc.tissue(3).native = [1 0];
    job{1}.spm.spatial.preproc.tissue(3).warped = [0 0];
    job{1}.spm.spatial.preproc.tissue(4).tpm = spm_file(TPM, 'number', 4);
    job{1}.spm.spatial.preproc.tissue(4).ngaus = 3;
    job{1}.spm.spatial.preproc.tissue(4).native = [0 0]; % by setting both bits to 0, we suppress output.
    job{1}.spm.spatial.preproc.tissue(4).warped = [0 0];
    job{1}.spm.spatial.preproc.tissue(5).tpm = spm_file(TPM, 'number', 5);
    job{1}.spm.spatial.preproc.tissue(5).ngaus = 4;
    job{1}.spm.spatial.preproc.tissue(5).native = [0 0]; % by setting both bits to 0, we suppress output.
    job{1}.spm.spatial.preproc.tissue(5).warped = [0 0];
    job{1}.spm.spatial.preproc.tissue(6).tpm = spm_file(TPM, 'number', 6);
    job{1}.spm.spatial.preproc.tissue(6).ngaus = 2;
    job{1}.spm.spatial.preproc.tissue(6).native = [0 0]; % by setting both bits to 0, we suppress output.
    job{1}.spm.spatial.preproc.tissue(6).warped = [0 0];
    job{1}.spm.spatial.preproc.warp.mrf = 1;
    job{1}.spm.spatial.preproc.warp.cleanup = 1;
end