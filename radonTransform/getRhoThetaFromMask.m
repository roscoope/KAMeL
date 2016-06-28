%%% getRhoThetaFromMask.m
%%% Given a binary line mask, this function returns the corresponding <theta,rho> pair

function [rho,theta] = getRhoThetaFromMask(mask)

[r,c] = find(mask);
inds = sort(sub2ind(size(mask),r,c),'ascend');
[y,x] = ind2sub(size(mask),[min(inds);max(inds)]);

[h,w] = size(mask);

x1 = x(1)-w/2;
y1 = h/2-y(1);
x2 = x(2)-w/2;
y2 = h/2-y(2);

m = (y2-y1)/(x2-x1);
mInv = -1/m;

theta1 = atand(mInv);
if theta1 < 0
    theta=theta1+180;
else
    theta = theta1;
end

hyp = sqrt(sum(size(mask).^2));
xx = (-hyp:0.01:hyp)';
yy = xx * mInv;

[~,ind] = min((xx-x1).^2+(yy-y1).^2);
rhoAbs = sqrt(xx(ind)^2+yy(ind)^2);
if yy(ind) < 0
    rho = -1*rhoAbs;
else
    rho = rhoAbs;
end


