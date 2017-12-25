import objc
from Foundation import NSObject,NSLog,NSApplication
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
    return getCaptureController().activePreviewView().sourceLayout()

def setCITransition(name, inputMap={}, duration=0.25, **kwargs):
    
    new_transition = CIFilter.filterWithName_withInputParameters_(name, inputMap)
    
    my_layout = getCurrentLayout()
    my_layout.setTransitionFilter_(new_transition)
    my_layout.setTransitionDuration_(duration)
    
    if 'full_scene' in kwargs:
        full_scene = kwargs['full_scene']
        my_layout.setTransitionFullScene_(full_scene)


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


def scriptByName(name):
    cap_controller = getCaptureController()
    layout_script = cap_controller.getSequenceForName_(name)
    return layout_script


def runScriptByName(name):
    pass



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


def switchToLayoutByName(name, **kwargs):
    layout = layoutByName(name)
    if layout:
        switchToLayout(layout)

def switchToLayout(layout, **kwargs):
    getCaptureController().switchToLayout_usingLayout_(layout, getCurrentLayout())

def mergeLayout(layout, **kwargs):
    getCaptureController().mergeLayout_usingLayout_(layout, getCurrentLayout())


def mergeLayoutByName(name, **kwargs):
    layout = layoutByName(name)
    if layout:
        mergeLayout(layout)


def removeLayout(layout, **kwargs):
    getCaptureController().removeLayout_usingLayout_(layout, getCurrentLayout())

def removeLayoutByName(name, **kwargs):
    layout = layoutByName(name)
    if layout:
        removeLayout(layout)


def inputByName(name):
    layout = getCurrentLayout()
    real_input = layout.inputForName_(name)
    return real_input
