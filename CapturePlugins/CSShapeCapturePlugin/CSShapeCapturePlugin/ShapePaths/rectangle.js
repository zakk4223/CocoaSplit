var name = "Rectangle"


var createPath = function(newPath, frame)
{
    newPath.appendBezierPathWithRect(frame);
    newPath.closePath();
}
