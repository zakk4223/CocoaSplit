from Quartz import CGPathCreateMutable, CGPathAddArc, CGPathCloseSubpath, CGPathMoveToPoint, CGPathAddLineToPoint
import math

name = "Arc"

def create_cgpath(frame):
    newpath = CGPathCreateMutable()
    CGPathAddArc(newpath, None, 0,0, math.sqrt(frame.size.width**2 + frame.size.height**2)/2, math.radians(90), 0, True)
    CGPathAddLineToPoint(newpath, None, 0,0)
    return newpath
