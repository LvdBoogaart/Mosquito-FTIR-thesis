function plot_bounds(imdat)
%PLOT_BOUNDS Summary of this function goes here
%   Detailed explanation goes here

splinedat = imdat.sampling;
for n = 1:splinedat.nLegs
x1 = splinedat.c1{n}(:,1);
y1 = splinedat.c1{n}(:,2);
x2 = splinedat.c2{n}(:,1);
y2 = splinedat.c2{n}(:,2);

plot(x1,y1,x2,y2)
hold on

end
end







