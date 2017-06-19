

var runAnimationForLayoutWithExtraDictionary = function(animation_string, layout, extraDictionary) {
    var default_animation_time = extraDictionary["__default_animation_time__"];
    beginAnimation(default_animation_time);
    var all_animations = {};
    CSAnimationBlock.currentFrame().layout = layout;
    CSAnimationBlock.currentFrame().animation_info['__cs_default_kwargs'] = {};
    CSAnimationBlock.currentFrame().animation_info['all_animations'] = all_animations;

    
    try {
        setCompletionBlock(function() { console.log("COMPLETION BLOCK");});
        eval(animation_string);
    }
    catch(err) {
        throw err;
    } finally {
        commitAnimation();
    }
    
    return all_animations;
}


var isArray = function(arr) {
    return Object.prototype.toString.call(arr) === '[object Array]';
}


var getCurrentLayout = function() {
    current_frame = CSAnimationBlock.currentFrame();
    if (current_frame)
    {
        return current_frame.layout;
    }
    return captureController.activeLayout;
}

var inputByName = function(name) {
    var layout = getCurrentLayout();
    var real_input = layout.inputForName(name);
    if (real_input)
    {
        return new CSAnimationInput(real_input);
    }
    return null;
}

