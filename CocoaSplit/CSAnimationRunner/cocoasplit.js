

var runAnimationForLayoutWithExtraDictionary = function(animation_string, layout, extraDictionary) {
    var default_animation_time = extraDictionary["__default_animation_time__"];
    beginAnimation(default_animation_time);
    CSAnimationBlock.currentFrame().layout = layout;
    try {
        setCompletionBlock(function() { console.log("COMPLETION BLOCK");});
        eval(animation_string);
    }
    catch(err) {
        throw err;
    } finally {
        commitAnimation();
    }
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
    console.log("REAL INPUT " + real_input);
    if (real_input)
    {
        return new CSAnimationInput(real_input);
    }
    return null;
}

