

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

var setBasicTransition = function(name, direction, duration, kwargs) {
    kwargs = kwargs || {};
    var my_layout = getCurrentLayout();
    my_layout.transitionName = name;
    my_layout.transitionDirection = direction;
    my_layout.transitionDuration = duration;
    if (kwargs['full_scene']) {
        my_layout.transitionFullScene = kwargs['full_scene'];
    }
}

var clearTransition = function() {
    var my_layout = getCurrentLayout();
    my_layout.transitionName = null;
    my_layout.transitionDuration = 0;
    my_layout.transitionFilter = null;
}

var setCITransition = function(name, inputMap, duration, kwargs) {
    inputMap = inputMap || {};
    if (duration === undefined) { duration = 0.25; }
    var new_transition = CIFilter.filterWithNameWithInputParameters(name, inputMap);
    var my_layout = getCurrentLayout();
    my_layout.transitionFilter = new_transition;
    my_layout.transitionDuration = duration;
    
    if (kwargs['full_scene'])
    {
        my_layout.transitionFullScene = kwargs['full_scene'];
    }
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
    
    if (layout) { 
        var target_layout = getCurrentLayout();
        if ((CSAnimationBlock.currentFrame() && target_layout.transitionName || target_layout.transitionFilter) && target_layout.transitionDuration > 0) {
            var dummy_animation = new CSAnimation(null, null, null);
            dummy_animation.duration = target_layout.transitionDuration;
            
            CSAnimationBlock.currentFrame().add_animation(dummy_animation, null, null);
        }
        if (!kwargs['noscripts']) {
        
            var contained_layouts = target_layout.containedLayouts;
            contained_layouts.forEach(function(c_lay) {
                                    
                                      if (c_lay !== layout)
                                      {
                                        var c_scripts = c_lay.transitionScripts;
                                        if (c_scripts['replaced']) {
                                            var rep_script = c_scripts['replaced'];
                                            eval(rep_script);
                                        }
                                      }
                                    });
            //runTriggerScript(target_layout, "beforeReplace");
            

        }
                    
        target_layout.replaceWithSourceLayout(layout);
        if (!kwargs['noscripts']) {
            var layout_transition_scripts = layout.transitionScripts;
            if (layout_transition_scripts['replacing']) {
                var layout_replacing_script = layout_transition_scripts['replacing'];
                eval(layout_replacing_script);
            }
            
            //runTriggerScript(target_layout, "afterReplace");

        }
    }
}

var mergeLayout = function(layout, kwargs) {
    
    kwargs = kwargs || {};
    
    if (layout)
    {
        var target_layout = getCurrentLayout();
        if ((CSAnimationBlock.currentFrame() && target_layout.transitionName || target_layout.transitionFilter) && target_layout.transitionDuration > 0) {
            var dummy_animation = new CSAnimation(null, null, null);
            dummy_animation.duration = target_layout.transitionDuration;
            CSAnimationBlock.currentFrame().add_animation(dummy_animation, null, null);
        }
        
        target_layout.mergeSourceLayout(layout);
        var layout_transition_scripts = layout.transitionScripts;
        if (layout_transition_scripts['merged'] && !kwargs['noscripts'])
        {
            var layout_merged_script = layout_transition_scripts['merged'];
            eval(layout_merged_script);
        }
        
    }
}

var mergeLayoutByName = function(name, kwargs) {
    var layout = layoutByName(name);
    if (layout) { mergeLayout(layout, kwargs); };
}

var removeLayout = function(layout, kwargs) {
    kwargs = kwargs || {};
    
    if (layout)
    {
        var target_layout = getCurrentLayout();
        if ((CSAnimationBlock.currentFrame() && target_layout.transitionName || target_layout.transitionFilter) && target_layout.transitionDuration > 0) {
            var dummy_animation = new CSAnimation(null, null, null);
            dummy_animation.duration = target_layout.transitionDuration;
            CSAnimationBlock.currentFrame().add_animation(dummy_animation, null, null);
        }
        var layout_transition_scripts = layout.transitionScripts;
        if (layout_transition_scripts['removed'] && !kwargs['noscripts'])
        {
            var layout_removed_script = layout_transition_scripts['removed'];
            eval(layout_removed_script);
        }
        
        if (!kwargs['noscripts'])
        {
            runTriggerScript(target_layout, "beforeRemove");
        }
        target_layout.removeSourceLayout(layout);

    }
}

var removeLayoutByName = function(name, kwargs) {
    var layout = layoutByName(name);
    if (layout) { removeLayout(layout, kwargs); };
}


