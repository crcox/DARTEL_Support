function [job] = SetupMNI(Dartel_Template6, Dartel_FlowFields, ChildImages, varargin)
% SETUPMNI Return job description for warping Dartel template to MNI
%
% This function implements all the defaults/recommendations as of SPM12 and
% based on whatever reading of docs I did (as of mid-2017).
%
% This function does not launch any SPM procedures. It only returns the
% instructions. Execute the output with spm_jobman('run', jobs).
%
% Inputs
%  Dartel_Template6 : A string pointing to the 6th and final Dartel
%                     template.
%  Dartel_FlowFields : A cell array of file paths pointing to Dartel flow
%                      fields, one per subject.
%  ChildImages : A cell array of cell arrays
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
    addRequired(p, 'Dartel_Template6', @ischar);
    addRequired(p, 'Dartel_FlowFields', @iscell);
    addRequired(p, 'ChildImages', @isArrayOfCells);
    addParameter(p, 'fwhm', [8,8,8], @isThreeElementVector);
    parse(p, Dartel_Template6, Dartel_FlowFields, ChildImages, varargin{:});
    
    job = cell(1);
    job{1}.spm.tools.dartel.mni_norm.template = {Dartel_Template6};
    job{1}.spm.tools.dartel.mni_norm.data.subjs.flowfields = Dartel_FlowFields;
    job{1}.spm.tools.dartel.mni_norm.data.subjs.images = ChildImages;
    job{1}.spm.tools.dartel.mni_norm.vox = [NaN NaN NaN];
    job{1}.spm.tools.dartel.mni_norm.bb = [NaN NaN NaN
                                           NaN NaN NaN];
    job{1}.spm.tools.dartel.mni_norm.preserve = 0;
    job{1}.spm.tools.dartel.mni_norm.fwhm = p.Results.fwhm;
end
