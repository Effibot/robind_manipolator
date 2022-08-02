function spline1 = makePath(nodeidList,nodeList)
%MAKEPATH Summary of this function goes here
%   Detailed explanation goes here
dimPath=size(nodeidList,2);
nPoints=double.empty(0,2);
t=1:1:dimPath;
for i =1:dimPath
    node = findobj(nodeList,'id',nodeidList(i));
    if ~isempty(node)
        nPoints(end+1,:)=node.bc;
    end
end
%% Example Spline two Points
% Grafico (x,t)
% dist=pdist([nPoints(1,1),nPoints(1,2);nPoints(2,1),nPoints(2,2)],'euclidean');
tbc=[0,1];
t=0:0.1:1;
xbc=[nPoints(1,2),nPoints(2,2),0,0];
ybc=[nPoints(1,1),nPoints(2,1),0,0];
[x]=splineEq(xbc(1),xbc(2),xbc(3),xbc(4),tbc);
[y]=splineEq(ybc(1),ybc(2),ybc(3),ybc(4),tbc);

% plot spline

figure
hold on
xx=double(subs(x,t));
yy=double(subs(y,t));
plot(t,xx);
plot(tbc,[xbc(1),xbc(2)],'or')
title('x vs. t for Cubic Spline Equation')
%Grafico (y,t)
figure
hold on
plot(t,yy);
plot(tbc,[ybc(1),ybc(2)],'or');
title('y vs. t for Cubic Spline Equation')

figure
plot(xx,yy,xbc,ybc,'or');
title('y vs. x for Cubic Spline Equation')

%% N-Point Spline
% y=flipud(nPoints(:,1));
% x=nPoints(:,2);
% % plot(x,y,x,y,'o');
% % title('Waypoints for N-Point example');
% % Instead, we need to introduce an independent variable that is always
% % monotonically increasing, like time!
% t=0:1:size(y,1)-1;
% % figure;
% % plot(t,x,t,x,'o');
% % title('x vs. t');
% % 
% % figure;
% % plot(t,y,t,y,'o');
% % title('y vs. t');
% % 
% % figure;
% % plot(x,y,x,y,'o');
% % title('y vs. x');
% %Spline Waypoints
% tq = 0:0.1:size(y,1)-1;
% slope0 = 0;
% slopeF = 0;
% xq = spline(t,[slope0; x; slopeF],tq);
% yq = spline(t,[slope0; y; slopeF],tq);
% 
% % plot spline in t-x, t-y and x-y space
% figure;
% plot(t,x,'o',tq,xq,':.');
% title('x vs. t');
% 
% figure;
% plot(t,y,'o',tq,yq,':.');
% title('y vs. t');
% 
% figure;
% plot(x,y,'o',xq,yq,':.');
% title('y vs. x');
% axis([0 1000 0 1000])
end

function [x,y]=splineEq(x0,xf,slope0,slopef,tbc)
%Cubic Spline: solving
% xdot0 = 1; xdotf = 1;
% x(t0) = x0; % position of initial coordinate
% x(tf) = xf; % position of final coordinate
% xdot(t0) = xdot0; % slope of initial coordinate
% xdot(tf) = xdotf; % slope of final coordinate
syms x xdot a0 a1 a2 a3 t y ydot 
x = a0+a1*t+a2*t^2+a3*t^3;
xdot = a1+2*a2*t+3*a3*t^2;
% Boundary Conditions [C]*[a0;a1;a2;a3]=bc
%Inserting the values of the initial conditions for t, 
% we get x and xdot as a function of a1,a2,a3,a4.
bc0=subs(x,t,tbc(1));
bc1=subs(x,t,tbc(2));
bc2=subs(xdot,t,tbc(1));
bc3=subs(xdot,t,tbc(2));
%Coefficients to define a spline equation taking coeff of bc
[C,~]=equationsToMatrix(bc0,bc1,bc2,bc3,[a0,a1,a2,a3]);
%Solving the eq to obtain a coeffs
%N.B.: '\': x = A\B solves the system of linear equations A*x = B.
% The matrices A and B must have the same number of rows. 
% MATLAB® displays a warning message if A is badly scaled or nearly singular, 
% but performs the calculation regardless.
% If A is a scalar, then A\B is equivalent to A.\B.
% 
% If A is a square n-by-n matrix and B is a matrix with n rows, then x = A\B is a solution to the equation A*x = B, if it exists.
% 
% If A is a rectangular m-by-n matrix with m ~= n, and B is a matrix with m rows, then A\B returns a least-squares solution to the system of equations A*x= B.
xbc=[x0;xf;slope0;slopef];
a = C\xbc; % a = [a1 a2 a3 a4]';
display(a);
%Equazione della spline
yyy = a(1)+a(2)*x+a(3)*x.^2+a(4)*x.^3;


x=a(1)+a(2)*t+a(3)*t.^2+a(4)*t.^3;


% % %y
% y=a0+a1*t+a2*t^2+a3*t^3;
% ydot =a1+2*a2*t+3*a3*t^2;
% % Boundary Conditions [C]*[a0;a1;a2;a3]=bc
% bc0=subs(y,t,y0);
% bc1=subs(y,t,yf);
% bc2=subs(ydot,t,45);
% bc3=subs(ydot,t,45);
% %Coefficients to define a spline equation taking coeff of bc
% [C,~]=equationsToMatrix(bc0,bc1,bc2,bc3,[a0,a1,a2,a3]);
% %Solving the eq to obtain a coeffs
% %N.B.: '\': x = A\B solves the system of linear equations A*x = B.
% % The matrices A and B must have the same number of rows. 
% % MATLAB® displays a warning message if A is badly scaled or nearly singular, 
% % but performs the calculation regardless.
% % If A is a scalar, then A\B is equivalent to A.\B.
% % 
% % If A is a square n-by-n matrix and B is a matrix with n rows, then x = A\B is a solution to the equation A*x = B, if it exists.
% % 
% % If A is a rectangular m-by-n matrix with m ~= n, and B is a matrix with m rows, then A\B returns a least-squares solution to the system of equations A*x= B.
% ybc=[x0;xf;slope0;slopef];
% a = C\ybc; % a = [a1 a2 a3 a4]';
% y = a(1)+a(2)*t+a(3)*t.^2+a(4)*t.^3;

end
