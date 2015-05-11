from uuid import uuid4
from Quartz import CATransaction,CAMediaTimingFunction
from Foundation import NSLog



class CSAnimation:
    def __init__(self, target, keyPath, animation, **kwargs):
        self.target = target
        self.keyPath = keyPath
        self.animation = animation
        self.isWaitMark = False
        self.isWaitOnly = False
        self.ignore_wait = False
        self.extra_model = None
        self.duration = 0.0
        self.cs_input = None
        self.label = None
        self.end_time = 0
        self.begin_time = 0
        self.completion_handler = None
        self.internal_completion_handler = None
        self.toValue = None
        
        if animation:
            animation.setRemovedOnCompletion_(False)
            animation.setFillMode_("forwards")
            self.duration = animation.duration()
     


        if 'repeatcount' in kwargs:
            self.repeatcount(kwargs['repeatcount'])
        if 'autoreverse' in kwargs:
            self.autoreverse()

        if 'timing' in kwargs:
            self.timingFunction(kwargs['timing'])
        if 'repeatduration' in kwargs:
            self.repeatduration(kwargs['repeatduration'])
    
        if 'extra_model' in kwargs:
            self.extra_model = kwargs['extra_model']

        if 'on_complete' in kwargs:
            self.completion_handler = kwargs['on_complete']
        
        if 'label' in kwargs:
            self.label = kwargs['label']
                
        self.internal_completion_handler = self.set_model_value
        


    def completed(self):
        if self.internal_completion_handler:
            self.internal_completion_handler(self)
        if self.completion_handler:
            self.completion_handler(self)

    def apply(self, begin_time):
        self.begin_time = begin_time
        
        
        if self.target and not self.isWaitMark:
            self.animation.setBeginTime_(begin_time)
            self.uukey = "{0}-{1}".format(self.keyPath, uuid4())
            self.target.addAnimation_forKey_(self.animation, self.uukey)
        if not self.ignore_wait:
            self.end_time = begin_time + self.duration
        return self.duration

    def apply_immediate(self):
        if self.target:
            p_value = self.toValue
            CATransaction.begin()
            #CATransaction.setDisableActions_(True)
            self.target.setValue_forKeyPath_(p_value, self.animation.keyPath())
            if self.extra_model:
                self.extra_model.setValue_forKeyPath_(p_value, self.animation.keyPath())
            CATransaction.commit()


    def set_model_value(self, realme=None):

        if self.target:
            p_layer = self.target.presentationLayer()
            p_value = p_layer.valueForKeyPath_(self.animation.keyPath())
            CATransaction.begin()
            CATransaction.setDisableActions_(True)
            self.target.setValue_forKeyPath_(p_value, self.animation.keyPath())
            if self.extra_model:
                self.extra_model.setValue_forKeyPath_(p_value, self.animation.keyPath())
            self.target.removeAnimationForKey_(self.uukey)
            CATransaction.commit()

    def repeatduration(self, duration):
        if self.animation:
            self.animation.setRepeatDuration_(duration)
        self.duration = duration

    def timingFunction(self, fname):
        if self.animation:
            tfunc = CAMediaTimingFunction.functionWithName_(fname)
            if tfunc:
                self.animation.setTimingFunction_(tfunc)

    def repeatcount(self, r_count):
        if self.animation:
            if r_count == 'forever':
                self.ignore_wait = True
                r_count = float(1e50) #I think this is HUGE_VALF
            else:
                self.duration *= r_count
            self.animation.setRepeatCount_(r_count)

    def autoreverse(self):
        if self.animation:
            self.animation.setAutoreverses_(True)
        self.duration *= 2
        return self


class CSAnimationGroup(CSAnimation):

    def addAnimation(self, animation):
        if not hasattr(self, 'animations'):
            self.animations = [animation]
        else:
            self.animations.append(animation)
        self.animation.setAnimations_(self.animations)


    def set_model_value(self):
        if self.target:
            p_layer = self.target.presentationLayer()
            real_animations = self.animation.animations()
            for anim in real_animations:
                kpath = anim.keyPath()
                p_value = p_layer.valueForKeyPath_(kpath)
                self.target.setValue_forKeyPath_(p_value, kpath)
            
            self.target.removeAnimationForKey_(self.uukey)

