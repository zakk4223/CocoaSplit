animation_name = "MovementDemo"
animation_description = "Demonstration of some movement animations"

animation_inputs = ["source1", "source2"]


def do_animation(inputs, duration):

    source1 = inputs['source1']
    source2 = inputs['source2']


    #move to bottom left corner
    source1.moveTo(0,0, 2.5)
    
    #wait until previous move is done
    waitAnimation()

    #move the input to the center, and then back to where it was before (bottom left)
    source1.moveCenter(3.0, autoreverse=True)

    waitAnimation()

    #translate to 100,100. The difference between translate* and move* is that moves done with the translate functions aren't permanent.
    #If you move an input via translate and then save the layout that move won't be reflected in the layout next time you restore it.
    #mixing move and translate calls may result in unpredictable positioning when you restore the layout

    source1.translateTo(100,100, 1.75)

    #wait until the move is done, then wait another half second
    waitAnimation(0.5)

    #translate to the center
    source1.translateCenter(1.75)

    #if there's a second source, do some more stuff
    if source2:
        #These animations happen simultaneously
        source2.moveCenter(2.5)
        source1.moveTo(500, 600, 2.5)
        waitAnimation(1.5)
        #we can use loops, too!
        for x in range(0, 5):
            source1.moveRelativeTo(source2, 0, top=0, offsetX=0)
            waitAnimation(0.1)
            source1.moveRelativeTo(source2, 0, left=0, offsetY=0)
            waitAnimation(0.1)
            source1.translateRelativeTo(source2, 0, bottom=0, offsetX=0)
            waitAnimation(0.1)
            source1.moveRelativeTo(source2, 0, right=0, offsetY=0)
            waitAnimation(0.1)









