from Foundation import NSLog

animation_name = "RotateDemo"
animation_description = "Rotate demo"

animation_inputs = ["source1", "source2"]
animation_params = ["degrees"]


def do_animation():

    NSLog("RUNNING ANIMATION")
    source1 = inputByName('source1')
    source2 = inputsByName('source2')

    rotDegrees = float(inputs['degrees'])

    #simple rotation, rotate from current state by X degrees. no duration is given, so the user specified duration is used.
    source1.rotate(rotDegrees)

    #wait for the previous animation(s) to finish
    waitAnimation()

    #rotate again, but this time use our own duration
    source1.rotate(rotDegrees, 1.5)

    #wait again
    waitAnimation()

    #rotate again, but when we're done rotate back to where we were
    source1.rotate(rotDegrees, 1.5, autoreverse=True)

    waitAnimation()

    #This rotation (rotateTo()) specifies the final angle, unlike the normal rotate() which adds the angle to whatever the current one is
    #rotate back to normal

    source1.rotateTo(0, 1.5)


    waitAnimation()

    #you can write normal python code in here too, loops, conditionals etc.
    #if we were assigned a 2nd source, rotate it too

    if source2:
        #some notes:
        # 1) without a waitAnimation() call between them, these two animations start at the same time.
        # 2) the 'repeatcount' keyword tells the animation to repeat itself however many times we specify
        # 3) the negative angle causes the source to rotate in the opposite direction as the previous rotations
        source1.rotate(-360, 2.5, repeatcount=3)
        source2.rotate(-360, 2.5, repeatcount=3)

