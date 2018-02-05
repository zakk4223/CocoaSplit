

CSAnimation = function(target, keyPath, animation) {
    
    this.target = target;
    this.keyPath = keyPath;
    this.animation = animation;
    this.isWaitMark = false;
    this.isWaitOnly = false;
    this.ignore_wait = false;
    this.extra_model = null;
    this.duration = 0.0;
    this.cs_input = null;
    this.label = null;
    this.end_time = 0;
    this.begin_time = 0;
    this.completion_handler = null;
    this.internal_completion_handler = null;
    this.toValue = null;
    this.baseLayer = null;
    this.layout = null;
    this.uukey = null;
    this.wait_only = null;
    
    
    
    
    var self = this;
    this.completed = function(what) {
        if (self.internal_completion_handler)
        {
            self.internal_completion_handler(self);
        }
        if (self.completion_handler)
        {
            self.completion_handler(self);
        }
    }
    
    this.apply = function(begin_time) {
        this.begin_time = begin_time;
        if (this.target && !this.isWaitMark)
        {
            this.animation.beginTime = begin_time;
            this.uukey = this.keyPath + "-" + generateUUID();
            applyAnimationAsync(this.target, this.animation, this.uukey);
        }
        
        if (!this.ignore_wait)
        {
            this.end_time = begin_time + this.duration;
        }
        
        return this.duration;
    }
    
    this.waitAnimation = function(duration) {
        CSAnimationBlock.currentFrame().waitAnimation(duration, this);
        return this;
    }
    
    this.apply_immediate = function() {
        if (this.target)
        {
            var p_value = this.toValue;
            CATransaction.begin();
            this.target.setValueForKeyPath(p_value, this.animation.keyPath);
            if (this.extra_model)
            {
                this.extra_model.setValueForKeyPath(p_value, this.animation.keyPath);
            }
            CATransaction.commit();
        }
    }
    
    this.set_model_value = function(realme) {
        if (this.target)
        {
            var p_layer = this.target.presentationLayer();
            if (!p_layer)
            {
                return;
            }
            
            var p_value = p_layer.valueForKeyPath(this.animation.keyPath);
            CATransaction.begin();
            CATransaction.setDisableActions(true);
            this.target.setValueForKeyPath(p_value, this.animation.keyPath);
            if (this.extra_model)
            {
                this.extra_model.setValueForKeyPath(p_value, this.animation.keyPath);
            }
            this.target.removeAnimationForKey(this.uukey);
            CATransaction.commit();
            //this.target = null;
            this.animation.delegate = null;
        }
    }
    
    this.internal_completion_handler = this.set_model_value;
    
    this.repeatduration = function(duration) {
        if (this.animation)
        {
            this.animation.repeatDuration = duration;
        }
        this.duration = duration;
    }
    
    this.timingFunction = function(fname) {
        if (this.animation)
        {
            var tfunc = CAMediaTimingFunction.functionWithName(fname);
            if (tfunc)
            {
                this.animation.setTimingFunction(tfunc);
            }
        }
        return this;
    }
    
    this.repeatforever = function() {
        return this.repeatcount('forever');
    }
    
    
    this.repeatcount = function(r_count) {
        if (this.animation)
        {

            if (r_count == 'forever')
            {

                this.ignore_wait = true;
                r_count = FLT_MAX;
            } else {
                this.duration *= r_count;
            }
            this.animation.repeatCount = r_count;
        }
        return this;
    }
    
    this.autoreverse = function() {
        if (this.animation)
        {
            this.animation.autoreverses = true;
        }
        this.duration *= 2;
        return this;
    }
    
    if (animation)
    {
        animation.removedOnCompletion = 0;
        //animation.fillMode = "forwards";
        this.duration = animation.duration;
    }
    
    this.set_extra_model = function(extra_model) {
        this.extra_model = extra_model;
        return this;
    }
    
    this.set_on_complete = function(on_complete) {
        this.completion_handler = on_complete;
        return this;
    }
    
    this.set_label = function(label) {
        this.label = label;
        return this;
    }
    

}

