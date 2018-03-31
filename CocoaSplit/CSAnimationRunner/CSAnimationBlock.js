var block_uuid_map = {};

var CSAnimationBlock = {};

CSAnimationBlock.currentFrame = function() {
    
    var blockUUID = CATransaction.valueForKey("__CS_BLOCK_UUID__");
    return block_uuid_map[blockUUID];
}




function AnimationBlock(duration, inherit_frame) {
    
    
    var self = this;
    
    if (duration === undefined)
    {
        duration = 0.0;
    }
    
    var cframe = CSAnimationBlock.currentFrame();
    

    
    if (cframe)
    {
        self.parent_frame_begin_time = cframe.current_begin_time;
    }
    
    
    if (!inherit_frame || !cframe)
    {
        self.layout = getCurrentLayout();
        self.current_begin_time = null;
        self.latest_end_time = null;
        self.animation_info = {};
        self.animation_info["all_animations"] = {};
        self.isolated = !inherit_frame;
        self.input_map = {};
        self.label_map = {};


    } else {
        cframe.applyPendingAnimations();
        self.layout = cframe.layout;
        self.current_begin_time = cframe.current_begin_time;
        self.latest_end_time = cframe.latest_end_time;
        self.animation_info = cframe.animation_info;
        self.isolated = !inherit_frame;
        self.input_map = cframe.input_map;
        self.label_map = cframe.label_map;
    }
    
    self.animations = [];
    self.duration = duration;
    self.max_animation_time = 0.0;
    self.beginTime = 0.0;
    self.real_completion_block = null;
    self.uuid = generateUUID();
    
    if (self.duration == 0.0)
    {
        self.duration = 0.25;
    }
    
    this.internal_completion_block = function(real_completion) {
        if (real_completion)
        {
            real_completion();
        }
    }
    
    this.set_completion_block = function(completion_callable) {
        if (completion_callable)
        {
            
            CATransaction.setCompletionBlockJS(completion_callable);
        }
    }
    
    
    this.advance_begin_time = function(duration) {
        if (self.current_begin_time)
        {
            self.latest_end_time = self.current_begin_time + duration;
        }
    }
    
    
    this.add_animation = function(animation)  {
        
        self.applyPendingAnimations();
        self.animations.push(animation);
    }
    
    
    this.add_animation_real = function(animation) {
        if (!self.current_begin_time)
        {
            
            self.current_begin_time = self.layout.rootLayer.convertTimeFromLayer(CACurrentMediaTime(), null);
        }
        
        if (!self.latest_end_time)
        {
            self.latest_end_time = self.current_begin_time;
        }
        
        if (animation.duration == 0)
        {
            animation.duration = 0.001;
            animation.animation.duration = 0.001;
        }
        
        if (animation.label)
        {
            self.label_map[animation.label] = animation;
        }
        
        if (!animation.ignore_wait && animation.animation)
        {
            var a_delegate = new CSJSAnimationDelegate(animation);
           animation.animation.delegate = a_delegate;
        }
        
        var use_begin_time = self.current_begin_time;
        
        if (animation.cs_input && self.input_map[animation.cs_input.uuid])
        {
            use_begin_time = self.input_map[animation.cs_input.uuid].begin_time;
        }
        
        var a_duration = animation.apply(use_begin_time);
        self.latest_end_time = Math.max(self.latest_end_time, animation.end_time);
        
        if (animation.uukey && animation.target)
        {
            self.animation_info.all_animations[animation.uukey]= animation.target;
        }
        
        if (animation.cs_input)
        {
            if (self.input_map[animation.cs_input.uuid])
            {
                
                self.input_map[animation.cs_input.uuid].end_time = Math.max(animation.end_time, self.input_map[animation.cs_input.uuid].end_time);
                
            } else {
                self.input_map[animation.cs_input.uuid] = {begin_time: self.current_begin_time, end_time: animation.end_time};
            }
        }
        
        //this.animations.push(animation);
        return animation;
    }
    
    
    this.add_waitmarker = function(duration, target, wait_only) {
        if (duration === undefined)
        {
            duration = 0.0;
        }
        new_mark = new CSAnimation(null, "__CS_WAIT_MARK", null);
        new_mark.isWaitMark = true;
        new_mark.duration = duration;
        new_mark.cs_input = target;
        new_mark.wait_only = wait_only;
        self.animations.push(new_mark);
        self.applyPendingAnimations();

        return new_mark;

    }
    
    
    this.add_waitmarker_real = function(waitMark) {
        
        if (!self.current_begin_time)
        {
            self.current_begin_time = self.layout.rootLayer.convertTimeFromLayer(CACurrentMediaTime(), null);
        }
        
        if (!self.latest_end_time)
        {
            self.latest_end_time = self.current_begin_time;
        }
        

        if (waitMark.cs_input)
        {
            var input_begin_time = self.current_begin_time;
            var input_end_time = self.current_begin_time;
            if (self.input_map[waitMark.cs_input.uuid])
            {
                input_begin_time = self.input_map[waitMark.cs_input.uuid].end_time;
                input_end_time = self.input_map[waitMark.cs_input.uuid].end_time;
            }
            input_begin_time += waitMark.duration;
            
            self.input_map[waitMark.cs_input.uuid] = {begin_time: input_begin_time, end_time: Math.max(input_end_time, input_begin_time)}
            
            
            this.latest_end_time = Math.max(self.latest_end_time, input_begin_time);
            return waitMark;
        } else if (waitMark.label && self.label_map[waitMark.label]) {
            self.current_begin_time = self.label_map[waitMark.label].end_time;
        } else {
            if (!waitMark.wait_only)
            {
                self.current_begin_time = self.latest_end_time;
            }
        }
        
        
        waitMark.apply(self.current_begin_time);
        this.latest_end_time = Math.max(self.latest_end_time, waitMark.end_time);
        
        self.current_begin_time += waitMark.duration;
    
        return waitMark;
    }
    
    
    this.applyPendingAnimations = function()
    {
        for(var i = 0, len = self.animations.length; i < len; i++)
        {
            var anim = self.animations[i];
            if (anim.isWaitMark)
            {
                self.add_waitmarker_real(anim);
            } else {
                self.add_animation_real(anim);
            }
        }
        
        self.animations = [];
    }
    
    
    
    this.commit = function()
    {
        
        self.applyPendingAnimations();
        
        CATransaction.setValueForKey(null, "__CS_BLOCK_UUID__");
        self.animation_info = null;
        delete block_uuid_map[self.uuid];
        if (self.doScriptWait)
        {
            self.waitAnimation();
        }
        CATransaction.commit();
        if (!self.isolated)
        {
            let cframe = CSAnimationBlock.currentFrame();
            if (cframe)
            {

                cframe.current_begin_time = self.current_begin_time;
                cframe.latest_end_time = self.latest_end_time;
            }
        }
        

    }
    
    this.waitTransition = function() {
        if (self.parent_frame_begin_time)
        {
            self.current_begin_time = self.parent_frame_begin_time;
        }
    }
    
    
    this.waitAnimation = function(duration, target) {
        return self.add_waitmarker(duration, target, 0);
    }
    
    this.wait = function(duration, target) {
        return self.add_waitmarker(duration, target, 1);
    }
    
    CATransaction.begin();
    self.doScriptWait = false;
    block_uuid_map[self.uuid] = self;
    CATransaction.setValueForKey(self.uuid, "__CS_BLOCK_UUID__");
    //this.current_begin_time = 0;


}

var setCompletionBlock = function(completion_block) {
    

    CSAnimationBlock.currentFrame().set_completion_block(completion_block);
}

var wait = function(duration)
{
    return CSAnimationBlock.currentFrame().wait(duration);
}

var waitAnimation = function(duration) {
    return CSAnimationBlock.currentFrame().waitAnimation(duration);
}

var animationDuration = function() { CSAnimationBlock.currentFrame().duration; }

var beginIsolatedAnimation = function(duration) {
    if (duration === undefined)
    {
        duration = 0.25;
    }
    
    return new AnimationBlock(duration, false);
}


var beginAnimation = function(duration) {
    
    if (duration === undefined)
    {
        duration = 0.25;
    }
    
    return new AnimationBlock(duration, true);
}

var commitAnimation = function() {
    var cframe = CSAnimationBlock.currentFrame();
    cframe.commit();
}

var waitTransition = function () {
    var cframe = CSAnimationBlock.currentFrame();
    if (cframe)
    {
        cframe.waitTransition();
    }
}


var waitScript = function() {
    var cframe = CSAnimationBlock.currentFrame();
    if (cframe)
    {
        cframe.isolated = false;
        cframe.doScriptWait = true;
    }
}
