function L = approxSplineLength(sp)
x1 = round(sp.knots(1));
xe = round(sp.knots(end));
x = x1:1:xe;

y = fnval(sp,x);

dx = x(2:end)-x(1:end-1);
dy = y(2:end)-y(1:end-1);

%pythagoras
P = dx.^2+dy.^2;
C = sqrt(P);
L = sum(C);

end