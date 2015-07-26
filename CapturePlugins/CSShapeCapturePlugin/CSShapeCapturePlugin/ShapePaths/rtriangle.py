from Quartz import CGPathCreateWithEllipseInRect,CGPathCreateMutable,CGPathMoveToPoint, CGPathCloseSubpath, CGPathAddLineToPoint

name = "Right Triangle"

def create_cgpath(frame):
    newPath = CGPathCreateMutable()
    CGPathMoveToPoint(newPath, None, 0,0)
    CGPathAddLineToPoint(newPath, None, frame.size.width, 0)
    CGPathAddLineToPoint(newPath, None, 0, frame.size.height)
    CGPathCloseSubpath(newPath)
    return newPath
