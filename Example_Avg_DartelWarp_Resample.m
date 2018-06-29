addpath('C:\Users\mbmhscc4\GitHub\DARTEL_Support');
jobs = cell(23,1);
for i = 1:23
    ImagesToAverage = cell(9,1);
    for j = 1:9
        ImagesToAverage{j} = sprintf('%02d_%02d_O+orig.nii', i, j);
    end
    AverageResultsFilename = sprintf('%02d_O+orig.nii', i);
    jobs{i} = AverageImages(ImagesToAverage,AverageResultsFilename,'','AsMatrix',true);
end
spm_jobman('run',jobs);

x = arrayfun(@(x) sprintf('%02d_O+orig.nii', x), 1:23, 'UniformOutput', false)';
jobs = ApplyDartel(Dartel_FlowFields, {x});
spm_jobman('run',jobs);

y = spm_file(x,'prefix','w');
jobs = ApplyResample(y, 'VoxelSize', [3,3,3], 'fwhm', [0,0,0]);
spm_jobman('run',jobs);

y = spm_file(x,'prefix','w');
jobs = ApplyResample(y, 'VoxelSize', [3,3,3], 'fwhm', [4,4,4]);
spm_jobman('run',jobs);
