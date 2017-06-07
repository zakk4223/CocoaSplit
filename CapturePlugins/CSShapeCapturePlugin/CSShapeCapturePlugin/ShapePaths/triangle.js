var name = "Triangle"


var createPath = function(newPath, frame)
{
    newPath.moveToPoint({x:0, y:0});
    newPath.lineToPoint({x:frame.width, y:0});
    newPath.lineToPoint({x:frame.width/2, y:frame.height});
    newPath.closePath();
}
