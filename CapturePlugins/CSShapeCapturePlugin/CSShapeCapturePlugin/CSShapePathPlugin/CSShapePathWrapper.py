import objc
from Foundation import *
from Quartz import CGPathCreateMutable

CSShapeWrapper = objc.lookUpClass('CSShapeWrapper')


class CSShapePathWrapper(CSShapeWrapper):

    def initWithPlugin_(self, plugin):
        self = super(CSShapePathWrapper, self).init()
        if self is None: return None
        self.plugin = plugin
        return self

    def getcgpath_forLayer_(self, frame, layer):
        new_path = self.plugin.create_cgpath(frame)
        layer.setPath_(new_path)





