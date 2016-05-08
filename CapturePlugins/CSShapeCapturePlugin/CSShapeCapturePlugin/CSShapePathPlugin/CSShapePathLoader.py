import objc
import sys
import os

my_path = NSBundle.bundleForClass_(objc.lookUpClass("CSShapeCapture").class__()).resourcePath() + "/Python"
sys.path.append(my_path)

from pluginbase import PluginBase
from Foundation import *
from CSShapePathWrapper import *

sys.dont_write_bytecode = True


plugin_base = PluginBase(package='shapeplugins')

library_dirs = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSAllDomainsMask - NSSystemDomainMask, YES)
plugin_dirs = map(lambda x: x + "/Application Support/CocoaSplit/Plugins/Paths", library_dirs)
plugin_dirs.append(NSBundle.bundleForClass_(objc.lookUpClass("CSShapeCapture").class__()).resourcePath() + "/Paths")
plugin_source = plugin_base.make_plugin_source(searchpath=plugin_dirs)



class CSShapePathLoader(NSObject):
    
    def init(self):
        self = objc.super(CSShapePathLoader,self).init()
        return self
    
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
            reload(plugin)
            try:
                plugin_name = plugin.name
            except AttributeError:
                plugin_name = "No Name!"
            
            new_wrap = CSShapePathWrapper.alloc().initWithPlugin_(plugin)
            
            ret[m_name] = { 'name':plugin_name, 'module':m_name, 'plugin':new_wrap}
        return ret


