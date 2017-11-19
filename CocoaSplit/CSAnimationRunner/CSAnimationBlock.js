var block_uuid_map = {};

var CSAnimationBlock = {};

CSAnimationBlock.currentFrame = function() {
    
    var blockUUID = CATransaction.valueForKey("__CS_BLOCK_UUID__");
    return block_uuid_map[blockUUID];
}




function AnimationBlock(duration) {
    
    if (duration === undefined)
    {
        duration = 0.0;
    }
    
    cframe = CSAnimationBlock.currentFrame();
    if (cframe === undefined)
    {
        this.layout = getCurrentLayout();
        this.current_begin_time = null;
        this.current_end_time = null;
        this.animation_info = {};
    } else {
        this.layout = cframe.layout;
        this.current_begin_time = cframe.current_begin_time;
        this.current_end_time = cframe.current_end_time;
        this.animation_info = cframe.animation_info;
    }
    
    this.animations = [];
    this.duration = duration;
    this.max_animation_time = 0.0;
    this.beginTime = 0.0;
    this.real_completion_block = null;
    this.input_map = {};
    this.label_map = {};
    this.uuid = generateUUID();
    
    if (this.duration == 0.0)
    {
        this.duration = 0.25;
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
        if (this.current_begin_time)
        {
            this.latest_end_time = this.current_begin_time + duration;
        }
    }
    
    
    this.add_animation = function(animation)  {

        this.animations.push(animation);
    }
    
    
    this.add_animation_real = function(animation) {
        if (!this.current_begin_time)
        {
            this.current_begin_time = this.layout.rootLayer.convertTimeFromLayer(CACurrentMediaTime(), null);
        }
        
        if (animation.duration == 0)
        {
            animation.duration = 0.001;
            animation.animation.duration = 0.001;
        }
        
        if (animation.label)
        {
            this.label_map[animation.label] = animation;
        }
        
        if (!animation.ignore_wait && animation.animation)
        {
            var a_delegate = new CSJSAnimationDelegate(animation);
           animation.animation.delegate = a_delegate;
        }
        
        var a_duration = animation.apply(this.current_begin_time);
        this.latest_end_time = animation.end_time;
        if (animation.uukey && animation.target)
        {
            this.animation_info.all_animations[animation.uukey]= animation.target;
        }
        
        if (animation.cs_input)
        {
            if (this.input_map[animation.cs_input.uuid])
            {
                this.input_map[animation.cs_input.uuid] = Math.max(this.latest_end_time, this.input_map[animation.cs_input.uuid]);
            } else {
                this.input_map[animation.cs_input.uuid] = this.latest_end_time;
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
        this.animations.push(new_mark);
        return new_mark;
    }
    
    
    this.add_waitmarker_real = function(waitMark) {
        if (!this.current_begin_time)
        {
            this.current_begin_time = this.layout.rootLayer.convertTimeFromLayer(CACurrentMediaTime(), null);
        }
        

        
        

        if (waitMark.cs_input && this.input_map[waitMark.cs_input.uuid])
        {
            this.current_begin_time = this.input_map[waitMark.cs_input.uuid];
        } else if (waitMark.label && this.label_map[waitMark.label]) {
            this.current_begin_time = this.label_map[waitMark.label].end_time;
        } else {
            if (!wait_only)
            {
                this.current_begin_time = this.latest_end_time;
            }
        }
        
        
        waitMark.apply(this.current_begin_time);
        this.latest_end_time = Math.max(this.latest_end_time, waitMark.end_time);
        this.current_begin_time += waitMark.duration;
        return waitMark;
    }
    
    
    this.commit = function()
    {
        
        for(var i = 0, len = this.animations.length; i < len; i++)
        {
            var anim = this.animations[i];
            if (anim.isWaitMark)
            {
                this.add_waitmarker_real(anim);
            } else {
                this.add_animation_real(anim);
            }
        }
        
        CATransaction.setValueForKey(null, "__CS_BLOCK_UUID__");
        this.animation_info = null;
        delete block_uuid_map[this.uuid];
        CATransaction.commit();
        
    }
    
    this.waitAnimation = function(duration, target) {
        return this.add_waitmarker(duration, target, 0);
    }
    
    this.wait = function(duration, target) {
        return this.add_waitmarker(duration, target, 1);
    }
    
    CATransaction.begin();
    block_uuid_map[this.uuid] = this;
    
    CATransaction.setValueForKey(this.uuid, "__CS_BLOCK_UUID__");
    this.current_begin_time = 0;


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

var beginAnimation = function(duration) {
    
    if (duration === undefined)
    {
        duration = 0.25;
    }
    
    return new AnimationBlock(duration);
}

var commitAnimation = function() {
    var cframe = CSAnimationBlock.currentFrame();
    cframe.commit();
}
