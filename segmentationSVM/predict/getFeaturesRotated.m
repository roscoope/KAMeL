%%% getFeaturesRotated.m
%%% Calculates the features for the entire image rotated to angle currTheta
%%%
%%% Input Arguments
%%% imIn = input image
%%% currTheta = rotation of image at which to calculate features
%%%
%%% Output Arguments
%%% features = matrix where each row represents the features for another
%%%      pixel, and each column is the value of one of the 18 features

function features = getFeaturesRotated(imIn,currTheta)

%%% Rotate the image
imHorzBig = imrotate(imIn,90-currTheta,'bicubic');
[r,c] = find(imHorzBig);
[h,w] =size(imHorzBig);
maxR = min(max(r)+10,h);
minR = max(min(r)-10,1);
maxC = min(max(c)+10,w);
minC = min(max(c)-10,1);
imHorz = imHorzBig(minR:maxR,minC:maxC);

%%% Calculate the features for the rotated image
featuresSmall = createKymoFeaturesImfilter(imHorz);
featuresBig = zeros(size(imHorzBig,1),size(imHorzBig,2),size(featuresSmall,2));
featuresBig(minR:maxR,minC:maxC,:) = reshape(featuresSmall,maxR-minR+1,maxC-minC+1,size(featuresSmall,2));
features1 = reshape(featuresBig,size(imHorzBig,1)*size(imHorzBig,2),size(featuresSmall,2));

%%% Rotate the features back to align then with the original image
featuresR = imrotate(reshape(features1,size(imHorzBig,1),size(imHorzBig,2),size(features1,2)),currTheta-90,'bicubic');
offset(1) = round((size(featuresR,1)-size(imIn,1))/2);
offset(2) = round((size(featuresR,2)-size(imIn,2))/2);
if offset(1) == 0 && offset(2) == 0
    offset = offset + 1;
    newImg = featuresR(offset(1):end-offset(1)+1,offset(2):end-offset(2)+1,:);
else
    newImg = featuresR(offset(1):end-offset(1),offset(2):end-offset(2),:);
end
[h,w,d] = size(imIn);
[h2,w2,d2] = size(newImg);
if h <= h2
    newImg2 = newImg(1:h,:,:);
else
    newImg2 = [newImg;zeros(h-h2,w2,d2)];
end
if w <= w2
    featuresC = newImg2(:,1:w,:);
else
    featuresC = [newImg2,zeros(h,w2-w,d)];
end
features = reshape(featuresC,h*w,size(features1,2));
