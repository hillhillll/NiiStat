function str = nii_roi2mm (ROIIndex, forceRecalc)
%report coordinates for each parcel in a region-of-interest map.
% ROIindex : (optional) number for region of interest
% forceRecalc : (optional) re-generate even if node file exists in ROI folder
%Examples
% nii_roi2mm; %use GUI
% nii_roi2mm(2);
% str = nii_roi2mm('jhu');

if exist('ROIIndex','var') && ~isnumeric(ROIIndex) %convert text to numeric 'jhu' -> 7
    [kROI, kROINumbers, ROIIndex] = nii_roi_list(ROIIndex) ;
else
    [kROI, kROINumbers] = nii_roi_list() ;
end

if ~exist('ROIIndex','var') %region of interest not specified
    ROIIndex = str2double(cell2mat(inputdlg(['RoiIndex (' sprintf('%s',kROINumbers) ')'], 'Choose image', 1,{'2'})));
end;

if ~exist('forceRecalc','var')
    forceRecalc = false;
end

ROIname = deblank(kROI(ROIIndex,:));
nodename = [ROIname '.node'];
if (forceRecalc) || ~exist(nodename,'file')
    str = calcSub(ROIname);
else
    str = fileread(nodename);
end
if ~exist(nodename,'file')
   fileID = fopen(nodename,'w');
   fprintf(fileID, str);
   fclose(fileID); 
end
if nargout < 1
    fprintf(str);
end
%hdr.mat
%end nii_roi2mm()

function str = calcSub (ROIname)
label = labelSub ([ROIname '.txt']);
hdr = spm_vol ([ROIname '.nii']);
img = spm_read_vols (hdr);
fprintf('Calculating BrainNetViewer format file %s\n', [ROIname '.node']);
str = '';
for i = 1: max(img(:))
    %identify voxels in region
    img1 = zeros(size(img));
    img1(img == i) = 1;
    sumTotal = sum(img1(:));
    %compute center of mass
    vox(1) = sum(sum(sum(img1,3),2)'.*(1:size(img1,1)))/sumTotal; %dimension 1
    vox(2) = sum(sum(sum(img1,3),1).*(1:size(img1,2)))/sumTotal; %dimension 2
    vox(3) = sum(squeeze(sum(sum(img1,2),1))'.*(1:size(img1,3)))/sumTotal; %dimension 3
    %convert from voxels to mm
    mm=vox*hdr.mat(1:3, 1:3)'+hdr.mat(1:3, 4)';
    lbl = deblank(label(i,:));
    lbl = strrep(lbl, ' ', '.');
    %report coordinates
    str = [str sprintf('%g\t%g\t%g\t1\t1\t%s\n', mm(1), mm(2), mm(3), lbl)];  %#ok<AGROW>
end
%end calcSub()


function label = labelSub (ROIname)
if ~exist(ROIname,'file'), error('Unable to find %s',ROIname); end;
fid = fopen(ROIname);  % Open file
label=[];
tline = fgetl(fid);
while ischar(tline)
    %disp(tline)
    label=strvcat(label,tline); %#ok<REMFF1>
    tline = fgetl(fid);
end
fclose(fid); 
%end labelSub()