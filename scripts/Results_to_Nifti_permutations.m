addpath('C:\Users\mbmhscc4\MATLAB\src\WholeBrain_MVPA\dependencies\jsonlab\');
addpath('C:\Users\mbmhscc4\MATLAB\src\WholeBrain_MVPA\util');

%% Load the permutation data
[~,perms,n] = HTCondorLoad('permutations');

%% Extract information from subject sub-structure into the top-level structure.
for i = 1:numel(perms)
    perms(i).cvholdout = perms(i).subject.cvholdout;
    perms(i).finalholdout = perms(i).subject.finalholdout;
    perms(i).bias = perms(i).subject.bias;
    perms(i).target_label = perms(i).subject.target_label;
    perms(i).target_type = perms(i).subject.target_type;
    perms(i).sim_metric = perms(i).subject.sim_metric;
    perms(i).sim_source = perms(i).subject.sim_source;
    perms(i).normalize_data = perms(i).subject.normalize_data;
    perms(i).normalize_target = perms(i).subject.normalize_target;
    perms(i).normalize_wrt = perms(i).subject.normalize_wrt;
    perms(i).orientation = perms(i).subject.orientation;
    perms(i).radius = perms(i).subject.radius;
    perms(i).regularization = perms(i).subject.regularization;
    perms(i).subject = perms(i).subject.subject;
end

%% Average error maps over cross-validations
% Full structure has 23 subjects x 9 cross validations x 100 permutations
subjects = unique([perms.subject]);
randomseeds = unique([perms.RandomSeed]);
perms_avg = repmat(...
    cell2struct(cell(numel(fieldnames(perms)),1),fieldnames(perms)), ...
    23*100,...
    1);
[x,y] = ndgrid(subjects, randomseeds);
subjects = x(:);
randomseeds = y(:);

for i = 1:numel(perms_avg)
    z = ([perms.subject] == subjects(i)) & ([perms.RandomSeed] == randomseeds(i));
    P = perms(z);
    perms_avg(i) = P(1);
    perms_avg(i).error_map1 = mean(cat(2,P.error_map1),2);
    perms_avg(i).error_map2 = mean(cat(2,P.error_map2),2);
end
perms_avg = rmfield(perms_avg, {'cvholdout','finalholdout'});

%% Add coords (and filter)
load('D:\MRI\SoundPicture\data\MAT\avg\bysession\metadata_sessions_ECoG_SoundPicture_Merge.mat', 'metadata');
for i = 1:numel(subjects)
    z = [perms_avg.subject] == subjects(i);
    ix = find(z, 1);
    zz = [metadata.subject] == subjects(i);
    M = metadata(zz);
    zz = strcmp(perms_avg(ix).orientation, {M.coords.orientation});
    C = M.coords(zz);
    zz = strcmp('colfilter_vis', {M.filters.label});
    F = M.filters(zz);
    C.ind = C.ind(F.filter);
    [perms_avg(z).coords] = deal(C);
end

%% Write nii files
addpath('C:\Users\mbmhscc4\MATLAB\src\WholeBrain_MVPA\dependencies\nifti\');
datadir = 'D:\MRI\SoundPicture\data\raw';
MASK_ORIG_O = struct('subject',num2cell(1:23)', 'filename', {
    fullfile(datadir,'s02_rightyes','mask','nS_c1_mask_nocerebellum_O.nii')
    fullfile(datadir,'s03_leftyes','mask','nS_c1_mask_nocerebellum_O.nii')
    fullfile(datadir,'s04_rightyes','mask','nS_c1_mask_nocerebellum_O.nii')
    fullfile(datadir,'s05_leftyes','mask','nS_c1_mask_nocerebellum_O.nii')
    fullfile(datadir,'s06_rightyes','mask','nS_c1_mask_nocerebellum_O.nii')
    fullfile(datadir,'s07_leftyes','mask','nS_c1_mask_nocerebellum_O.nii')
    fullfile(datadir,'s08_rightyes','mask','nS_c1_mask_nocerebellum_O.nii')
    fullfile(datadir,'s09_leftyes','mask','nS_c1_mask_nocerebellum_O.nii')
    fullfile(datadir,'s10_rightyes','mask','nS_c1_mask_nocerebellum_O.nii')
    fullfile(datadir,'s11_leftyes','mask','nS_c1_mask_nocerebellum_O.nii')
    fullfile(datadir,'s12_rightyes','mask','nS_c1_mask_nocerebellum_O.nii')
    fullfile(datadir,'s13_leftyes','mask','nS_c1_mask_nocerebellum_O.nii')
    fullfile(datadir,'s14_rightyes','mask','nS_c1_mask_nocerebellum_O.nii')
    fullfile(datadir,'s15_leftyes','mask','nS_c1_mask_nocerebellum_O.nii')
    fullfile(datadir,'s16_rightyes','mask','nS_c1_mask_nocerebellum_O.nii')
    fullfile(datadir,'s17_leftyes','mask','nS_c1_mask_nocerebellum_O.nii')
    fullfile(datadir,'s18_rightyes','mask','nS_c1_mask_nocerebellum_O.nii')
    fullfile(datadir,'s19_leftyes','mask','nS_c1_mask_nocerebellum_O.nii')
    fullfile(datadir,'s20_rightyes','mask','nS_c1_mask_nocerebellum_O.nii')
    fullfile(datadir,'s21_leftyes','mask','nS_c1_mask_nocerebellum_O.nii')
    fullfile(datadir,'s22_rightyes','mask','nS_c1_mask_nocerebellum_O.nii')
    fullfile(datadir,'s23_leftyes','mask','nS_c1_mask_nocerebellum_O.nii')
    fullfile(datadir,'s24_rightyes','mask','nS_c1_mask_nocerebellum_O.nii')
}, 'hdr', []);
for i = 1:numel(MASK_ORIG_O)
    MASK_ORIG_O(i).hdr = load_nii_hdr(MASK_ORIG_O(i).filename);
end
HTCondor_struct2nii( ...
    perms_avg, ...
    MASK_ORIG_O, ...
    'error_map1', ...
    'outdir','permutations\solutionmaps\nifti', ...
    'filestring','%02d_%03d_O+orig.nii', ...
    'filevars',{'subject','RandomSeed'});