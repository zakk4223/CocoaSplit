import objc
from Foundation import NSObject
from Quartz import CACurrentMediaTime,CATransaction
from CSAnimation import *

superLayer = None
current_frame = None
frames = []

class CSAnimationDelegate(NSObject):

    @objc.signature('v@:@c')
    def animationDidStop_finished_(self, animation, finished):
        cs_anim = animation.valueForKeyPath_("__CS_COMPLETION__")
        cs_anim.set_model_value()


class AnimationBlock:
    def __init__(self, duration = 0.0):
        CATransaction.begin()
        self.animations = []
        self.duration = duration
        self.max_animation_time = 0.0
        self.beginTime =  0.0



    def add_waitmarker(self, duration=0):
        new_mark = CSAnimation(None, "__CS_WAIT_MARK", None)
        new_mark.isWaitMark = True
        new_mark.duration = duration
        self.animations.append(new_mark)
        return new_mark

    def add_animation(self, animation, target, keyPath):
        if animation.duration > 0:
            self.animations.append(animation)
        else:
            animation.apply_immediate()
        return animation

    def waitAnimation(self, duration=0):
        return self.add_waitmarker(duration)

    def commit(self):
        add_time = CACurrentMediaTime()
        slayer_time = self.baseLayer.convertTime_fromLayer_(add_time, None)
        max_time = 0.0
        total_time = 0.0
        c_begin = slayer_time
        for anim in self.animations:
            if anim.isWaitMark:
                c_begin += max_time
                c_begin += anim.duration
                max_time = 0.0

            if not anim.ignore_wait and anim.animation:
                anim.animation.setValue_forKeyPath_(anim, "__CS_COMPLETION__")
                anim.animation.setDelegate_(CSAnimationDelegate.alloc().init())

            a_duration = anim.apply(c_begin)
            if not anim.ignore_wait:
                max_time = max(a_duration, max_time)

        CATransaction.commit()



def beginAnimation():
    global current_frame
    global frames
    global superLayer

    new_frame = AnimationBlock()
    new_frame.baseLayer = superLayer
    if current_frame:
        frames.append(CSAnimationBlock.current_frame)
    current_frame = new_frame


def commitAnimation():
    global current_frame
    global frames
    current_frame.commit()

    if not frames:
        current_frame = None
    else:
        current_frame = frames.pop()

