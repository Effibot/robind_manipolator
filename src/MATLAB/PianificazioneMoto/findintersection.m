function [yi, xi] = findintersection(nodeA, nodeB)
    xlimit=[nodeA.corner(2,2), nodeA.corner(2,3)];
    ylimit=[nodeA.corner(1,2), nodeA.corner(1,3)];
    xbox = xlimit([1 1 2 2 1]);
    ybox = ylimit([1 2 2 1 1]);
    [xi,yi] = polyxpoly([nodeB.bc(2) nodeA.bc(2)],...
        [nodeB.bc(1) nodeA.bc(1)],xbox,ybox);
 
    xlimit1=[nodeB.corner(2,2), nodeB.corner(2,3)];
    ylimit1=[nodeB.corner(1,2), nodeB.corner(1,3)];
    xbox1 = xlimit1([1 1 2 2 1]);
    ybox1 = ylimit1([1 2 2 1 1]);
end