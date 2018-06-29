function [jobs] = ApplyDartelAndMNI(DARTEL_Template_6, DARTEL_FlowFields, Images, varargin)
% APPLYDARTELANDMNI Return job descriptions for applying DARTEL deformation fields
%
% This function implements all the defaults/recommendations as of SPM12 and
% based on whatever reading of docs I did (as of mid-2017).
%
% This function does not launch any SPM procedures. It only returns the
% instructions. Execute the output with spm_jobman('run', jobs).
%
% Inputs
%   DARTEL_Template_6 : The path the Template 6
%
%   DARTEL_FlowFields : A cell array of file paths pointing to Dartel flow
%                       fields, one per subject.
%
%   Images : A cell array of cell arrays, each containing a list of files to be
%            warped with each flowfield.
%
%   fwhm   : The size of the gaussian kernel, in mm, used to smooth the data
%            after ariving in MNI space. SPM default is [8 8 8], default of this
%            function is [4 4 4].
%
%   OutputVoxelSize : Size of the voxels of the MNI space images.
%
%   GZipInput : SPM cannot directly read compressed files. When chaining
%   operations together, it may make more sense to leave .nii output
%   uncompressed on disk so that it does not need to be extracted (on disk)
%   before SPM can use it. However, once the next step in the processing
%   stream has occured, it probably makes sense to compress the input.
%
%   GZipOutput : Compress the output and delete the uncompressed version.
%   This is useful at the end of a processing stream, but for intermediate
%   steps it will only force the next step to extract the data on disk.
%
%   DeleteFlowFields : The Dartel-warped output will be written into the
%   directory where the flow fields are. As part of the pipeline,
%   therefore, we may choose to copy the flow fields into the directory
%   containing the results being warped. However, these copies of the
%   original flow fields are not necessary after being applied. Set this
%   flag to true to delete them after warping the data.
%
% Function assumes that DARTEL_Flowfields(i) and ChildImages{j}(i) will
% refer to data from the same subject.
%
% Output
%  job : A structure that SPM can interpret with spm_jobman('run', {job}).
%

    p = inputParser();
    addRequired(p, 'DARTEL_Template_6');%, @iscell);
    addRequired(p, 'DARTEL_FlowFields');%, @iscell);
    addRequired(p, 'Images');%, @isArrayOfCells);
    addParameter(p, 'fwhm', [4,4,4], @isnumeric);
    addParameter(p, 'OutputVoxelSize', [3,3,3], @isnumeric);
    addParameter(p, 'GZipInput', false, @islogical);
    addParameter(p, 'GZipOutput', false, @islogical);
    addParameter(p, 'DeleteFlowFields', false, @islogical);
    parse(p, DARTEL_FlowFields, ChildImages, varargin{:});

    UNPACK = false;
    DELETE = false;
    REPACK = false;

    % Force ChildImages to be a column vector of cells containing column-
    % vectorized cellstrs.
    tmp = cellfun(@(x) x(:), ChildImages(:), 'UniformOutput', 0);
    fileFlatList = cat(1, tmp{:});
    z = ~cellfun('isempty', regexp(fileFlatList, '\.gz$'));
    if any(z)
        UNPACK = true;
        DELETE = UNPACK;
        REPACK = ~all(z);

        fileFlatList_nii = regexprep(fileFlatList, '\.gz$', '');
        ChildImages_nii = mat2cell( ...
            fileFlatList_nii, ...
            cellfun('prodofsize', ChildImages), 1);

        fileFlatList_gz = fileFlatList(z);
        fileFlatList_nii_nogz = fileFlatList(~z);
        fileFlatList_nii_yesgz = fileFlatList_nii(z);

    elseif p.Results.GZipInput
        REPACK = true;
        fileFlatList_nii = fileFlatList;
        fileFlatList_nii_nogz = fileFlatList;
        ChildImages_nii = ChildImages;

    else
        ChildImages_nii = ChildImages;
    end

    jobs = cell(6, 1);
    if UNPACK
        jobs{1}.cfg_basicio.file_dir.file_ops.cfg_gunzip_files.files = fileFlatList_gz;
        jobs{1}.cfg_basicio.file_dir.file_ops.cfg_gunzip_files.outdir = {''};
        jobs{1}.cfg_basicio.file_dir.file_ops.cfg_gunzip_files.keep = true;
    end

    for i = 1:numel(DARTEL_FlowFields);
        jobs{2}.spm.tools.dartel.mni_norm.data.subj(i).flowfield = DARTEL_FlowFields(i);
        jobs{2}.spm.tools.dartel.mni_norm.data.subj(i).images = Images;
    end
    jobs{2}.spm.tools.dartel.mni_norm.template = {DARTEL_Template_6};
    jobs{2}.spm.tools.dartel.mni_norm.vox = p.Results.OutputVoxelSize; [3 3 3];
    jobs{2}.spm.tools.dartel.mni_norm.bb = [NaN NaN NaN
                                            NaN NaN NaN];
    jobs{2}.spm.tools.dartel.mni_norm.preserve = 0;
    jobs{2}.spm.tools.dartel.mni_norm.fwhm = p.Results.fwhm; [4 4 4];

    if REPACK
        jobs{3}.cfg_basicio.file_dir.file_ops.cfg_gzip_files.files = fileFlatList_nii_nogz;
        jobs{3}.cfg_basicio.file_dir.file_ops.cfg_gzip_files.outdir = {''};
        jobs{3}.cfg_basicio.file_dir.file_ops.cfg_gzip_files.keep = false;
    end

    if DELETE
        jobs{4}.cfg_basicio.file_dir.file_ops.file_move.files = fileFlatList_nii_yesgz;
        jobs{4}.cfg_basicio.file_dir.file_ops.file_move.action.delete = false;
    end

    if p.Results.GZipOutput
        outputFilelist = spm_file(fileFlatList_nii, 'prefix', 'w');
        jobs{5}.cfg_basicio.file_dir.file_ops.cfg_gzip_files.files = outputFilelist;
        jobs{5}.cfg_basicio.file_dir.file_ops.cfg_gzip_files.outdir = {''};
        jobs{5}.cfg_basicio.file_dir.file_ops.cfg_gzip_files.keep = false;
    end

    if p.Results.DeleteFlowFields
        jobs{6}.cfg_basicio.file_dir.file_ops.file_move.files = DARTEL_FlowFields;
        jobs{6}.cfg_basicio.file_dir.file_ops.file_move.action.delete = false;
    end

    z = ~cellfun('isempty', jobs);
    jobs = jobs(z);
end
