function CSAnimationInput(cs_input) {
    
 
    this.input = cs_input;
    this.layer = cs_input.layer;
    this.animationLayer = cs_input.animationLayer();
    
    this.position = function() { return this.animationLayer.frame.origin; }
    this.width = function() { return this.animationLayer.bounds.width; }
    this.height = function() { return this.animationLayer.bounds.height; }
    this.minY = function() { return NSMinY(this.animationLayer.frame); }
    this.maxY = function() { return NSMaxY(this.animationLayer.frame); }
    this.minX = function() { return NSMinX(this.animationLayer.frame); }
    this.maxX = function() { return NSMaxX(this.animationLayer.frame); }
    this.midY = function() { return NSMidY(this.animationLayer.frame); }
    this.midX = function() { return NSMidX(this.animationLayer.frame); }


    
    this.make_animation_values = function(initial_value, anim_value, valueMaker) {
        
        var ret_val;
        
        if (isArray(anim_value))
        {
            var val_arr = [];
            if (initial_value !== undefined)
            {
                val_arr.push(initial_value)
            }
            var vLen, i;
            for(vLen = anim_value.length, i=0; i<vLen; i++)
            {
                var aVal = anim_value[i];
                var nVal = valueMaker(aVal);
                val_arr.push(nVal);
            }
            ret_val = val_arr;
        } else {
            ret_val = valueMaker(anim_value);
        }
        
        return ret_val;
    }
    
    
    this.basic_animation = function(forKey, withDuration) {
        var cab = CABasicAnimation.animationWithKeyPath(forKey);
        if (withDuration === undefined)
        {
            cab.duration = CSAnimationBlock.currentFrame().duration;
        } else {
            cab.duration = withDuration;
        }
        return cab;
    }
    
    this.add_animation = function(animation, target, keyPath) {
        animation.cs_input = this;
        CSAnimationBlock.currentFrame().add_animation(animation, target, keyPath);
        return animation;
    }
    
    this.keyframe_animation = function(forKey, withDuration) {
        var kanim = CAKeyframeAnimation.animationWithKeyPath(forKey);
        if (withDuration !== undefined)
        {
            kanim.duration = withDuration;
        } else {
            kanim.duration = CSAnimationBlock.currentFrame().duration;
        }
        kanim.calculationMode = "paced";
        kanim.rotationMode = "autoReverse";
        return kanim;
    }
    
    
    this.simple_animation = function(forKey, toValue, withDuration, kwargs) {
        var real_end_value = toValue;
        
        if (kwargs === undefined)
        {
            kwargs = {};
        }
        
        var default_kwargs = CSAnimationBlock.currentFrame().animation_info['__cs_default_kwargs'];
        var merged_kwargs = Object.assign({}, default_kwargs, kwargs);
        
        if (merged_kwargs === undefined)
        {
            merged_kwargs = {};
        }
        var for_layer = this.layer;
        
        var banim;
        if (isArray(toValue))
        {
            banim = this.keyframe_animation(forKey, withDuration);
            real_end_value = toValue[-1];
            banim.values = toValue;
        } else {
            banim = this.basic_animation(forKey, withDuration);
            if (merged_kwargs["use_fromVal"])
            {
                banim.fromValue = merged_kwargs["use_fromVal"];
            }
            banim.toValue = toValue;
        }
        
        
        if (merged_kwargs["source_only"])
        {
            for_layer = this.layer.sourceLayer;
        }
        
        if (merged_kwargs["use_layer"])
        {
            for_layer = merged_kwargs["use_layer"]
        }
        
        var csanim = new CSAnimation(for_layer, forKey, banim, merged_kwargs);
        if (!merged_kwargs["autoreverse"])
        {
            this.animationLayer.setValueForKeyPath(real_end_value, forKey);
        }
        if (merged_kwargs["extra_keypath"])
        {
            this.animationLayer.setValueForKeyPath(real_end_value, merged_kwargs["extra_keypath"]);
        }
        
        csanim.toValue = real_end_value;
        return this.add_animation(csanim, for_layer, forKey);
        
    }
    
    this.waitAnimation = function(duration, kwargs) {
        return CSAnimationBlock.currentFrame().waitAnimation(duration, this, kwargs);
    }
    
    this.wait = function(duration) {
        return CSAnimationBlock.currentFrame().wait(duration, this);
    }

    
    this.real_coordinate_from_fract = function(x,y) {
        var ret_x = x;
        var ret_y = y;
        if (x > 0.0 && x <= 1.0)
        {
            var slayer = this.layer.superlayer();
            ret_x = slayer.bounds.x + (slayer.bounds.width * x);
        }
        
        if (y > 0.0 && y <= 1.0)
        {
            var slayer = this.layer.superlayer();
            ret_y = slayer.bounds.y + (slayer.bounds.height *y);
        }
        return {x: ret_x, y: ret_y};
    }
    
  
    
    /**
     * Move the input's Y coordinate. This change is permanent/saved. If you want non-saved move use the translate* animations
     * @param {number} move_y - the amount to move the input's Y coordinate
     */
    this.moveY = function(move_y, duration, kwargs) {
        kwargs = kwargs || {};
        var cpos = this.animationLayer.position;
        self = this;
        var vmk = function(val) {
            var new_coord = self.real_coordinate_from_fract(0,val);
            cpos.y = cpos.y + new_coord.y;
            return cpos.y;
        }
        
        var anim_vals = this.make_animation_values(cpos.y, move_y, vmk);
        return this.simple_animation('position.y', anim_vals, duration, kwargs);
    }
    
 
    /**
     * Move the input's X coordinate. This change is permanent/saved. If you want non-saved move use the translate* animations
     * @param {number} move_=x - the amount to move the input's X coordinate
     */
    this.moveX = function(move_x, duration, kwargs) {
        kwargs = kwargs || {};
        var cpos = this.animationLayer.position;
        self = this;
        var vmk = function(val) {
            var new_coord = self.real_coordinate_from_fract(val,0);
            cpos.x = cpos.x + new_coord.x;
            return cpos.x;
        }
        
        var anim_vals = this.make_animation_values(cpos.x, move_x, vmk);
        return this.simple_animation('position.x', anim_vals, duration, kwargs);
    }
    
    
    this.scaleLayer = function(scaleVal, duration, kwargs) {
        var cval = this.animationLayer.valueForKeyPath('transform.scale');
        var anim_vals = this.make_animation_values(cval, scaleVal, function(x) { return x; });
        return this.simple_animation('transform.scale', anim_vals, duration, kwargs);
    }
    
    this.scaleSize = function(scaleVal, duration, kwargs) {
        var curr_width = this.width;
        var curr_height = this.height;
        
        
    }
    
    /**
     * Set the width of the input. This change saves/is permanent
     * @param {number} width - The input's new width
     */
    this.sizeWidth = function(width, duration, kwargs) {
        kwargs = kwargs || {};
        
        var move_frames = [];
        var original_width = this.width();
        
        var vmk = function(val) {
            var mvval;
            if (kwargs['anchorLeft'])
            {
                mvval = (val - original_width)/2;
            } else if (kwargs['anchorRight']) {
                mvval = (original_width - val)/2;
            }
            if (mvval !== undefined)
            {
                move_frames.push(mvval);
            }
            return val;
        }
        
        var anim_vals = this.make_animation_values(original_width, width, vmk);
        
        kwargs['use_fromVal'] = original_width;
        kwargs['extra_keypath'] = 'bounds.size.width';
        var ret = this.simple_animation('fakeWidth', anim_vals, duration, kwargs);
        delete kwargs['use_fromVal'];
        delete kwargs['extra_keypath'];
        this.moveX(move_frames, duration, kwargs);
        return ret;
    }
    
    
    /**
     * Set the height of the input. This change saves/is permanent
     * @param {number} height - The input's new height
     */
    this.sizeHeight = function(height, duration, kwargs) {
        kwargs = kwargs || {};
        
        var move_frames = [];
        var original_height = this.height();
        
        var vmk = function(val) {
            var mvval;
            if (kwargs['anchorBottom'])
            {
                mvval = (val - original_height)/2;
            } else if (kwargs['anchorTop']) {
                mvval = (original_height - val)/2;
            }
            if (mvval !== undefined)
            {
                move_frames.push(mvval);
            }
            return val;
        }
        
        var anim_vals = this.make_animation_values(original_height, height, vmk);
        
        kwargs['use_fromVal'] = original_height;
        kwargs['extra_keypath'] = 'bounds.size.height';
        var ret = this.simple_animation('fakeHeight', anim_vals, duration, kwargs);
        delete kwargs['use_fromVal'];
        delete kwargs['extra_keypath'];
        this.moveY(move_frames, duration, kwargs);
        return ret;
    }

    this.rotate = function(angle, duration, kwargs) {
        
        var fromVal = this.animationLayer.valueForKeyPath("transform.rotation.z");
        var anim_vals = this.make_animation_values(fromVal, angle, function(x) { return fromVal+(x * Math.PI /180)});
        
        return this.simple_animation("transform.rotation.z", anim_vals, duration, kwargs);
    }
    
}
