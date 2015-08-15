from Quartz import CGPathCreateMutable,CGPathMoveToPoint, CGPathCloseSubpath, CGPathAddLineToPoint

name = "Triangle"

def create_cgpath(frame):
    newPath = CGPathCreateMutable()
    CGPathMoveToPoint(newPath, None, 0,0)
    CGPathAddLineToPoint(newPath, None, frame.size.width, 0)
    CGPathAddLineToPoint(newPath, None, frame.size.width/2, frame.size.height)
    CGPathCloseSubpath(newPath)
    return newPath
