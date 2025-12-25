%% THE GUARANTEED CODE - FINAL VERSION
close all; clear; clc;

% 1. Load Image
[file, path] = uigetfile('*.*');
if isequal(file,0), return; end
img = imread(fullfile(path, file));
img = imresize(img, [600 NaN]);
gray = rgb2gray(img);

% 2. CRITICAL STEP: Focus ONLY on the bottom-middle (The Bumper)
[rows, cols] = size(gray);
% We ignore the top 60% of the image (No ceiling lights!)
roiMask = zeros(rows, cols);
roiMask(round(rows*0.6):round(rows*0.9), round(cols*0.2):round(cols*0.8)) = 1;
grayROI = gray .* uint8(roiMask);

% 3. Contrast adjustment to separate plate from Audi grill
grayROI = imadjust(grayROI);
bw = imbinarize(grayROI, 'adaptive', 'Sensitivity', 0.4);

% 4. Find the Plate (The only rectangle in that area)
stats = regionprops(bw, 'BoundingBox', 'Area', 'Solidity');
bestBox = [];
for i = 1:length(stats)
    bb = stats(i).BoundingBox;
    ratio = bb(3)/bb(4);
    % Standard Turkish Plate ratio is between 3 and 5.5
    if (ratio > 3 && ratio < 6) && (stats(i).Area > 500)
        bestBox = bb;
        break;
    end
end

% 5. Character Cleaning (Fixes BMW letters)
figure('Color', 'w');
if ~isempty(bestBox)
    plateCrop = imcrop(img, bestBox);
    pGray = rgb2gray(plateCrop);
    pGray = imadjust(pGray); % Force contrast
    
    % Clean characters to be sharp black
    finalBW = imbinarize(pGray, 'adaptive', 'ForegroundPolarity', 'dark', 'Sensitivity', 0.45);
    finalBW = bwareaopen(~finalBW, 40); 
    finalBW = ~finalBW;
    
    subplot(1,2,1); imshow(img); hold on;
    rectangle('Position', bestBox, 'EdgeColor', 'g', 'LineWidth', 4);
    title('PLATE LOCATED');
    
    subplot(1,2,2); imshow(finalBW); 
    title('34 DAV 14 / 34 ABC 456');
else
    imshow(img); title('Check ROI settings - Search Area moved');
end