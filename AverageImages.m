function [ job ] = AverageImages( ImagesToAverage, OutputName, varargin )
%AVERAGEIMAGES Voxelwise mean over images using imcalc.
%
% This function does not launch any SPM procedures. It only returns the
% instructions. Execute the output with spm_jobman('run', jobs).
%
% Input
%   ImagesToAverage : A cell array of strings that are paths pointing to
%                     NIFTI images to average.
%   OutputName : A filename for the average image to be saved as. Can
%                either be a base-filename or a full path.
%
% Optional Positional Arguments
%   OutputDir : A string specifying a path to a directory where the
%   average image should be written. Not necessary if the OutputName
%   specifies a full path, or if the output should be written to the
%   current working directory.
%
% Optional KeyValue Arguments
%   AsMatrix : This affects the command passed to imcalc. The output should
%   be equivalent in either case.
%
% Output
%  job : A structure that SPM can interpret with spm_jobman('run', {job}).
%
    p = inputParser();
    addRequired(p, 'ImagesToAverage', @iscell);
    addRequired(p, 'OutputName', @ischar);
    addOptional(p, 'OutputDir', [], @ischar);
    addParameter(p, 'AsMatrix', false, @islogical);
    parse(p, ImagesToAverage, OutputName, varargin{:});
    if isempty(p.Results.OutputDir)
        [outdir,f,e] = fileparts(p.Results.OutputName);
        outfile = strcat(f,e);
    end
    
    
    if p.Results.AsMatrix
        cmd = 'mean(X)';
        dmtx = 1;
    else
        n = numel(p.Results.ImagesToAverage);
        cmd = strcat('(', strjoin(arrayfun(@(x) sprintf('i%d',x), 1:n, 'Unif', 0), '+'), sprintf(')/%d',n));
        dmtx = 0;
    end
    
    job = cell(1);
    job{1}.spm.util.imcalc.input = p.Results.ImagesToAverage;
    job{1}.spm.util.imcalc.output = outfile;
    job{1}.spm.util.imcalc.outdir = {outdir};
    job{1}.spm.util.imcalc.expression = cmd; 
    job{1}.spm.util.imcalc.options.dmtx = dmtx;
    job{1}.spm.util.imcalc.options.mask = 0;
    job{1}.spm.util.imcalc.options.interp = 1;
    job{1}.spm.util.imcalc.options.dtype = 8;

end

