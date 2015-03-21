from uuid import uuid4
from Quartz import CATransaction



class CSAnimation:
    def __init__(self, target, keyPath, animation, **kwargs):
        self.target = target
        self.keyPath = keyPath
        self.animation = animation
        self.isWaitMark = False
        self.ignore_wait = False
        self.extra_model = None
        self.duration = 0.0
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



    def apply(self, begin_time):
        if self.target:
            self.animation.setBeginTime_(begin_time)
            self.uukey = "{0}-{1}".format(self.keyPath, uuid4())
            self.target.addAnimation_forKey_(self.animation, self.uukey)
        return self.duration

    def apply_immediate(self):
        if self.target:
            p_value = self.animation.toValue()
            CATransaction.begin()
            CATransaction.setDisableActions_(True)
            self.target.setValue_forKeyPath_(p_value, self.animation.keyPath())
            if self.extra_model:
                self.extra_model.setValue_forKeyPath_(p_value, self.animation.keyPath())
            CATransaction.commit()


    def set_model_value(self):
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

