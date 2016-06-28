%%% createKymoFeaturesImfilter.m
%%% Create the 18 features used by the SVM for every pixel of the input
%%% image.  Some of these features were adapted from Adriana San Miguel's
%%% code
%%%
%%% Input Argument
%%% imIn = input image
%%%
%%% Output Argument
%%% featList = matrix where each row represents the features for another
%%%      pixel, and each column is the value of one of the 18 features

function featList = createKymoFeaturesImfilter(imIn)

imDouble =double(imIn);

%%% Threshold out some background noise
[h,w] = size(imDouble);
level = graythresh(mat2gray(imDouble));
tbw = im2bw(mat2gray(imDouble),level*0.8);
imBlackBG = zeros(h,w);
imBlackBG(tbw) = imDouble(tbw);
imBlackBG(~tbw) = mean2(imDouble);

%%% Feature 1 = imIn intensity
im_slice=imBlackBG;
featList=im_slice(:); % 1

%%% Feature 2 = gradient magnitude
hy = fspecial('sobel'); hx = hy';
Iy = imfilter(im_slice, hy, 'replicate');
Ix = imfilter(im_slice, hx, 'replicate');
grad_im = sqrt(Ix.^2 + Iy.^2);
featList=[featList, grad_im(:)]; % 2
%%% Feature 3 = x-gradient
featList=[featList, Ix(:)]; % 3
%%% Feature 4 = y-gradient
featList=[featList, Iy(:)]; % 4
%%% Feature 5 = smoothed x-gradient (LPF with long SE)
IxLPF = conv2(Ix,1/10*ones(1,10),'same');
featList=[featList, IxLPF(:)]; % 5
%%% Feature 6 = smoothed y-gradient (LPF with long SE)
IyLPF = conv2(Iy,1/10*ones(10,1),'same');
featList=[featList, IyLPF(:)];% 6

%%% Feature 7 = LPF with square SE
imLPF=conv2(im_slice,1/25*ones(5),'same');
featList=[featList,imLPF(:)]; % 7
%%% Feature 8 = LPF with long SE1
imLPF=conv2(im_slice,1/25*ones(1,25),'same');
featList=[featList,imLPF(:)]; % 8
%%% Feature 9 = LPF with long SE2
imLPF=conv2(im_slice,1/75*ones(3,25),'same');
featList=[featList,imLPF(:)]; % 9

%%% Features 10 and 11 = Difference of Gaussians of varying sigma
h1 = fspecial('gaussian', 25, 0.1);
h2 = fspecial('gaussian', 25, 15*0.1);
h3 = fspecial('gaussian', 25, 50*0.1);
dog1=imfilter(im_slice,h1,'replicate');
ddog1=dog1-imfilter(im_slice,h2,'replicate');
featList=[featList,ddog1(:)]; % 10
ddog3=dog1-imfilter(im_slice,h3,'replicate');
featList=[featList,ddog3(:)]; % 11

%%% Features 12-15 = avgs and std devs with small and large disk
temp_im = imfilter((im_slice),fspecial('disk',5),'replicate');
featList=[featList,temp_im(:)]; % 12
temp_im=stdfilt(im_slice,ones(5));
featList=[featList,temp_im(:)]; % 13
temp_im = imfilter((im_slice),fspecial('disk',11),'replicate');
featList=[featList,temp_im(:)]; % 14
temp_im=stdfilt(im_slice,ones(11));
featList=[featList,temp_im(:)]; % 15

%%% Feature 16 = Laplacian of Gaussian (2nd derivative)
hlog2=fspecial('log',15,0.1);
temp_im=imfilter(im_slice,hlog2,'replicate');
featList=[featList,temp_im(:)]; % 16

%%% Feature 17 = erosion
see=strel('diamond',4);
temp_im=imerode(im_slice,see);
featList=[featList,temp_im(:)]; % 17
%%% Feature 18 = dilation
temp_im=imdilate(im_slice,see);
featList=[featList,temp_im(:)]; % 18

