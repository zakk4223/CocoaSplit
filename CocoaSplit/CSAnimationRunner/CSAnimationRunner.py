"""
Animation runner base
"""
import objc
import CSAnimationInput
from types import ModuleType
from Foundation import *
#from CoreGraphics import *
from Quartz import CACurrentMediaTime,CATransaction,CGPathRef,CGPathAddLines,CGPathCloseSubpath,CGPathRelease,CGPathCreateMutable
from pluginbase import PluginBase
import math
import CSAnimationBlock
from CSAnimation import *
from Foundation import NSObject,NSLog,NSApplication
import sys
import os
import re
sys.dont_write_bytecode = True


plugin_base = PluginBase(package='animationplugins')

library_dirs = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSAllDomainsMask - NSSystemDomainMask, YES)
plugin_dirs = map(lambda x: x + "/Application Support/CocoaSplit/Plugins/Animations", library_dirs)
plugin_dirs.append(NSBundle.mainBundle().resourcePath() + "/Animations")
plugin_source = plugin_base.make_plugin_source(searchpath=plugin_dirs)




def dummyCompletion():
    return None


def wait(duration=0):
    CSAnimationBlock.wait(duration)



class CSAnimationRunnerObj(NSObject):
    
    def init(self):
        self = super(CSAnimationRunnerObj,self).init()
        return self


    @objc.signature('@@:@')
    def animationPath_(self, pluginName):
        plugin_module = plugin_source.load_plugin(pluginName)
        plugin_file = plugin_module.__file__
        real_path = os.path.realpath(plugin_file)
        return real_path
    
    
    @objc.signature('@@:')
    def allAnimations(self):
        plugins = plugin_source.list_plugins()
        ret = {}
        
        for m_name in plugins:
            plugin = plugin_source.load_plugin(m_name)
            reload(plugin)


            try:
                plugin_name = plugin.animation_name
            except AttributeError:
                continue
            
            try:
                plugin_inputs = plugin.animation_inputs
            except AttributeError:
                plugin_inputs = []
            
            try:
                plugin_parameters = plugin.animation_params
            except AttributeError:
                plugin_parameters = []
            
            plugin_parameters.append('duration')
            
            try:
                plugin_description = plugin.animation_description
            except AttributeError:
                plugin_description = "No description provided"
            
            ret[m_name] = {'params': plugin_parameters, 'inputs': plugin_inputs, 'name':plugin_name, 'module':m_name, 'description':plugin_description}
        return ret


    def beginAnimation(self, duration=0.25):
        CSAnimationBlock.beginAnimation(duration)
        CSAnimationBlock.current_frame().layout = self.layout
    

    @objc.signature('v@:@@')
    def runAnimation_forLayout_(self,animation_string, layout):
    
        animation = ModuleType('cs_fromstring_animation', '')
        exec("from cocoasplit import *", animation.__dict__)
        exec(animation_string, animation.__dict__)
        CSAnimationBlock.beginAnimation()
        CSAnimationBlock.current_frame().layout = layout
        
        animation.wait = CSAnimationBlock.wait
        animation.waitAnimation = CSAnimationBlock.waitAnimation
        animation.animationDuration = CSAnimationBlock.animationDuration
        animation.setCompletionBlock = CSAnimationBlock.setCompletionBlock
        animation.commitAnimation = CSAnimationBlock.commitAnimation
        
        self.baseLayer = layout.rootLayer()
        self.layout = layout
        
        
        try:
            CSAnimationBlock.setCompletionBlock(dummyCompletion)
        
            animation.run_script()
        except:
            CSAnimationBlock.commitAnimation()
            raise
        else:
            CSAnimationBlock.commitAnimation()

    
    
