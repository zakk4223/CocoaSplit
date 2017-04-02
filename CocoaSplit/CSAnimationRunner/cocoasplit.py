import CSAnimationBlock
import CSAnimationInput


def getCaptureController():
    my_app = NSApplication.sharedApplication()
    app_delegate = my_app.delegate()
    return app_delegate.captureController()

def getCurrentLayout():
    current_frame = CSAnimationBlock.current_frame()
    if current_frame:
        return current_frame.layout
    return getCaptureController().selectedLayout()
    
def setBasicTransition(name, direction=None, duration=0.25, **kwargs):
    my_layout = getCurrentLayout()
    my_layout.setTransitionName_(name)
    my_layout.setTransitionDirection_(direction)
    my_layout.setTransitionDuration_(duration)
    
    if 'full_scene' in kwargs:
        full_scene = kwargs['full_scene']
        my_layout.setTransitionFullScene_(full_scene)


def clearTransition():
    my_layout = getCurrentLayout()
    my_layout.setTransitionName_(None)
    my_layout.setTransitionDuration_(0)
    my_layout.setTransitionFilter_(None)


def audioInputByRegex(regex):
    cap_controller = getCaptureController()
    all_audio_inputs = cap_controller.multiAudioEngine().audioInputs()
    
    re_c = re.compile(regex)
    
    for a_inp in all_audio_inputs:
        a_name = a_inp.name()
        NSLog("A NAME %@", a_name)
        if re.search(re_c, a_name):
            return a_inp

    return None


def setAudioInputVolume(name_regex, volume):
    a_inp = audioInputByRegex(name_regex)
    if a_inp:
        a_inp.setVolume_(volume)



def layoutByName(name):
    cap_controller = getCaptureController()
    layout = cap_controller.findLayoutWithName_(name)
    return layout

def switchToLayout(name):
    layout = layoutByName(name)
    if layout:
        target_layout = getCurrentLayout()
        target_layout.replaceWithSourceLayout_(layout)
        if (CSAnimationBlock.current_frame() and target_layout.transitionName() or target_layout.transitionFilter()) and target_layout.transitionDuration() > 0:
            dummy_animation = CSAnimation(None, None, None)
            dummy_animation.duration = target_layout.transitionDuration()
            CSAnimationBlock.current_frame().add_animation(dummy_animation, None, None)


def mergeLayout(name):
    layout = layoutByName(name)
    if layout:
        target_layout = getCurrentLayout()
        target_layout.mergeSourceLayout_(layout)
        if (CSAnimationBlock.current_frame() and target_layout.transitionName() or target_layout.transitionFilter()) and target_layout.transitionDuration() > 0:
            dummy_animation = CSAnimation(None, None, None)
            dummy_animation.duration = target_layout.transitionDuration()
            CSAnimationBlock.current_frame().add_animation(dummy_animation, None, None)


def removeLayout(name):
    layout = layoutByName(name)
    if layout:
        target_layout = getCurrentLayout()
        target_layout.removeSourceLayout_(layout)
        if (CSAnimationBlock.current_frame() and target_layout.transitionName() or target_layout.transitionFilter()) and target_layout.transitionDuration() > 0:
            dummy_animation = CSAnimation(None, None, None)
            dummy_animation.duration = target_layout.transitionDuration()
            CSAnimationBlock.current_frame().add_animation(dummy_animation, None, None)


def inputByName(name):
    
    layout = getCurrentLayout()
    real_input = layout.inputForName_(name)
    if real_input:
        return CSAnimationInput(real_input)
    return None
