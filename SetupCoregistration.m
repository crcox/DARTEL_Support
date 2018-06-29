function [job] = SetupCoregistration(ReferenceImage, SourceImage, varargin)
% SETUPCOREGISTRATION Return job description for intra-modal coregistration
%
% This function implements all the defaults/recommendations as of SPM12 and
% based on whatever reading of docs I did (as of mid-2017).
%
% This function does not launch any SPM procedures. It only returns the
% instructions. Execute the output with spm_jobman('run', jobs).
%
% Inputs
%  ReferenceImage : A string pointing to the reference volume
%  SourceImage : A cell array of file paths pointing to the image to be
%                moved.
%  ChildImages : A cell array of cell arrays containing images to also
%                apply the warp to.
%
% Optional Key-value arguments:
%  fwhm : Controls the smoothing applied to images after normalization to
%  MNI space, defined as a 3 element vector. Default [8,8,8] (millimeters).
%
% Function assumes that Dartel_Flowfields(i) and ChildImages{j}(i) will
% refer to data from the same subject.
%
% Output
%  job : A structure that SPM can interpret with spm_jobman('run', {job}).
%
    p = inputParser();
    addRequired(p, 'ReferenceImage', @ischar);
    addRequired(p, 'SourceImage', @ischar);
    addOptional(p, 'ChildImages', {}, @iscell);
    parse(p, ReferenceImage, SourceImage, varargin{:});

    job = cell(1);
    job{1}.spm.spatial.coreg.estwrite.ref = {ReferenceImage};
    job{1}.spm.spatial.coreg.estwrite.source = {spm_file(SourceImage,'number',1)};
    job{1}.spm.spatial.coreg.estwrite.other = p.Results.ChildImages;
    job{1}.spm.spatial.coreg.estwrite.eoptions.cost_fun = 'nmi';
    job{1}.spm.spatial.coreg.estwrite.eoptions.sep = [4 2];
    job{1}.spm.spatial.coreg.estwrite.eoptions.tol = [0.02 0.02 0.02 0.001 0.001 0.001 0.01 0.01 0.01 0.001 0.001 0.001];
    job{1}.spm.spatial.coreg.estwrite.eoptions.fwhm = [7 7];
    job{1}.spm.spatial.coreg.estwrite.roptions.interp = 4;
    job{1}.spm.spatial.coreg.estwrite.roptions.wrap = [0 0 0];
    job{1}.spm.spatial.coreg.estwrite.roptions.mask = 0;
    job{1}.spm.spatial.coreg.estwrite.roptions.prefix = 'r';
end