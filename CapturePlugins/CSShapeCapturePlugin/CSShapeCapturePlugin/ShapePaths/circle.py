from Quartz import CGPathCreateMutable, CGPathAddEllipseInRect

name = "Circle"

def create_cgpath(frame):
    newpath = CGPathCreateMutable()
    CGPathAddEllipseInRect(newpath, None, frame)
    return newpath
