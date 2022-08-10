function [objArea,objPerim,objShape,ang]=visione(filename)
% addpath(genpath('./MATLAB/Visione/'))
% addpath('MATLAB/PianificazioneMoto/')
delete('.\mapgenerationimg\visione\Processed\*.png')
% variabili simboliche
syms x rect(x,x0,y0,m) rect2p(x,x0,y0,x1,y1)  
rect(x,x0,y0,m)=m*(x-x0)+y0;
rect2p(x,x0,y0,x1,y1) = (x-x0)/(x1-x0)*(y1-y0)+y0;
% switch(obsTarget)
%     case 1
%         filename = 'Immagini/triangolo.jpg';
%     case 2
%         filename = 'Immagini/quadrato.jpg';
% 
%     case 3
%         filename = 'Immagini/sfera.jpg';
%     otherwise
%         disp("No obstacle match");
% end
[preprocessdata,maxRes]=preprocess(filename);
center=preprocessdata{1};
imgRGB=preprocessdata{2};
res=preprocessdata{3};
imgM=manipulateImg(imgRGB,res);
[objArea,objPerim,objShape,orient,diag,obb,...
    z, a, b, alpha]=computeGeometric(imgM,center);


%% Grafico contorno dell'oggetto
figure('Visible','off')
imshow(imgM,'Border','tight');
hold on
plot(obb(:,2),obb(:,1),'g','LineWidth',3);

phi = linspace(0,2*pi,50);
cosphi = cos(phi);
sinphi = sin(phi);

xbar = z(1);
ybar = z(2);

a = a/2;
b = b/2;

theta = pi*alpha/180;
R = [ cos(theta)   sin(theta)
     -sin(theta)   cos(theta)];

xy = [a*cosphi; b*sinphi];
xy = R*xy;

xx = xy(1,:) + xbar;
yy = xy(2,:) + ybar;

plot(xx,yy,'r','LineWidth',2);

%% Disegno assi maggiori dell'oggetto
ang=(wrapTo360(orient));
% aggiungo sfasamento trovato empiricamente dai plot precedenti per far
% coincidere lo 'zero' con quello da noi considerato.
majorax=rect(x,z(1),z(2),ang);
point=subs(majorax,x,z(1)+linspace(-a/2,a/2));
plot(z(1)+linspace(-a/2,a/2),point)
plot(z(1),z(2),'*g')
minorax=rect(x,z(1),z(2),-1/ang);
point=subs(minorax,x,z(1)+linspace(-b,b));
h=plot(z(1)+linspace(-b,b),point);

hold on
%% Disegno Baricentro dell'oggetto
plot(z(1),z(2),'bo','MarkerSize',10)
%% Visualizzo Diagonali dell'oggetto
lineOrient =  z(2) + tan(orient) * ( x  - z(1) ) ;
fplot(lineOrient,'y', 'LineWidth', 2.5);
plot(z(1)*ones(1,maxRes(1)),linspace(0,maxRes(1),maxRes(1)),'--r','linewidth',2)
plot(linspace(0,maxRes(2),maxRes(2)),z(2)*ones(1,maxRes(2)),'--r','linewidth',2)
for i =1:size(diag,2)
    eq = diag(i);
    fplot(eq, 'b','LineWidth', 1.5);
    hold on
end
saveimage(gcf,'.\mapgenerationimg\visione\Processed\','1.png');
%% Report dell'Identificazione
% fprintf("Area: %f, Perimetro: %f\n", objArea, objPerim);
% fprintf("Forma dell'Oggetto: %s\n", objShape);
% fprintf("Baricentro dell'Oggetto: X[bc] = %f, Y[bc] = %f\n", z(1), z(2));
% fprintf("Orientamento dell'Oggetto: %f°\n", ang);
% fprintf("Tempo di Processamento: %f ms\n", elapseTime);
end




