from Quartz import CGPathCreateWithEllipseInRect

name = "Circle"

def create_cgpath(frame):
    return CGPathCreateWithEllipseInRect(frame, None)
