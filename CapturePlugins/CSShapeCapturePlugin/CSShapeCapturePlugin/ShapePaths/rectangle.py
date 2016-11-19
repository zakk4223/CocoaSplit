from Quartz import CGPathCreateMutable, CGPathAddRect

name = "Rectangle"

def create_cgpath(frame):
    newpath = CGPathCreateMutable()
    CGPathAddRect(newpath, None, frame)
    return newpath
