function [ jobs, prefix ] = ApplyResample( ImagesToResample, varargin )
%UNTITLED5 Summary of this function goes here
%   Detailed explanation goes here
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

    p = inputParser();
    addRequired(p, 'ImagesToResample', @iscell);
    addParameter(p, 'VoxelSize', [3,3,3], @isThreeElementVector);
    addParameter(p, 'fwhm', [0,0,0], @isThreeElementVector);
    addParameter(p, 'GZipInput', false, @islogical);
    addParameter(p, 'GZipOutput', false, @islogical);
    parse(p, ImagesToResample, varargin{:});
    
    voxsiz = p.Results.VoxelSize(:)'; % new voxel size {mm}
    prefix = sprintf('xb%d_',max(p.Results.fwhm));
    
    UNPACK = false;
    DELETE = false;
    REPACK = false;

    z = ~cellfun('isempty', regexp(ImagesToResample, '\.gz$'));
    if any(z)
        UNPACK = true;
        DELETE = UNPACK;
        REPACK = ~all(z);
        
        ImagesToResample_nii = regexprep(ImagesToResample, '\.gz$', '');
        
        ImagesToResample_gz = ImagesToResample(z);
        ImagesToResample_nii_nogz = ImagesToResample(~z);
        ImagesToResample_nii_yesgz = ImagesToResample_nii(z);

    elseif p.Results.GZipInput
        REPACK = true;
        ImagesToResample_nii = ImagesToResample;
        ImagesToResample_nii_nogz = ImagesToResample;

    else
        ImagesToResample_nii = ImagesToResample;
    end
    
    jobs = cell(5, 1);
    if UNPACK
        jobs{1}.cfg_basicio.file_dir.file_ops.cfg_gunzip_files.files = ImagesToResample_gz;
        jobs{1}.cfg_basicio.file_dir.file_ops.cfg_gunzip_files.outdir = {''};
        jobs{1}.cfg_basicio.file_dir.file_ops.cfg_gunzip_files.keep = true;
    end

    jobs{2}.spm.util.defs.comp{1}.idbbvox.vox = voxsiz;
    jobs{2}.spm.util.defs.comp{1}.idbbvox.bb = [NaN NaN NaN
                                               NaN NaN NaN];
    jobs{2}.spm.util.defs.out{1}.pull.fnames = ImagesToResample_nii;
    jobs{2}.spm.util.defs.out{1}.pull.savedir.savepwd = 1;
    jobs{2}.spm.util.defs.out{1}.pull.interp = 4;
    jobs{2}.spm.util.defs.out{1}.pull.mask = 0;
    jobs{2}.spm.util.defs.out{1}.pull.fwhm = p.Results.fwhm;
    jobs{2}.spm.util.defs.out{1}.pull.prefix = prefix;
    
    if REPACK
        jobs{3}.cfg_basicio.file_dir.file_ops.cfg_gzip_files.files = ImagesToResample_nii_nogz;
        jobs{3}.cfg_basicio.file_dir.file_ops.cfg_gzip_files.outdir = {''};
        jobs{3}.cfg_basicio.file_dir.file_ops.cfg_gzip_files.keep = false;
    end

    if DELETE
        jobs{4}.cfg_basicio.file_dir.file_ops.file_move.files = ImagesToResample_nii_yesgz;
        jobs{4}.cfg_basicio.file_dir.file_ops.file_move.action.delete = false;
    end
    
    if p.Results.GZipOutput
        outputFilelist = spm_file(ImagesToResample_nii, 'prefix', prefix);
        jobs{5}.cfg_basicio.file_dir.file_ops.cfg_gzip_files.files = outputFilelist;
        jobs{5}.cfg_basicio.file_dir.file_ops.cfg_gzip_files.outdir = {''};
        jobs{5}.cfg_basicio.file_dir.file_ops.cfg_gzip_files.keep = false;
    end

    z = ~cellfun('isempty', jobs);
    jobs = jobs(z);
end

