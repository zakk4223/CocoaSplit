from Foundation import NSObject,NSLog,NSApplication
import CSAnimationBlock
from CSAnimationInput import *
from CSAnimation import *
import re



objc.registerMetaDataForSelector('CSCaptureBase', 'updateLayersWithFramedataBlock:', {'arguments': {2: {'type': '@?', 'callable': {'arguments': {'0':'^v', '1':'@'}}}}})

CSCaptureBase = objc.lookUpClass('CSCaptureBase')
CSIOSurfaceLayer = objc.lookUpClass('CSIOSurfaceLayer')
CSAbstractCaptureDevice = objc.lookUpClass('CSAbstractCaptureDevice')
LayoutRenderer = objc.lookUpClass('LayoutRenderer')
CSCaptureSourceProtocol = objc.protocolNamed('CSCaptureSourceProtocol')


def getCaptureController():
    my_app = NSApplication.sharedApplication()
    app_delegate = my_app.delegate()
    return app_delegate.captureController()

def getCurrentLayout():
    current_frame = CSAnimationBlock.current_frame()
    if current_frame:
        return current_frame.layout
    return getCaptureController().activePreviewView().sourceLayout()
    
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


def setDefaultAnimationArguments(**kwargs):
    a_module = CSAnimationBlock.current_frame().animation_module
    a_module.__cs_default_kwargs = kwargs

def clearDefaultAnimationArguments():
    a_module = CSAnimationBlock.current_frame().animation_module
    a_module.__cs_default_kwargs = {}

def scriptByName(name):
    cap_controller = getCaptureController()
    layout_script = cap_controller.getSequenceForName_(name)
    return layout_script


def runScriptByName(name):
    my_func = getattr(CSAnimationBlock.current_frame().animation_module, "run_{0}_script".format(name), None)
    if my_func:
        return my_func()
    
    layout_script = scriptByName(name)
    if layout_script:
        script_code = layout_script.animationCode()
        real_script_code = ""
        if script_code:
            re_ra = re.compile('def\s+run_script')
            if re.search(re_ra, script_code):
                real_script_code = re.sub(re_ra, script_code)
            else:
                real_script_code = "def run_{0}_script():\n".format(name)
                sc_lines = script_code.splitlines(True)
                for s_line in sc_lines:
                    real_script_code += "\t{0}".format(s_line)
            
            
            exec(real_script_code, CSAnimationBlock.current_frame().animation_module.__dict__)
            my_func = getattr(CSAnimationBlock.current_frame().animation_module, "run_{0}_script".format(name))
            my_func()




def audioInputByRegex(regex):
    cap_controller = getCaptureController()
    all_audio_inputs = cap_controller.multiAudioEngine().audioInputs()
    
    re_c = re.compile(regex)
    
    for a_inp in all_audio_inputs:
        a_name = a_inp.name()
        if re.search(re_c, a_name):
            return a_inp

    return None


def setAudioInputVolume(name_regex, volume, duration):
    a_inp = audioInputByRegex(name_regex)
    if a_inp:
        a_inp.setVolumeAnimated_withDuration_(volume, duration)



def layoutByName(name):
    cap_controller = getCaptureController()
    layout = cap_controller.findLayoutWithName_(name)
    return layout

def containsLayout(name):
    target_layout = getCurrentLayout()
    return target_layout.containsLayoutNamed_(name)

def switchToLayout(name):
    layout = layoutByName(name)
    if layout:
        target_layout = getCurrentLayout()
        if (CSAnimationBlock.current_frame() and target_layout.transitionName() or target_layout.transitionFilter()) and target_layout.transitionDuration() > 0:
            dummy_animation = CSAnimation(None, None, None)
            dummy_animation.duration = target_layout.transitionDuration()
            CSAnimationBlock.current_frame().add_animation(dummy_animation, None, None)
        target_layout.replaceWithSourceLayout_(layout)



def mergeLayout(name):
    layout = layoutByName(name)
    if layout:
        target_layout = getCurrentLayout()
        if (CSAnimationBlock.current_frame() and target_layout.transitionName() or target_layout.transitionFilter()) and target_layout.transitionDuration() > 0:
            dummy_animation = CSAnimation(None, None, None)
            dummy_animation.duration = target_layout.transitionDuration()
            CSAnimationBlock.current_frame().add_animation(dummy_animation, None, None)
    target_layout.mergeSourceLayout_(layout)



def removeLayout(name):
    layout = layoutByName(name)
    if layout:
        target_layout = getCurrentLayout()
        if (CSAnimationBlock.current_frame() and target_layout.transitionName() or target_layout.transitionFilter()) and target_layout.transitionDuration() > 0:
            dummy_animation = CSAnimation(None, None, None)
            dummy_animation.duration = target_layout.transitionDuration()
            CSAnimationBlock.current_frame().add_animation(dummy_animation, None, None)
    target_layout.removeSourceLayout_(layout)



def inputByName(name):
    
    layout = getCurrentLayout()
    real_input = layout.inputForName_(name)
    if real_input:
        return CSAnimationInput(real_input)
    return None
