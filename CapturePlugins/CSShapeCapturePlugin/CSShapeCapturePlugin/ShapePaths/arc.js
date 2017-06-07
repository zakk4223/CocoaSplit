var name = "Arc"


var createPath = function(newPath, frame)
{
    
    newPath.moveToPoint({x:0,y:0});
    newPath.appendBezierPathWithArcWithCenterRadiusStartAngleEndAngleClockwise({x:0,y:0}, Math.sqrt(Math.pow(frame.width,2) + Math.pow(frame.height,2))/2, 0,90, 0);
    
    newPath.closePath();
    
}
