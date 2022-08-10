function [p,dp,ddp]=path_generator(startId,shape,method)
load matfiles/mapg.mat
redObsbc = reshape([findobj(nodeList, 'prop', 'r').bc]',2,[]);
[id,~]=dsearchn(redObsbc',shape);
goalObs = redObsbc(:,id(1));
goalid = findobj(nodeList,'bc',goalObs');
endId = findAdjNode(goalid,nodeList,Acomp);
P = shortestpath(G, startId, endId);
rbclist = getbcprop(nodeList, 'r');
[p,dp,ddp] = pathfind(nodeList, P, Aint, Amid, rbclist,method);
runonmap(M,p,rbclist,nodeList,robotsize,'originalsim\');
save matfiles/path.mat p dp ddp M rbclist nodeList robotsize
end

