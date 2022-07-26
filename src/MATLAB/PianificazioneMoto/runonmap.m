function runonmap(M,p,rbclist,nodeList,robotsize,src)
showimage(M);
circleColorObs=[0.623, 0.501, 0.635, 0.5];
robotColor = [1 1 0 0.7];
cp = p';
hold on
plot(cp(:,1),cp(:,2),'LineWidth',3);
saving=@(gcf)frame2im(getframe(gcf));
% 
if size(p,2)>2
for j = 1:ceil((size(p,2)-1)/100):size(p,2)
    currPoint = p(1:2,j)';
    [closestObs, minDist] = findClosestObs(rbclist, fliplr(currPoint));
    obsNode= findobj(nodeList,'bc',closestObs);
    radiusObs=sqrt(2)/2*obsNode.dim;
    radiusRobot=minDist-radiusObs;
    if radiusRobot>=robotsize/2
        circleColor = [0.0, 1.0, 1.0, 0.5];
    else
        circleColor = [0.780, 0, 0.050];

    end
    h = circle(currPoint(1), currPoint(2), radiusRobot, circleColor);

    hobs = circle(closestObs(2), closestObs(1), radiusObs, circleColorObs);

    robot = circle(currPoint(1), currPoint(2), robotsize/2, robotColor);
    ll = line([currPoint(1), closestObs(2)],...
        [currPoint(2), closestObs(1)],...
        'Color','#ca64ea','LineStyle','-.','LineWidth',3);

    im = saving(gcf);

    J = imresize(im,[1024,1024],'cubic');
    JJBGRA = cat(3,J,ones(1024,'uint8')*255);
    msg = src.UserData.buildMessage(0,"ANIMATION",src.UserData.compressImg(JJBGRA));
    msg = src.UserData.buildMessage(msg,"FINISH",0);
    src.UserData.sendMessage(src,msg);
    delete(h);
    delete(hobs);
    delete(robot)
    delete(ll);
end
else
     currPoint = p(1:2,1)';
    [closestObs, minDist] = findClosestObs(rbclist, fliplr(currPoint));
    obsNode= findobj(nodeList,'bc',closestObs);
    radiusObs=sqrt(2)/2*obsNode.dim;
    radiusRobot=minDist-radiusObs;
    if radiusRobot>=robotsize/2
        circleColor = [0.0, 1.0, 1.0, 0.5];
    else
        circleColor = [0.780, 0, 0.050];

    end
    h = circle(currPoint(1), currPoint(2), radiusRobot, circleColor);

    hobs = circle(closestObs(2), closestObs(1), radiusObs, circleColorObs);

    robot = circle(currPoint(1), currPoint(2), robotsize/2, robotColor);
    ll = line([currPoint(1), closestObs(2)],...
        [currPoint(2), closestObs(1)],...
        'Color','#ca64ea','LineStyle','-.','LineWidth',3);

    im = saving(gcf);

    J = imresize(im,[1024,1024],'cubic');
    JJBGRA = cat(3,J,ones(1024,'uint8')*255);
    msg = src.UserData.buildMessage(0,"ANIMATION",src.UserData.compressImg(JJBGRA));
    msg = src.UserData.buildMessage(msg,"FINISH",0);
    src.UserData.sendMessage(src,msg);
    delete(h);
    delete(hobs);
    delete(robot)
    delete(ll);
end
end

