function quickplotter(image,output)
%QUICKPLOTTER Summary of this function goes here
%   Detailed explanation goes here
classdat = output{image}.Class;
sz = size(classdat.legobj,2);

for n = 1:sz
    spline = classdat.legobj{n}.spline;
    fnplt(spline)
    hold on
end

