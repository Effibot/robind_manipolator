function [gid,shapepos]=mapGeneration(obs,dim)
addpath(genpath('.\')); 
delete('PianificazioneMoto\mapgenerationimg\generated\*.png');
delete('PianificazioneMoto\mapgenerationimg\constructing\*.png');
delete('PianificazioneMoto\mapgenerationimg\generatedsim\*.png');
delete('PianificazioneMoto\mapgenerationimg\originalsim\*.png');

map = makeMap(obs,dim);
showimage(map.value);
saveimage(gcf,'PianificazioneMoto\mapgenerationimg\generated\','bw.png');
toSave = true;
toShow = false;
%% QT-Decomp
[M, nodeList] = splitandcolor(map, robotsize, toSave, toShow);
% mapImg = imshow(M);
%% Adjiacency Matrix
[A, Acomp, Aint, Amid] = adjmatrix(nodeList);
G=graph(A);
gid = gPlot(nodeList, A, Amid, Aint,M);
nobs = size(obs,1);
shapepos = zeros(3,3);
for i = 1:3
    form = randi(2,1);
    obb = randi(nobs,1);
    pos = obs(obb,1:2);
    shapepos(i,:) = [form,pos];
end
save mapg.mat M obs dim robotsize A Aint Amid G nodeList shapepos Acomp
end