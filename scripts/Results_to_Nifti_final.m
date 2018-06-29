addpath('C:\Users\mbmhscc4\MATLAB\src\WholeBrain_MVPA\dependencies\jsonlab\');
addpath('C:\Users\mbmhscc4\MATLAB\src\WholeBrain_MVPA\util');

%% Load the permutation data
[~,final,n] = HTCondorLoad('final');

%% Extract information from subject sub-structure into the top-level structure.
for i = 1:numel(final)
    final(i).cvholdout = final(i).subject.cvholdout;
    final(i).finalholdout = final(i).subject.finalholdout;
    final(i).bias = final(i).subject.bias;
    final(i).target_label = final(i).subject.target_label;
    final(i).target_type = final(i).subject.target_type;
    final(i).sim_metric = final(i).subject.sim_metric;
    final(i).sim_source = final(i).subject.sim_source;
    final(i).normalize_data = final(i).subject.normalize_data;
    final(i).normalize_target = final(i).subject.normalize_target;
    final(i).normalize_wrt = final(i).subject.normalize_wrt;
    final(i).orientation = final(i).subject.orientation;
    final(i).radius = final(i).subject.radius;
    final(i).regularization = final(i).subject.regularization;
    final(i).subject = final(i).subject.subject;
end

%% Average error maps over cross-validations
% Full structure has 23 subjects x 9 cross validations
subjects = unique([final.subject]);
final_avg = repmat(...
    cell2struct(cell(numel(fieldnames(final)),1),fieldnames(final)), ...
    23,...
    1);

for i = 1:numel(final_avg)
    z = ([final.subject] == subjects(i)) & ([final.RandomSeed] == randomseeds(i));
    P = final(z);
    final_avg(i) = P(1);
    final_avg(i).error_map1 = mean(cat(2,P.error_map1),2);
    final_avg(i).error_map2 = mean(cat(2,P.error_map2),2);
end
final_avg = rmfield(final_avg, {'cvholdout','finalholdout'});

%% Add coords (and filter)
load('D:\MRI\SoundPicture\data\MAT\avg\bysession\metadata_sessions_ECoG_SoundPicture_Merge.mat', 'metadata');
for i = 1:numel(subjects)
    z = [final_avg.subject] == subjects(i);
    ix = find(z, 1);
    zz = [metadata.subject] == subjects(i);
    M = metadata(zz);
    zz = strcmp(final_avg(ix).orientation, {M.coords.orientation});
    C = M.coords(zz);
    zz = strcmp('colfilter_vis', {M.filters.label});
    F = M.filters(zz);
    C.ind = C.ind(F.filter);
    [final_avg(z).coords] = deal(C);
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
    final_avg, ...
    MASK_ORIG_O, ...
    'error_map1', ...
    'outdir','permutations\solutionmaps\nifti', ...
    'filestring','%02d_O+orig.nii', ...
    'filevars',{'subject'});