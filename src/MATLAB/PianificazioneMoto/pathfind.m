function [curve,dcurve,ddcurve,pik] = pathfind(nodeList, idList, Aint, Amid, obsList,method,pend)
% nodeList: lista di nodi che compongono il path
% Aint: matrice n x n x 2 di componenti [x,y]
% costruisco sequenza di punti in cui far passare il path
dimPath = size(idList,2);
nPoints = double.empty(0,2);
for i = 1:dimPath -1
    node = findobj(nodeList, 'id', idList(i));
    next = findobj(nodeList, 'id', idList(i+1));
    if (~isempty(node) || ~isempty(next))
        if isempty(ismember(nPoints,node.bc,'rows'))
            nPoints(end+1,:) = node.bc;
        end
        %             nPoints(end+1,:) = Amid(node.id,next.id,:);
        %             nPoints(end+1,:) = Aint(node.id,next.id,:);
        nPoints(end+1,:) = selectPoint(node, next, Amid, Aint, obsList);
        nPoints(end+1,:) = next.bc;
    end
end
if(isempty(nPoints))
    nPoints(end+1,:) = findobj(nodeList, 'id', idList(1)).bc;
    next = findobj(nodeList, 'id', idList(1));
end
  
if(next.dim>64)
    p1 = next.bc;
    p2 = pend(1:2);
    
    corners = next.corner';

    corners(1,:) = [corners(1,1)+25 corners(1,2)+25];
    corners(2,:) = [corners(2,1)-25 corners(2,2)+25];
    corners(3,:) = [corners(3,1)+25 corners(3,2)-25];
    corners(4,:) = [corners(4,1)-25 corners(4,2)-25];
    
    xlimit = [corners(1,2) corners(4,2)];
    ylimit = [corners(1,1) corners(4,1)];
    xbox = xlimit([1 1 2 2 1]);
    ybox = ylimit([1 2 2 1 1]);
    [xi,yi] = polyxpoly([p1(2) p2(2)],[p1(1) p2(1)],xbox,ybox);
    nPoints(end+1,:)=[yi,xi];
end

pik = [(pend(1:2)+nPoints(end,:))./2,pend(3)] ;
% figure
% hold on
% plot(nPoints(:,1),nPoints(:,2),'ob');
% if length(nPoints)>6
% pt = nPoints(1,:);
% pend = nPoints(end,:);
% pend1 = nPoints(end-1,:);
% pend2 = nPoints(end-2,:);
% diag = @(pt,pt1,pt2) (pt(1)~=pt1(1) || pt1(1)~=pt2(1))&&...
%     (pt(2)~=pt1(2) || pt1(2)~=pt2(2));
% rect = @(pt,pt1,pt2)  (pt(1) == pt1(1) &&...
%     pt1(2) == pt2(2) || ...
%     pt(2) == pt1(2) && ...
%     pt1(1) == pt2(1));
% while (pt(1) ~= pend(1) || pt(2)~=pend(2)) &&...
%         (pt(1) ~= pend1(1) || pt(2)~=pend1(2))&&...
%         (pt(1) ~= pend2(1) || pt(2)~=pend2(2))
%     id = find(ismember(nPoints,pt,'rows'));
%     pt1 = nPoints(id+1,:);
%     pt2 = nPoints(id+2,:);
%     %     h = plot(pt(1,1),pt(1,2),'og');
% 
%     if diag(pt,pt1,pt2) && ~rect(pt,pt1,pt2)
%         pt = nPoints(id+1,:);
%     elseif ~rect(pt,pt1,pt2)
%         nPoints(ismember(nPoints,pt1,'rows'),:)=[];
%         nPoints(ismember(nPoints,pt2,'rows'),:)=[];
%         pt = nPoints(id+1,:);
% 
%     else
%         pt = pt2;
%     end
%     %     plot(pt(1,1),pt(1,2),'*r');
%     %     delete(h)
% end
% end
dim = length(nPoints);
% tend = dim-1;
% stepsize = 0.001;
% time = tstart:stepsize:floor(tend/2);
% time = linspace(0,floor(tend/2),(dim-1)*500);
x = nPoints(:,1);
y= nPoints(:,2);
[pt,dpt] = interparc(dim,x,y,'linear');
        step=1/100;

switch method
    case 'Paraboloic'
        [qx,qxd,qxdd]= paraboloic_blend(pt(:,1)',step);
        [qy,qyd,qydd]= paraboloic_blend(pt(:,2)',step);
%         [pt,vt] = interparc(1000*(dim-1),qx,qy,'linear');
%         qx = pt(:,1)';
%         qy = pt(:,2)';
%         qxd = vt(:,1)';
%         qyd = vt(:,2)';
%         qxdd = zeros(1,1000*(dim-1))';
%         qydd = zeros(1,1000*(dim-1))';

    case 'Cubic'
        [qx,qxd,qxdd]=cubic_spline(x,step);
        [qy,qyd,qydd]=cubic_spline(y,step);

    case 'Quintic'
     [qx,qxd,qxdd]=quintic_spline(x,step);
     [qy,qyd,qydd]=quintic_spline(y,step);
end

theta = zeros(1,size(qx,2));

for i = 2:length(theta)
    theta(i) = atan2(qy(i)-qy(i-1),qx(i)-qx(i-1));
end

thetad = gradient(theta,step)*step;
thetadd = gradient(thetad,step)*step;


curve = [qy;qx;theta];
dcurve = [qxd;qyd;thetad];
ddcurve = [qxdd;qydd;thetadd];
end

function point = selectPoint(node, next, Amid, Aint, obsList)

pointInt = [Aint(node.id, next.id,1), Aint(node.id, next.id,2)];
pointMid = [Amid(node.id, next.id,1), Amid(node.id, next.id,2)];

[closestObstInt, minDistInt] = findClosestObs(obsList, pointInt);
[closestObstMid, minDistMid] = findClosestObs(obsList, pointMid);

if isequal(closestObstMid, closestObstInt)
    if minDistInt >= minDistMid
        point = pointInt;
    else
        point = pointMid;
    end

else
    %     point = ((pointInt+pointMid)/2);
    point = nearest(floor(pointMid/2)*2);
end
end

