import objc
from Foundation import *
from CoreGraphics import *
from Quartz import CACurrentMediaTime
from pluginbase import PluginBase
import math
import CSAnimationBlock
from CSAnimation import *

plugin_base = PluginBase(package='animationplugins')

library_dirs = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSAllDomainsMask - NSSystemDomainMask, YES)
plugin_dirs = map(lambda x: x + "/Application Support/CocoaSplit/Plugins/Animations", library_dirs)
plugin_source = plugin_base.make_plugin_source(searchpath=plugin_dirs)


class CSAnimationInput:
    def __init__(self, cs_input):
        self.input = cs_input
        self.layer = cs_input.layer()
        self.animationLayer = cs_input.animationLayer()
        self.frames = []
        self.current_frame = None
    

    def minY(self):
        return NSMinY(self.animationLayer.frame())
    
    def maxY(self):
        return NSMaxY(self.animationLayer.frame())

    def minX(self):
        return NSMinX(self.animationLayer.frame())

    def maxX(self):
        return NSMaxX(self.animationLayer.frame())

    def midY(self):
        return NSMidY(self.animationLayer.frame())

    def midX(self):
        return NSMidX(self.animationLayer.frame())


    def basic_animation(self, forKey, withDuration):
        cab = CABasicAnimation.animationWithKeyPath_(forKey)
        cab.setDuration_(withDuration)
        return cab
    

    def simple_animation(self, forKey, toValue, withDuration, **kwargs):
        banim = self.basic_animation(forKey, withDuration)
        for_layer = self.layer
        if 'use_layer' in kwargs:
            for_layer = kwargs['use_layer']
        csanim = CSAnimation(for_layer, forKey, banim, **kwargs)
        
        if not 'autoreverse' in kwargs:
            self.animationLayer.setValue_forKeyPath_(toValue, forKey)
        
        banim.setToValue_(toValue)
        return self.add_animation(csanim, for_layer, forKey)
    
    

    def add_animation(self, animation, target, keyPath):
        animation.cs_input = self
        CSAnimationBlock.current_frame.add_animation(animation, target, keyPath)
        return animation
    

    def adjust_coordinates(self, x, y):
        m_width = self.animationLayer.frame().size.width
        m_height = self.animationLayer.frame().size.height
        c_x = self.animationLayer.frame().origin.x
        c_y = self.animationLayer.frame().origin.y
        return NSPoint(x-c_x, y-c_y)
    
    def waitAnimation(self, duration=0, **kwargs):
        return CSAnimationBlock.current_frame.waitAnimation(duration, self, **kwargs)
    
    def wait(self, duration=0):
        return CSAnimationBlock.current_frame.wait(duration, self)
    
    def scaleLayer(self, scaleVal, duration, **kwargs):
        return self.simple_animation('transform.scale', scaleVal, duration, **kwargs)
    

    def scaleSize(self, scaleVal, duration):
        curr_width = self.animationLayer.bounds().size.width
        curr_height = self.animationLayer.bounds().size.height
        return self.size(curr_width * scaleVal, curr_height*scaleVal, duration)
    
    def width(self, width, duration, **kwargs):
        kwargs['use_layer'] = self.layer.sourceLayer()
        kwargs['extra_model'] = self.layer
        return self.simple_animation('bounds.size.width', width, duration, **kwargs)
    
    def height(self, height, duration, **kwargs):
        kwargs['use_layer'] = self.layer.sourceLayer()
        kwargs['extra_model'] = self.layer
        return self.simple_animation('bounds.size.height', height, duration, **kwargs)

    def size(self, width, height, duration, **kwargs):
        current_bounds = self.animationLayer.bounds()
        oldwidth = current_bounds.size.width
        current_bounds.size.width = width
        current_bounds.size.height = height
        rectval = NSValue.valueWithRect_(current_bounds)
        kwargs['use_layer'] = self.layer.sourceLayer()
        kwargs['extra_model'] = self.layer
        return self.simple_animation('bounds', rectval, duration, **kwargs)
    
    def translateY(self, y, duration, **kwargs):
        cval = self.animationLayer.valueForKeyPath_('transform.translation.y')
        return self.simple_animation('transform.translation.y', y+cval, duration, **kwargs)
 
    def translateX(self, x, duration, **kwargs):
        cval = self.animationLayer.valueForKeyPath_('transform.translation.x')
        return self.simple_animation('transform.translation.x', x+cval, duration, **kwargs)
    
    def translate(self, x,y,duration, **kwargs):
        cpos = self.animationLayer.valueForKeyPath_('transform.translation')
        csize = cpos.sizeValue()
        nsize = NSSize(csize.width+x, csize.height+y)
        return self.simple_animation('transform.translation', NSValue.valueWithSize_(nsize), duration, **kwargs)
    
    
    def moveX(self, move_x, duration, **kwargs):
        return self.simple_animation('position.x', self.animationLayer.position().x+move_x, duration, **kwargs)
    
    def moveY(self, move_y, duration):
        return self.simple_animation('position.y', self.animationLayer.position().y+move_y, duration, **kwargs)


    def move(self, move_x, move_y, duration, **kwargs):
        curr_x = self.animationLayer.position().x
        curr_y = self.animationLayer.position().y
        return self.moveTo(curr_x+move_x, curr_y+move_y, duration, **kwargs)
    
    def moveCenter(self, duration, **kwargs):
        rootLayer = self.layer.superlayer()
        rootWidth = rootLayer.bounds().size.width
        rootHeight = rootLayer.bounds().size.height
        #we want to move our center to root center. do anchor point correction..
        new_x = rootWidth * 0.5 - self.animationLayer.frame().size.width * 0.5
        new_y = rootHeight * 0.5 - self.animationLayer.frame().size.height * 0.5
        return self.moveTo(new_x, new_y, duration, **kwargs)
    
    
    def moveYTo(self, move_y, duration, **kwargs):
        new_coord = self.adjust_coordinates(0,move_y)
        c_pos = self.animationLayer.position()
        c_pos.y += new_coord.y

        return self.simple_animation('position.y', c_pos.y, duration, **kwargs)
    
    def moveXTo(self, move_x, duration, **kwargs):
        new_coord = self.adjust_coordinates(move_x, 0)
        c_pos = self.animationLayer.position()
        c_pos.x += new_coord.x
        return self.simple_animation('position.x', c_pos.x, duration, **kwargs)

    def moveTo(self, move_x, move_y, duration, **kwargs):
        new_coords = self.adjust_coordinates(move_x, move_y)
        c_pos = self.animationLayer.position()
        c_pos.x += new_coords.x
        c_pos.y += new_coords.y
        return self.simple_animation('position', NSValue.valueWithPoint_(c_pos), duration, **kwargs)
    
    def opacity(self, opacity, duration, **kwargs):
        return self.simple_animation('opacity', opacity, duration, **kwargs)


    def rotateX(self, angle, duration, **kwargs):
        toVal = math.radians(angle)
        fromVal = self.animationLayer.valueForKeyPath_('transform.rotation.x')
        retval = self.simple_animation('transform.rotation.x', fromVal+toVal, duration, **kwargs)
        return retval

    def rotateY(self, angle, duration, **kwargs):
        toVal = math.radians(angle)
        fromVal = self.animationLayer.valueForKeyPath_('transform.rotation.y')
        retval = self.simple_animation('transform.rotation.y', fromVal+toVal, duration, **kwargs)
        return retval
    
    def rotateXTo(self, angle, duration, **kwargs):
        toVal = math.radians(angle)
        retval = self.simple_animation('transform.rotation.x', toVal, duration, **kwargs)
        return retval
    
    def rotateYTo(self, angle, duration, **kwargs):
        toVal = math.radians(angle)
        retval = self.simple_animation('transform.rotation.y', toVal, duration, **kwargs)
        return retval


    def rotate(self, angle, duration, **kwargs):
        toVal = math.radians(angle)
        fromVal = self.animationLayer.valueForKeyPath_('transform.rotation.z')
        retval = self.simple_animation('transform.rotation.z', fromVal+toVal, duration, **kwargs)
        return retval
    
    def rotateTo(self, angle, duration, **kwargs):
        toVal = math.radians(angle)
        return self.simple_animation('transform.rotation.z', toVal, duration, **kwargs)


    def borderwidth(self, width, duration, **kwargs):
        return self.simple_animation('borderWidth', width, duration, **kwargs)

    def cornerradius(self, radius, duration, **kwargs):
        return self.simple_animation('cornerRadius', radius, duration, **kwargs)

    def __hidden_complete__(self, animation, yesno):
        animation.set_model_value()
        self.layer.setHidden_(yesno)
    
    def hidden(self, yesno, duration, **kwargs):
        ret = self.simple_animation('hidden', yesno, duration, **kwargs)
        ret.internal_completion_handler = lambda a: self.__hidden_complete__(a, yesno)
        return ret

    def hide(self, duration, **kwargs):
        return self.hidden(True, duration, **kwargs)
    
    def show(self, duration, **kwargs):
        return self.hidden(False, duration, **kwargs)
    
    def toggle(self, duration, **kwargs):
        cval = self.animationLayer.hidden()        
        return self.hidden(not cval, duration, **kwargs)
    
    
    def zPosition(self, zpos, duration, **kwargs):
        return self.simple_animation('zPosition', zpos, duration, **kwargs)

    def moveRelativeTo(self, toInput, duration, **kwargs):
        new_coords = self.animationLayer.frame().origin
        my_size = self.animationLayer.bounds().size
        if 'left' in kwargs:
            l_space = kwargs['left']
            new_coords.x = toInput.minX()-my_size.width-l_space
        elif 'right' in kwargs:
            r_space = kwargs['right']
            new_coords.x = toInput.maxX()+r_space

        if 'top' in kwargs:
            t_space = kwargs['top']
            new_coords.y = toInput.maxY()+t_space
            new_coords.x = toInput.minX()
        elif 'bottom' in kwargs:
            b_space = kwargs['bottom']
            new_coords.y = toInput.minY()-my_size.height-b_space
        
        if 'offsetX' in kwargs:
            ex_space = kwargs['offsetX']
            new_coords.x = toInput.minX()-ex_space
        
        if 'offsetY' in kwargs:
            ex_space = kwargs['offsetY']
            new_coords.y = toInput.minY()-ex_space
    
        return self.moveTo(new_coords.x, new_coords.y, duration, **kwargs)





def wait(duration=0):
    CSAnimationBlock.wait(duration, None)


class CSAnimationRunnerObj(NSObject):
    
    def init(self):
        self = super(CSAnimationRunnerObj, self).init()
        return self


    @objc.signature('@@:')
    def allAnimations(self):
        plugins = plugin_source.list_plugins()
        ret = {}
        for m_name in plugins:
            plugin = plugin_source.load_plugin(m_name)
            reload(plugin)

            plugin_name = plugin.animation_name
            if not plugin_name:
                continue
            plugin_inputs = plugin.animation_inputs
            ret[m_name] = {'inputs': plugin_inputs, 'name':plugin_name, 'module':m_name}
        return ret


    @objc.signature('v@:@@@f')
    def runAnimation_forInput_withSuperlayer_withDuration_(self, pluginName,input_or_dict,superlayer, duration):
        input_arg = input_or_dict
        if isinstance(input_or_dict, NSDictionary) or isinstance(input_or_dict, NSMutableDictionary):
            input_arg = {}
            for k in input_or_dict:
                if input_or_dict[k]:
                    input_arg[k] = CSAnimationInput(input_or_dict[k])
                else:
                    input_arg[k] = None



        animation = plugin_source.load_plugin(pluginName)
        reload(animation)
        CSAnimationBlock.superLayer = superlayer
        CSAnimationBlock.beginAnimation()
        animation.wait = CSAnimationBlock.wait
        animation.waitAnimation = CSAnimationBlock.waitAnimation
        animation.do_animation(input_arg, duration)
        CSAnimationBlock.commitAnimation()





