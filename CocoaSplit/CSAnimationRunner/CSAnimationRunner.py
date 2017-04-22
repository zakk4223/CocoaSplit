"""
Animation runner base
"""
import objc
import CSAnimationInput
from types import ModuleType
#from Foundation import *
#from CoreGraphics import *
from Quartz import CACurrentMediaTime,CATransaction,CGPathRef,CGPathAddLines,CGPathCloseSubpath,CGPathRelease,CGPathCreateMutable
from pluginbase import PluginBase
import math
import CSAnimationBlock
from CSAnimation import *
#from Foundation import NSObject,NSLog,NSApplication
import sys
import traceback
import os
import re
sys.dont_write_bytecode = True


script_base = PluginBase(package='scriptplugins')
plugin_base = PluginBase(package='cocoasplitplugins')

library_dirs = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSAllDomainsMask - NSSystemDomainMask, YES)
script_dirs = map(lambda x: x + "/Application Support/CocoaSplit/Plugins/Scripts", library_dirs)
script_dirs.append(NSBundle.mainBundle().resourcePath() + "/Scripts")
script_source = script_base.make_plugin_source(searchpath=script_dirs)

plugin_dirs = map(lambda x: x + "/Application Support/CocoaSplit/Plugins/Python", library_dirs)
plugin_dirs.append(NSBundle.mainBundle().builtInPlugInsPath() + "/Python")
plugin_source = plugin_base.make_plugin_source(searchpath=plugin_dirs)





def dummyCompletion():
    pass

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
    def allPlugins(self):
        ret = []
        plugin_names = plugin_source.list_plugins()

        for plugin_n in plugin_names:
            p_plugin = None
            try:
                p_plugin = plugin_source.load_plugin(plugin_n)
            except Exception, e:
                NSLog("Error loading plugin %@: %@", plugin_n, traceback.format_exc())
            
            if p_plugin:
                plugin_classes = p_plugin.plugin_classes
                ret.extend(plugin_classes)
        
        return ret
    
    @objc.signature('@@:')
    def allAnimations(self):
        plugins = script_source.list_plugins()
        ret = {}
        
        for m_name in plugins:
            plugin = script_source.load_plugin(m_name)
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
    

    @objc.signature('@@:@@@')
    def runAnimation_forLayout_withExtraDictionary_(self,animation_string, layout, extraDictionary):
    
        NSLog("EXTRA DICT %@", extraDictionary);
        
        animation = ModuleType('cs_fromstring_animation', '')
        animation.extraData = extraDictionary

        exec("from cocoasplit import *", animation.__dict__)
        exec("all_animations = {}", animation.__dict__)
        exec("__cs_default_kwargs = {}", animation.__dict__)
        exec(animation_string, animation.__dict__)
        #sys.modules['cs_fromstring_animation'] = animation
        CSAnimationBlock.beginAnimation()
        CSAnimationBlock.current_frame().layout = layout
        CSAnimationBlock.current_frame().animation_module = animation
        
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
        return animation.all_animations



    
    
