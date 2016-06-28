%%% makeLineRadon.m
%%% Given a <theta,rho> pair, this function returns a binary mask of 
%%% the same size as imClean tracing the <theta,rho> line

function newLine = makeLineRadon(imClean,theta,rho,hyp)

[h,w] = size(imClean);
if ~exist('hyp','var')
    hyp = ceil(sqrt(h^2+w^2));
end
bigIm = zeros(hyp);
try
bigIm(:,round(hyp/2+rho+1)) = 1;
catch err
    temp = 5;
end
   
newLine1 = imrotate(bigIm,theta,'crop');
[h2,w2] = size(newLine1);
midY = ceil(h2/2)+1;
midX = ceil(w2/2)+1;
y1 = max(round(midY-h/2),1);
y2 = min(round(midY+h/2)-1,h2);
x1 = max(round(midX-w/2),1);
x2 = min(round(midX+w/2)-1,w2);
newLine = newLine1(y1:y2,x1:x2);