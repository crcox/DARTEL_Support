function [job] = SetupDartel(GreySegment, WhiteSegment)
% SETUPDARTEL Return job description for generating DARTEL deformation fields
%
% This function implements all the defaults/recommendations as of SPM12 and
% based on whatever reading of docs I did (as of mid-2017).
%
% This function does not launch any SPM procedures. It only returns the
% instructions. Execute the output with spm_jobman('run', jobs).
%
% Inputs
%  GreySegment : A cell array of file paths pointing to grey-matter
%                segmentations, one per subject.
%  WhiteSegment : A cell array of file paths pointing to white-matter
%                 segmentations, one per subject.
%
% Function assumes that GreySegment(i) and WhiteSegment(i) will refer to
% data from the same subject.
%
% Output
%  job : A structure that SPM can interpret with spm_jobman('run', {job}).
%

    p = inputParser();
    addRequired(p, 'GreySegment', @iscell);
    addRequired(p, 'WhiteSegment', @iscell);
    parse(p, GreySegment, WhiteSegment);
    
    job = cell(1);
    job{1}.spm.tools.dartel.warp.images = {GreySegment, WhiteSegment};
    job{1}.spm.tools.dartel.warp.settings.template = 'Template';
    job{1}.spm.tools.dartel.warp.settings.rform = 0;
    job{1}.spm.tools.dartel.warp.settings.param(1).its = 3;
    job{1}.spm.tools.dartel.warp.settings.param(1).rparam = [4 2 1e-06];
    job{1}.spm.tools.dartel.warp.settings.param(1).K = 0;
    job{1}.spm.tools.dartel.warp.settings.param(1).slam = 16;
    job{1}.spm.tools.dartel.warp.settings.param(2).its = 3;
    job{1}.spm.tools.dartel.warp.settings.param(2).rparam = [2 1 1e-06];
    job{1}.spm.tools.dartel.warp.settings.param(2).K = 0;
    job{1}.spm.tools.dartel.warp.settings.param(2).slam = 8;
    job{1}.spm.tools.dartel.warp.settings.param(3).its = 3;
    job{1}.spm.tools.dartel.warp.settings.param(3).rparam = [1 0.5 1e-06];
    job{1}.spm.tools.dartel.warp.settings.param(3).K = 1;
    job{1}.spm.tools.dartel.warp.settings.param(3).slam = 4;
    job{1}.spm.tools.dartel.warp.settings.param(4).its = 3;
    job{1}.spm.tools.dartel.warp.settings.param(4).rparam = [0.5 0.25 1e-06];
    job{1}.spm.tools.dartel.warp.settings.param(4).K = 2;
    job{1}.spm.tools.dartel.warp.settings.param(4).slam = 2;
    job{1}.spm.tools.dartel.warp.settings.param(5).its = 3;
    job{1}.spm.tools.dartel.warp.settings.param(5).rparam = [0.25 0.125 1e-06];
    job{1}.spm.tools.dartel.warp.settings.param(5).K = 4;
    job{1}.spm.tools.dartel.warp.settings.param(5).slam = 1;
    job{1}.spm.tools.dartel.warp.settings.param(6).its = 3;
    job{1}.spm.tools.dartel.warp.settings.param(6).rparam = [0.25 0.125 1e-06];
    job{1}.spm.tools.dartel.warp.settings.param(6).K = 6;
    job{1}.spm.tools.dartel.warp.settings.param(6).slam = 0.5;
    job{1}.spm.tools.dartel.warp.settings.optim.lmreg = 0.01;
    job{1}.spm.tools.dartel.warp.settings.optim.cyc = 3;
    job{1}.spm.tools.dartel.warp.settings.optim.its = 3;
end