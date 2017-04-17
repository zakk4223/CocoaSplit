import objc
import PyObjCTools.AppHelper
from Foundation import NSObject,NSLog
from Quartz import CACurrentMediaTime,CATransaction
from CSAnimation import *



def current_frame():
  return CATransaction.valueForKey_("__CS_BLOCK_OBJECT__")

class CSAnimationDelegate(NSObject):

    @objc.signature('v@:@c')
    def animationDidStop_finished_(self, animation, finished):
        cs_anim = animation.valueForKeyPath_("__CS_COMPLETION__")
        cs_anim.completed()


class AnimationBlock:
    def __init__(self, duration = 0.0):
        cframe = current_frame()
        if cframe:
            self.layout = cframe.layout
            self.animation_module = cframe.animation_module
            self.current_begin_time = cframe.current_begin_time
            self.current_end_time = cframe.current_end_time
        else:
            self.layout = None
            self.animation_module = None
            self.current_begin_time = None
            self.current_end_time = None
        
        CATransaction.begin()
        CATransaction.setValue_forKey_(self, "__CS_BLOCK_OBJECT__")
        self.animations = []
        self.duration = duration
        self.max_animation_time = 0.0
        self.beginTime =  0.0
        self.real_completion_block = None
        self.input_map = {}
        self.label_map = {}
        
        if not self.duration:
            self.duration = 0.25


    def internal_completion_block(self, real_completion):
        if real_completion:
            real_completion()

    def set_completion_block(self, completion_callable):
        if completion_callable:
            CATransaction.setCompletionBlock_(lambda: self.internal_completion_block(completion_callable))


    def add_waitmarker(self, duration=0, target=None, wait_only=None, **kwargs):
        if not self.current_begin_time:
            self.current_begin_time = self.layout.rootLayer().convertTime_fromLayer_(CACurrentMediaTime(), None)

        new_mark = CSAnimation(None, "__CS_WAIT_MARK", None, **kwargs)
        new_mark.isWaitMark = True
        new_mark.duration = duration
        new_mark.cs_input = target
        if new_mark.cs_input and new_mark.cs_input in self.input_map:
            self.current_begin_time = self.input_map[new_mark.cs_input]
        elif new_mark.label and new_mark.label in self.label_map:
            self.current_begin_time = self.label_map[new_mark.label].end_time
        else:
            if not wait_only:
                self.current_begin_time = self.latest_end_time
        new_mark.apply(self.current_begin_time)
        self.latest_end_time = max(self.latest_end_time, new_mark.end_time)
        self.current_begin_time += new_mark.duration
        #self.animations.append(new_mark)
        return new_mark

    def add_animation(self, animation, target, keyPath):
        
        if not self.current_begin_time:
            self.current_begin_time = self.layout.rootLayer().convertTime_fromLayer_(CACurrentMediaTime(), None)
        if animation.duration == 0:
            #hax
            animation.duration = 0.001
            animation.animation.setDuration_(0.001)

        if animation.label:
            self.label_map[animation.label] = animation
        
        NSLog("CURRENT BEGIN %f", self.current_begin_time)
        
        a_duration = animation.apply(self.current_begin_time)

        self.latest_end_time = animation.end_time
        
        if (animation.uukey and animation.target):
            self.animation_module.all_animations[animation.uukey] = animation.target



        if animation.cs_input:
            if animation.cs_input in self.input_map:
                self.input_map[animation.cs_input] = max(self.latest_end_time, self.input_map[animation.cs_input])
            else:
                self.input_map[animation.cs_input] = self.latest_end_time


        if not animation.ignore_wait and animation.animation:
            animation.animation.setValue_forKeyPath_(animation, "__CS_COMPLETION__")
            animation.animation.setDelegate_(CSAnimationDelegate.alloc().init())
        self.animations.append(animation)

        return animation

    def wait(self, duration=0, target=None, **kwargs):
        waitmark = self.add_waitmarker(duration=duration, target=target, wait_only=1, **kwargs)

    def waitAnimation(self, duration=0, target=None, **kwargs):
        return self.add_waitmarker(duration=duration, target=target, **kwargs)

    def commit(self):
        CATransaction.commit()




def setCompletionBlock(completion_block):
    NSLog("SET BLOCK %@", completion_block)
    current_frame().set_completion_block(completion_block)

def wait(duration=0):
    current_frame().wait(duration, None)

def waitAnimation(duration=0, **kwargs):
    current_frame().waitAnimation(duration=duration, **kwargs)

def animationDuration():
    current_frame().duration

def beginAnimation(duration=0.25):

    new_frame = AnimationBlock(duration)


def commitAnimation():
    current_frame().commit()


