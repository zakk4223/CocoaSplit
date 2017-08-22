

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
    if (current_frame && current_frame.layout)
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

var setTransition = function(transition) {
    var my_layout = getCurrentLayout();
    my_layout.transitionInfo = transition;
}


var createBasicTransition = function(name, direction, duration, kwargs) {
    kwargs = kwargs || {};
    var new_transition = CSLayoutTransition.alloc().init();
    
    new_transition.transitionName = name;
    new_transition.transitionDirection = direction;
    new_transition.transitionDuration = duration;
    if (kwargs['full_scene']) {
        new_transition.transitionFullScene = kwargs['full_scene'];
    }
    
    return new_transition;
}

var clearTransition = function() {
    var my_layout = getCurrentLayout();
    my_layout.transitionInfo = null;
}


var createLayoutTransition = function(useLayout, inTransition, outTransition, layoutHoldTime) {
    var new_transition = CSLayoutTransition.alloc().init();
    new_transition.transitionLayout = useLayout;
    new_transition.preTransition = inTransition;
    new_transition.postTransition = outTransition;
    new_transition.layoutHoldTime = layoutHoldTime;
    return new_transition;
}


var createCITransition = function(name, inputMap, duration, kwargs) {
    inputMap = inputMap || {};
    if (duration === undefined) { duration = 0.25; }
    var new_cs_transition = CSLayoutTransition.alloc().init();
    
    var new_transition = CIFilter.filterWithNameWithInputParameters(name, inputMap);
    new_cs_transition.transitionFilter = new_transition;
    new_cs_transition.transitionDuration = duration;
    
    if (kwargs['full_scene'])
    {
        new_cs_transition.transitionFullScene = kwargs['full_scene'];
    }
    
    return new_cs_transition;
}


var scriptByName = function(name) {
    return captureController.getSequenceForName(name);
}


var runScriptByName = function(name) {
    var layout_script = scriptByName(name);
    if (layout_script) {
        var script_code = layout_script.animationCode;
        eval(script_code);
    }
}

var audioInputByRegex = function(regex_str) {
    var all_audio_inputs = captureController.multiAudioEngine.audioInputs;
    var re_c = new RegExp(regex_str);
    all_audio_inputs.forEach(function (e) {
                             var a_name = e.name;
                             if (re_c.test(a_name))
                             {
                                return e;
                             }
    });
    return null;
}

var setAudioInputVolume = function(name_regex, volume, duration) {
    var a_inp = audioInputByRegex(name_regex);
    if (a_inp) {
        a_inp.setVolumeAnimatedWithDuration(volume, duration);
    }
}


var runTriggerScriptInput = function(input, scriptType) {
    if (input["script_"+scriptType])
    {
        
        var inputSelf = null;
        if (input.animationLayer)
        {
            inputSelf = new CSAnimationInput(input);
        }
        (new Function("self", input["script_"+scriptType]))(inputSelf);
        inputSelf = null;
    }

}


var runTriggerScript = function(layout, scriptType) {
    var s_inputs = layout.sourceList;
    s_inputs.forEach(function (r_inp) {
                     
                     if (r_inp["script_"+scriptType])
                     {
                     
                        var inputSelf = null;
                        if (r_inp.animationLayer)
                        {
                            inputSelf = new CSAnimationInput(r_inp);
                        }
                        (new Function("self", r_inp["script_"+scriptType]))(inputSelf);
                        inputSelf = null;
                     }
    });

}


var advanceBeginTime = function(duration) {
    CSAnimationBlock.currentFrame().advance_begin_time(duration);
}


var addDummyAnimation = function(duration) {
    var basic_anim = CABasicAnimation.animationWithKeyPath("__DUMMY_ANIMATION__");
    basic_anim.duration = duration;
    
    var dummy_animation = new CSAnimation(getCurrentLayout().rootLayer, "__DUMMY_ANIMATION__", basic_anim);
    CSAnimationBlock.currentFrame().add_animation(dummy_animation, getCurrentLayout().rootLayer, "__DUMMY_ANIMATION__");
}


var layoutByName = function(name) {
    return captureController.findLayoutWithName(name);
}

var containsLayout = function(name) {
    var target_layout = getCurrentLayout();
    return target_layout.containsLayoutNamed(name);
}

var switchToLayoutByName = function(name, kwargs) {
    var layout = layoutByName(name)
    if (layout) {
        switchToLayout(layout, kwargs);
    }
}

var switchToLayout = function(layout, kwargs) {
    kwargs = kwargs || {};
    var useScripts = !kwargs['noscripts'];

    if (layout) {
        var target_layout = getCurrentLayout();
        var layoutTransition = target_layout.transitionInfo;
        if (layoutTransition && layoutTransition.transitionLayout)
        {
            if (layoutTransition.preTransition)
            {
                target_layout.transitionInfo = layoutTransition.preTransition;
                
                target_layout.replaceWithSourceLayoutUsingScripts(layoutTransition.transitionLayout, useScripts);
                waitAnimation(layoutTransition.transitionHoldTime);
            }
            target_layout.transitionInfo = layoutTransition.postTransition;
        }
        target_layout.replaceWithSourceLayoutUsingScripts(layout, useScripts);
    }
}

var mergeLayout = function(layout, kwargs) {
    
    kwargs = kwargs || {};
    var useScripts = !kwargs['noscripts'];

    if (layout)
    {
        var target_layout = getCurrentLayout();
        var layoutTransition = target_layout.transitionInfo;
        var endLayout = layout;
        
        if (layoutTransition && layoutTransition.transitionLayout)
        {
            endLayout = target_layout.mergedSourceLayout(layout);
            if (layoutTransition.preTransition)
            {
                target_layout.transitionInfo = layoutTransition.preTransition;
                target_layout.replaceWithSourceLayoutUsingScripts(layoutTransition.transitionLayout, useScripts);
                waitAnimation(layoutTransition.transitionHoldTime);
            }
            target_layout.transitionInfo = layoutTransition.postTransition;
            target_layout.replaceWithSourceLayoutUsingScripts(endLayout, useScripts);
        } else {
        
        
            target_layout.mergeSourceLayoutUsingScripts(endLayout, useScripts);
        }
        
    }
}

var mergeLayoutByName = function(name, kwargs) {
    var layout = layoutByName(name);
    if (layout) { mergeLayout(layout, kwargs); };
}

var removeLayout = function(layout, kwargs) {
    kwargs = kwargs || {};
    
    var useScripts = !kwargs['noscripts'];

    if (layout)
    {
        var target_layout = getCurrentLayout();
        var layoutTransition = target_layout.transitionInfo;
        var endLayout = layout;

        if (layoutTransition && layoutTransition.transitionLayout)
        {
            endLayout = target_layout.sourceLayoutWithRemoved(layout);
            if (layoutTransition.preTransition)
            {
                target_layout.transitionInfo = layoutTransition.preTransition;
                target_layout.replaceWithSourceLayoutUsingScripts(layoutTransition.transitionLayout, useScripts);
                waitAnimation(layoutTransition.transitionHoldTime);
            }
            target_layout.transitionInfo = layoutTransition.postTransition;
            target_layout.replaceWithSourceLayoutUsingScripts(endLayout, useScripts);
        } else {
            
            
            target_layout.removeSourceLayoutUsingScripts(layout, useScripts);
        }


    }
}

var removeLayoutByName = function(name, kwargs) {
    var layout = layoutByName(name);
    if (layout) { removeLayout(layout, kwargs); };
}


