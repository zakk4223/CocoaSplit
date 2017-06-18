function printPrototype(obj, i) {
    var n = Number(i || 0);
    var indent = Array(2 + n).join("-");
    
    for(var key in obj) {
        if(obj.hasOwnProperty(key)) {
            console.log(indent, key, ": ", obj[key]);
        }
    }
    
    if(obj) {
        if(Object.getPrototypeOf) {
            printPrototype(Object.getPrototypeOf(obj), n + 1);
        } else if(obj.__proto__) {
            printPrototype(obj.prototype, n + 1);
        }
    }
}

function CSAnimationInput(cs_input) {
    
 
    this.input = cs_input;
    this.layer = cs_input.layer;
    this.animationLayer = cs_input.animationLayer();
    
    this.position = function() { return this.animationLayer.frame.origin; }
    this.width = function() { return this.animationLayer.bounds.size.width; }
    this.height = function() { return this.animationLayer.bounds.size.height; }
    this.minY = function() { return NSMinY(this.animationLayer.frame); }
    this.maxY = function() { return NSMaxY(this.animationLayer.frame); }
    this.minX = function() { return NSMinX(this.animationLayer.frame); }
    this.maxX = function() { return NSMaxX(this.animationLayer.frame); }
    this.midY = function() { return NSMidY(this.animationLayer.frame); }
    this.midX = function() { return NSMidX(this.animationLayer.frame); }

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
    
    this.simple_animation = function(forKey, toValue, withDuration, kwargs) {
        var real_end_value = toValue;
        
        var merged_kwargs = kwargs;
        if (merged_kwargs === undefined)
        {
            merged_kwargs = {};
        }
        var for_layer = this.layer;
        var banim = this.basic_animation(forKey, withDuration);
        if (merged_kwargs["use_fromVal"])
        {
            banim.fromValue = merged_kwargs["use_fromVal"];
        }
        banim.toValue = toValue;
        
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
        console.log("REAL END VALUE " + real_end_value);
        
        csanim.toValue = real_end_value;
        return this.add_animation(csanim, for_layer, forKey);
        
    }
    
    this.rotate = function(angle, duration, kwargs) {
        
        var fromVal = this.animationLayer.valueForKeyPath("transform.rotation.z");
        return this.simple_animation("transform.rotation.z", fromVal+(angle * Math.PI / 180), duration, kwargs);
    }
    
}
