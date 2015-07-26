import objc
import sys
import os
from Foundation import *
from pluginbase import PluginBase

sys.dont_write_bytecode = True


plugin_base = PluginBase(package='shapeplugins')

library_dirs = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSAllDomainsMask - NSSystemDomainMask, YES)
plugin_dirs = map(lambda x: x + "/Application Support/CocoaSplit/Plugins/Paths", library_dirs)
plugin_dirs.append(NSBundle.bundleForClass_(objc.lookUpClass("CSShapeCapture").class__()).builtInPlugInsPath() + "/Paths")
plugin_source = plugin_base.make_plugin_source(searchpath=plugin_dirs)


class CSShapePathLoader(NSObject):
    
    def init(self):
        self = super(CSShapePathLoader, self).init()
        return self
    
    @objc.signature('v@:@@')
    def setPathForLayer_withPlugin_(self, layer, m_name):
        if layer and m_name:
            path_plugin = plugin_source.load_plugin(m_name)
            path_ref = path_plugin.create_cgpath(layer.frame())
            layer.setPath_(path_ref)
    #CGPathRelease(path_ref)
            
    
    
    @objc.signature('@@:@')
    def pathLoaderPath_(self, pluginName):
        plugin_module = plugin_source.load_plugin(pluginName)
        plugin_file = plugin_module.__file__
        real_path = os.path.realpath(plugin_file)
        return real_path
    
    
    @objc.signature('@@:')
    def allPaths(self):
        
        plugins = plugin_source.list_plugins()
        ret = {}
        for m_name in plugins:
            plugin = plugin_source.load_plugin(m_name)
            #reload(plugin)
            try:
                plugin_name = plugin.name
            except AttributeError:
                plugin_name = "No Name!"
            
            
            ret[m_name] = { 'name':plugin_name, 'module':m_name}
        return ret


