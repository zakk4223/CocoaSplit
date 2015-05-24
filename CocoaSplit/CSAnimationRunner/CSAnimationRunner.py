"""
Animation runner base
"""
import objc
from Foundation import *
#from CoreGraphics import *
from Quartz import CACurrentMediaTime,CATransaction,CGPathRef,CGPathAddLines,CGPathCloseSubpath,CGPathRelease,CGPathCreateMutable
from pluginbase import PluginBase
import math
import CSAnimationBlock
from CSAnimation import *
import sys
sys.dont_write_bytecode = True


plugin_base = PluginBase(package='animationplugins')

library_dirs = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSAllDomainsMask - NSSystemDomainMask, YES)
plugin_dirs = map(lambda x: x + "/Application Support/CocoaSplit/Plugins/Animations", library_dirs)
plugin_dirs.append(NSBundle.mainBundle().builtInPlugInsPath() + "/Animations")
plugin_source = plugin_base.make_plugin_source(searchpath=plugin_dirs)




class CSAnimationInput(object):
    def __init__(self, cs_input):
        self.__input__ = cs_input
        self.__layer__ = cs_input.layer()
        self.__animationLayer__ = cs_input.animationLayer()
        self.frames = []
        self.current_frame = None
    
    @property
    def input(self):
        """
        The source being animated. This is set via the UI and animation_input keys to the input dict.
        """
        return self.__input__
    
    @property
    def layer(self):
        """
        The InputSource's CALayer.
        """
        return self.__layer__
    
    @property
    def animationLayer(self):
        """
        A "shadow" copy of the layer being animated. This layer is updated as animations are applied to the layer.
        """
        return self.__animationLayer__
    
    
    @property
    def width(self):
        """
        Current width of the input
        """
        return self.animationLayer.bounds().size.width
    
    @property
    def height(self):
        """
        Current height of the input
        """
        return self.animationLayer.bounds().size.height
    
    
    @property
    def minY(self):
        """
        Minimum Y value, otherwise known as the Y coordinate of the input's origin
        """
        return NSMinY(self.animationLayer.frame())
    
    @property
    def maxY(self):
        """
        Maximum Y value of the input's frame. origin.y+height
        """
        return NSMaxY(self.animationLayer.frame())

    @property
    def minX(self):
        """
        Minimum X value, otherwise known as the X coordinate of the input's origin
        """
        return NSMinX(self.animationLayer.frame())
    
    @property
    def maxX(self):
        """
        Maximum X value of the input's frame. origin.x+width
        """
        return NSMaxX(self.animationLayer.frame())

    @property
    def midY(self):
        """
        Midpoint of the input's frame on the Y axis. origin.y+(height/2)
        """
        return NSMidY(self.animationLayer.frame())

    @property
    def midX(self):
        """
        Midpoint of the input's frame on the X axis. origin.x+(width/2)
        """
        return NSMidX(self.animationLayer.frame())


    def basic_animation(self, forKey, withDuration):
        cab = CABasicAnimation.animationWithKeyPath_(forKey)
        if withDuration != None:
            cab.setDuration_(withDuration)
        else:
            cab.setDuration_(CSAnimationBlock.current_frame.duration)
        return cab
    

    def keyframe_animation(self, forKey, withDuration):
    
        kanim = CAKeyframeAnimation.animationWithKeyPath_(forKey)
        if withDuration != None:
            kanim.setDuration_(withDuration)
        else:
            kanim.setDuration_(CSAnimationBlock.current_frame.duration)
        kanim.setCalculationMode_('paced')
        kanim.setRotationMode_('autoReverse')
        
        return kanim
        
    
    def simple_animation(self, forKey, toValue, withDuration=None, **kwargs):
        
        real_end_value = toValue
        
        if type(toValue) in (list,tuple,CGPathRef):
            banim = self.keyframe_animation(forKey, withDuration)
            real_end_value = toValue[-1]
            banim.setValues_(toValue)
        else:
            banim = self.basic_animation(forKey, withDuration)
            if 'use_fromVal' in kwargs:
                banim.setFromValue_(kwargs['use_fromVal'])
            banim.setToValue_(toValue)

        
        
        for_layer = self.layer
        
        if 'source_only' in kwargs and kwargs['source_only']:
            for_layer = self.layer.sourceLayer()
        if 'use_layer' in kwargs:
            for_layer = kwargs['use_layer']
        csanim = CSAnimation(for_layer, forKey, banim, **kwargs)
        
        if not 'autoreverse' in kwargs:
            self.animationLayer.setValue_forKeyPath_(real_end_value, forKey)
            if 'extra_keypath' in kwargs:
                self.animationLayer.setValue_forKeyPath_(real_end_value, kwargs['extra_keypath'])
        
        
        csanim.toValue = real_end_value

        return self.add_animation(csanim, for_layer, forKey)
    
    
    def make_animation_values(self,initial_value, anim_value, valueMaker):
        

        ret_val = None
        
        if type(anim_value) in (list,tuple):
            
            val_arr = []
            if initial_value is not None:
                val_arr.append(initial_value)
            
            for val in anim_value:
                n_val = valueMaker(val)
                val_arr.append(n_val)
            ret_val = val_arr
        else:
            ret_val = valueMaker(anim_value)

        return ret_val


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

    def real_coordinate_from_fract(self, x,y):
        ret_x = x
        ret_y = y
        if x > 0.0 and x <= 1.0:
            slayer = self.layer.superlayer()
            ret_x = slayer.bounds().origin.x + (slayer.bounds().size.width * x)
        if y > 0.0 and y <= 1.0:
            slayer = self.layer.superlayer()
            ret_y = slayer.bounds().origin.y + (slayer.bounds().size.height * y)
        return NSPoint(ret_x, ret_y)


    def waitAnimation(self, duration=0, **kwargs):
        """
        Wait for all in-progress animations on this input to complete before adding any more. 
        This ONLY changes the timing for the input this wait is applied to. Example:
        input1.moveTo(0,0,2.5)
        input2.moveTo(100,100.5.5)
        input1.waitAnimation()
        input2.rotate(360, 5.5)
        input1.moveCenter(3.5)
        
        input1 will start to move towards the bottom left corner and simultaneously input2 will begin its rotation AND begin moving to 100,100.
        After input1 finishes moving to the corner it will then start moving towards the center.
        Notice that the timing of input2's animations are not modified by the waitAnimation() on input1.
        
        Like the global waitAnimation() you can specify a keyword argument of 'label' to wait on a specific animation.
        """
        return CSAnimationBlock.current_frame.waitAnimation(duration, self, **kwargs)
    
    def wait(self, duration=0):
        """
        Wait duration seconds before starting any new animations on this input. As described previously in waitAnimation() this 
        only modifies the timing of animations on THIS input.
        """
        return CSAnimationBlock.current_frame.wait(duration, self)
    
    def scaleLayer(self, scaleVal, duration=None, **kwargs):
        """
        Apply a uniform scale transform to the layer. Grows or shrinks the input by the given scale. 
        
        Two important points about scale animations:
        1) They ARE NOT PERMANENT. If you use an animation to apply a 0.5 scale to an input, then go live or save the layout, the scale does not carry over. If you want to make the change permanent use scaleSize()
        2) The scale is relative to the original size of the input. So applying one 2x scale and then another 2x scale only results in the scale changing once.
        """
        
        cval = self.animationLayer.valueForKeyPath_('transform.scale')
        
        anim_vals = self.make_animation_values(cval, scaleVal, lambda x: x)
        return self.simple_animation('transform.scale', anim_vals, duration, **kwargs)
    

    def scaleSize(self, scaleVal, duration=None, **kwargs):
        """
        Changes the input bounds by scaleVal. This change IS permanent; if you save and restore the layout after performing a scaleSize() the input will retain the size it was set to by the animation. Note that the scaleVal is relative to the CURRENT size of the input, so applying a 2x scaleSize followed by another 2x scaleSize will result in something 4x as big as the original bounds.
        """
        curr_width = self.animationLayer.bounds().size.width
        curr_height = self.animationLayer.bounds().size.height
        return self.size(curr_width * scaleVal, curr_height*scaleVal, duration, **kwargs)
    
    def sizeWidth(self, width, duration=None, **kwargs):
        """
        Set the width of the input. This change saves/is permanent. It is applied to the underlying layer's bounds.
        """

        move_frames = []
        original_width = self.width
        
        def vmk(val):
            
            mvval = None
            if 'anchorLeft' in kwargs and kwargs['anchorLeft']:
                mvval = (val - original_width)/2
            elif 'anchorRight' in kwargs and kwargs['anchorRight']:
                mvval = (original_width - val)/2
            if mvval is not None:
                move_frames.append(mvval)
            return val
        
        anim_vals = self.make_animation_values(self.width, width, vmk)
        kwargs['use_fromVal'] = self.width
        kwargs['extra_keypath'] = 'bounds.size.width'
        ret = self.simple_animation('fakeWidth', anim_vals, duration, **kwargs)
        kwargs.pop('use_fromVal', None)
        kwargs.pop('extra_keypath', None)

        self.moveX(move_frames, duration, **kwargs)
        return ret
    
    def sizeHeight(self, height, duration=None, **kwargs):
        """
        Set the height of the input. This change saves/is permanent. It is applied to the underlying layer's bounds.
        """
        move_frames = []
        original_height = self.height
        
        def vmk(val):
            mvval = None
            if 'anchorBottom' in kwargs and kwargs['anchorBottom']:
                mvval = (val - original_height)/2
            elif 'anchorTop' in kwargs and kwargs['anchorTop']:
                mvval = (original_height - val)/2
            if mvval is not None:
                move_frames.append(mvval)
            return val
        
        anim_vals = self.make_animation_values(self.height, height, vmk)
        kwargs['use_fromVal'] = self.height
        kwargs['extra_keypath'] = 'bounds.size.height'
        ret = self.simple_animation('fakeHeight', anim_vals, duration, **kwargs)
        kwargs.pop('use_fromVal', None)
        kwargs.pop('extra_keypath', None)
        
        self.moveY(move_frames, duration, **kwargs)
        return ret

    def size(self, size_tpl, duration=None, **kwargs):
        """
        Set the width and height of the input. This change saves/is permanent. It is applied to the underlying layer's bounds.
        """
        
        if type(size_tpl[0]) in (list, tuple):
            width_vals = map(lambda x: x[0], size_tpl)
            height_vals = map(lambda y: y[1], size_tpl)
        else:
            width_vals = size_tpl[0]
            height_vals = size_tpl[1]

        self.sizeWidth(width_vals, duration, **kwargs)
        return self.sizeHeight(height_vals, duration, **kwargs)
    
    
    def translateYTo(self, y, duration=None, **kwargs):
        """
        Translate/move the input on the y-axis to the new value y. The final result of this translation is not permanent/saved. If you translate an input and then manually move it via the UI or via the move* functions, it may not restore/go live in the exact position it appears in the layout. Use caution.
        """
        cval = self.animationLayer.valueForKeyPath_('transform.translation.y')

        def vmk(val):
            new_coord = self.real_coordinate_from_fract(0,val)
            new_coord = self.adjust_coordinates(0,new_coord.y)
            return new_coord.y + cval

        anim_vals = self.make_animation_values(0, y, vmk)
        
        
        return self.simple_animation('transform.translation.y', anim_vals, duration, **kwargs)
    
    def translateXTo(self, x, duration=None, **kwargs):
        """
        Translate/move the input on the x-axis to the new value x. The final result of this translation is not permanent/saved. If you translate an input and then manually move it via the UI or via the move* functions, it may not restore/go live in the exact position it appears in the layout. Use caution.
        """
        cval = self.animationLayer.valueForKeyPath_('transform.translation.x')

        def vmk(val):
            new_coord = self.real_coordinate_from_fract(0,val)
            new_coord = self.adjust_coordinates(new_coord.x,0)
            return new_coord.x + cval

        anim_vals = self.make_animation_values(0,x,vmk)
        return self.simple_animation('transform.translation.x', anim_vals, duration, **kwargs)

    def translateTo(self, pos_tpl,duration=None, **kwargs):
        """
        Translate/move the input's origin to the coordinate (x,y) The final result of this translation is not permanent/saved. If you translate an input and then manually move it via the UI or via the move* functions, it may not restore/go live in the exact position it appears in the layout. Use caution.
        """
        cpos = self.animationLayer.valueForKeyPath_('transform.translation')
        csize = cpos.sizeValue()
        def vmk(val):
            new_coord = self.real_coordinate_from_fract(val[0], val[1])
            new_coord = self.adjust_coordinates(new_coord.x,new_coord.y)
            nsize = NSSize(csize.width+new_coord.x, csize.height+new_coord.y)
            return NSValue.valueWithSize_(nsize)

        isize = NSSize(0,0)

        anim_vals = self.make_animation_values(NSValue.valueWithSize_(isize), pos_tpl, vmk)
        return self.simple_animation('transform.translation', anim_vals, duration, **kwargs)

    def translateY(self, y, duration=None, **kwargs):
        
        cval = self.animationLayer.valueForKeyPath_('transform.translation.y')

        def vmk(val):
            new_coord = self.real_coordinate_from_fract(0,val)
            return new_coord.y+cval
        anim_vals = self.make_animation_values(0, y, vmk)
        
        return self.simple_animation('transform.translation.y', anim_vals, duration, **kwargs)
 
    def translateX(self, x, duration=None, **kwargs):
        
        cval = self.animationLayer.valueForKeyPath_('transform.translation.x')

        def vmk(val):
            new_coord = self.real_coordinate_from_fract(val,0)
            return new_coord.x+cval

        anim_vals = self.make_animation_values(0,x,vmk)

        return self.simple_animation('transform.translation.x', anim_vals, duration, **kwargs)
    
    def translate(self, pos_tpl,duration=None, **kwargs):
        
        cpos = self.animationLayer.valueForKeyPath_('transform.translation')
        csize = cpos.sizeValue()

        def vmk(val):
            new_coord = self.real_coordinate_from_fract(val[0],val[1])
            return NSSize(csize.width+new_coord.x, csize.height+new_coord.y)
        
        isize = NSSize(0,0)
        anim_vals = self.make_animation_values(NSValue.valueWithSize_(isize), pos_tpl, vmk)
        
        return self.simple_animation('transform.translation', anim_vals, duration, **kwargs)
    
    def translateCenter(self, duration=None, **kwargs):
        """
            Translate to the center of the layout. This translate is slight different from the other translate animations; it moves the input's CENTER to the center of the layout. The final result of this translation is not permanent/saved. If you translate an input and then manually move it via the UI or via the move* functions, it may not restore/go live in the exact position it appears in the layout. Use caution.
            """
        rootLayer = self.layer.superlayer()
        rootWidth = rootLayer.bounds().size.width
        rootHeight = rootLayer.bounds().size.height
        #we want to move our center to root center. do anchor point correction..
        new_x = rootWidth * 0.5 - self.animationLayer.frame().size.width * 0.5
        new_y = rootHeight * 0.5 - self.animationLayer.frame().size.height * 0.5
        return self.translateTo(new_x, new_y, duration, **kwargs)

    def moveX(self, move_x, duration=None, **kwargs):
        """
        Move the input's X coordinate by move_x units. This change is permanent/saved. If you want non-saved move use the translate* animations
        """
        
        cpos = self.animationLayer.position()
        
        def vmk(val):
            new_coord = self.real_coordinate_from_fract(val,0)
            return cpos.x+new_coord.x

        anim_vals = self.make_animation_values(cpos.x, move_x, vmk)
        return self.simple_animation('position.x', anim_vals, duration, **kwargs)
    
    def moveY(self, move_y, duration=None, **kwargs):
        """
        Move the input's Y coordinate by move_y units. This change is permanent/saved. If you want non-saved move use the translate* animations
        """
        cpos = self.animationLayer.position()
        def vmk(val):
            new_coord = self.real_coordinate_from_fract(0,val)
            return cpos.y+new_coord.y
        
        anim_vals = self.make_animation_values(cpos.y, move_y, vmk)

        return self.simple_animation('position.y', anim_vals, duration, **kwargs)


    def move(self, pos_tpl, duration=None, **kwargs):
        """
        Move the input's position by move_x and move_y units This change is permanent/saved. If you want non-saved move use the translate* animations
        """
        curr_x = self.animationLayer.position().x
        curr_y = self.animationLayer.position().y

        def vmk(val):
            new_coord = self.real_coordinate_from_fract(val[0],val[1])
            return NSPoint(curr_x+new_coord.x, curr_y+new_coord.y)
        
        anim_vals = self.make_animation_values(NSPoint(curr_x, curr_y), pos_tpl, vmk)
        
        path = CGPathCreateMutable()
        CGPathAddLines(path, None, anim_vals, len(anim_vals))
        
        ret = self.moveTo(anim_vals, duration, **kwargs)
    
        CGPathCloseSubpath(path)
        #CGPathRelease(path)
        return ret
    
    
    
    def moveCenter(self, duration=None, **kwargs):
        """
        Move to the center of the layout. This move is slight different from the other move animations; it moves the input's CENTER to the center of the layout.
        """
        rootLayer = self.layer.superlayer()
        rootWidth = rootLayer.bounds().size.width
        rootHeight = rootLayer.bounds().size.height
        #we want to move our center to root center. do anchor point correction..
        new_x = rootWidth * 0.5 - self.animationLayer.frame().size.width * 0.5
        new_y = rootHeight * 0.5 - self.animationLayer.frame().size.height * 0.5
        return self.moveTo(new_x, new_y, duration, **kwargs)
    
    
    def moveYTo(self, move_y, duration=None, **kwargs):
        """
        Move the y component of the input's origin to the move_y point. The origin of an input is the input's bottom left corner. This is an absolute positioning, not a delta from the current position. This move is permanent/saved. If you want a non-saved move use the translate* animations.
        """
        c_pos = self.animationLayer.position()
        
        def vmk(val):
            new_coord = self.real_coordinate_from_fract(0,val)
            new_coord = self.adjust_coordinates(0,new_coord.y)
            n_val = c_pos.y + new_coord.y
            return n_val
        
        anim_value = self.make_animation_values(c_pos.y, move_y, vmk)

        return self.simple_animation('position.y', anim_value, duration, **kwargs)
    
    def moveXTo(self, move_x, duration=None, **kwargs):
        """
        Move the x component of the input's origin to the move_x point. The origin of an input is the input's bottom left corner. This is an absolute positioning, not a delta from the current position. This move is permanent/saved. If you want a non-saved move use the translate* animations.
        """
        c_pos = self.animationLayer.position()
        
        def vmk(val):
            new_coord = self.real_coordinate_from_fract(val, 0)
            new_coord = self.adjust_coordinates(new_coord.x, 0)
            n_val = c_pos.x + new_coord.x
            return n_val
        
        anim_value = self.make_animation_values(c_pos.x, move_x, vmk)
        
        return self.simple_animation('position.x', anim_value, duration, **kwargs)

    def moveTo(self, move_tpl, duration=None, **kwargs):
        """
        Move the y component of the input's origin to (move_x, move_y) The origin of an input is the input's bottom left corner. This is an absolute positioning, not a delta from the current position. This move is permanent/saved. If you want a non-saved move use the translate* animations.
        """

        c_pos = self.animationLayer.position()

        def vmk(val):
            new_coord = self.real_coordinate_from_fract(val[0], val[1])
            new_coord = self.adjust_coordinates(new_coord.x, new_coord.y)
            n_pos = NSPoint()
            n_pos.x = c_pos.x + new_coord.x
            n_pos.y = c_pos.y + new_coord.y
            return NSValue.valueWithPoint_(n_pos)

        anim_vals = self.make_animation_values(NSValue.valueWithPoint_(c_pos), move_tpl, vmk)
        
        return self.simple_animation('position', anim_vals, duration, **kwargs)
    
    def opacity(self, opacity, duration=None, **kwargs):
        """
        Change the opacity/transparency of the input.
        """
        
        anim_vals = self.make_animation_values(self.animationLayer.opacity(), opacity, lambda x: x)
        
        return self.simple_animation('opacity', anim_vals, duration, **kwargs)


    def rotateX(self, angle, duration=None, **kwargs):
        """
        Rotate the input around the x-axis by angle degrees. This rotation is additive: a rotate of 45 degrees followed by another rotate of 45 degrees results in a total rotation of 90 degrees. This rotation is not permanent, it will not persist across save/restore or go live.
        """
        fromVal = self.animationLayer.valueForKeyPath_('transform.rotation.x')

        anim_vals = self.make_animation_values(fromVal, angle, lambda x: fromVal+math.radians(x))
        
        return self.simple_animation('transform.rotation.x', anim_vals, duration, **kwargs)

    def rotateY(self, angle, duration=None, **kwargs):
        """
        Rotate the input around the y-axis by angle degrees. This rotation is additive: a rotate of 45 degrees followed by another rotate of 45 degrees results in a total rotation of 90 degrees. This rotation is not permanent, it will not persist across save/restore or go live.
        """
        fromVal = self.animationLayer.valueForKeyPath_('transform.rotation.y')
        
        anim_vals = self.make_animation_values(fromVal, angle, lambda x: fromVal+math.radians(x))

        return self.simple_animation('transform.rotation.y', anim_vals, duration, **kwargs)
    
    def rotateXTo(self, angle, duration=None, **kwargs):
        
        initVal = self.animationLayer.valueForKeyPath_('transform.rotation.x')

        anim_vals = self.make_animation_values(initVal, angle, lambda x: math.radians(x))
        
        return self.simple_animation('transform.rotation.x', anim_vals, duration, **kwargs)

    def rotateYTo(self, angle, duration=None, **kwargs):
        initVal = self.animationLayer.valueForKeyPath_('transform.rotation.y')
        
        anim_vals = self.make_animation_values(initVal, angle, lambda x: math.radians(x))
        
        return self.simple_animation('transform.rotation.y', anim_vals, duration, **kwargs)


    def rotate(self, angle, duration=None, **kwargs):
        """
        Rotate the input by angle degrees. Positive angles are anti-clockwise, negative angles are clockwise. This rotation is additive: a rotate of 45 degrees followed by another rotate of 45 degrees results in a total rotation of 90 degrees. This rotation is not permanent, it will not persist across save/restore or go live.
        """
        fromVal = self.animationLayer.valueForKeyPath_('transform.rotation.z')
        
        
        anim_vals = self.make_animation_values(fromVal, angle, lambda x: fromVal+math.radians(x))
        
        return self.simple_animation('transform.rotation.z', anim_vals, duration, **kwargs)
    
    def rotateTo(self, angle, duration=None, **kwargs):
        """
        Rotate the input to the specified angle. 
        """
        fromVal = self.animationLayer.valueForKeyPath_('transform.rotation.z')
        
        
        anim_vals = self.make_animation_values(fromVal, angle, lambda x: math.radians(x))
        
        return self.simple_animation('transform.rotation.z', anim_vals, duration, **kwargs)


    def borderwidth(self, width, duration=None, **kwargs):
        """
        Change the border width of the input. You probably also want to set a border color.
        """
        fromVal = self.animationLayer.valueForKeyPath_('borderWidth')
        
        anim_vals = self.make_animation_values(fromVal, width, lambda x: x)

        return self.simple_animation('borderWidth', anim_vals, duration, **kwargs)

    def cornerradius(self, radius, duration=None, **kwargs):
        """
        Change the corner radius of the input. The corner radius is what creates rounded corners.
        """
        fromVal = self.animationLayer.valueForKeyPath_('cornerRadius')
        
        anim_vals = self.make_animation_values(fromVal, radius, lambda x: x)
        
        return self.simple_animation('cornerRadius', anim_vals, duration, **kwargs)

    def __hidden_complete__(self, animation, yesno):
        animation.set_model_value()
        animation.target.setHidden_(yesno)
    
    def hidden(self, yesno, duration=None, **kwargs):
        ret = self.simple_animation('hidden', yesno, duration, **kwargs)
        ret.internal_completion_handler = lambda a: self.__hidden_complete__(a, yesno)
        return ret

    def hide(self, duration=None, **kwargs):
        """
        Hide the input, making it not visible. If it is already hidden this does nothing, but the duration will count towards any waitAnimation() calls
        """

        return self.hidden(True, duration, **kwargs)
    
    def show(self, duration=None, **kwargs):
        """
        Make the input visible. If it is already visible this does nothing, but the duration will count towards any waitAnimation() calls
        """
        return self.hidden(False, duration, **kwargs)
    
    def toggle(self, duration=None, **kwargs):
        """
        Toggle the visibility of the input. If it's hidden, show it, if it's visible hide etc. There is no fadein/fadeout animation for this change. The duration basically acts as a delay, if you hide an input with a duration of 2, it waits 2 seconds before hiding.
        """
        cval = self.animationLayer.hidden()        
        return self.hidden(not cval, duration, **kwargs)
    
    
    def zPosition(self, zpos, duration=None, **kwargs):
        """
        Change the depth of the input to zpos.
        """
        return self.simple_animation('zPosition', zpos, duration, **kwargs)

    def __calculateRelativeMove(self, toInput, **kwargs):
        new_coords = self.animationLayer.frame().origin
        my_size = self.animationLayer.bounds().size
        if 'left' in kwargs:
            l_space = kwargs['left']
            new_coords.x = toInput.minX-my_size.width-l_space
        elif 'right' in kwargs:
            r_space = kwargs['right']
            new_coords.x = toInput.maxX+r_space
        
        if 'top' in kwargs:
            t_space = kwargs['top']
            new_coords.y = toInput.maxY+t_space
        elif 'bottom' in kwargs:
            b_space = kwargs['bottom']
            new_coords.y = toInput.minY-my_size.height-b_space
        
        if 'offsetX' in kwargs:
            ex_space = kwargs['offsetX']
            new_coords.x = toInput.minX+ex_space

        if 'offsetY' in kwargs:
            ex_space = kwargs['offsetY']
            new_coords.y = toInput.minY+ex_space
        return new_coords
            


    def translateRelativeTo(self, toInput, duration=None, **kwargs):
        """
            Translates this input relative to toInput. The following keyword arguments describe positioning options:
            
            left=<margin>: The input is positioned so that its maximum X coordinate is equal to the x coordinate of toInput's origin. If <margin> is greater than zero, the input is positioned offset <margin> pixels from toInput.
            right=<margin>: The input is positioned so that its origin x coordinate is equal to the maximum x coordinate of toInput If <margin> is greater than zero, the input is positioned offset <margin> pixels from toInput.
            bottom=<margin>: The input is positioned so that its maximum Y coordinate is equal to the y coordinate of toInput's origin. If <margin> is greater than zero, the input is positioned offset <margin> pixels from toInput.
            top=<margin>: The input is positioned so that its origin y coordinate is equal to the maximum y coordinate of toInput If <margin> is greater than zero, the input is positioned offset <margin> pixels from toInput.
            
            offsetX=<value>: The input is positioned so that its origin X coordinate is equal to toInput.minX+<value>
            
            offsetY=<value>: The input is positioned so that its origin Y coordinate is equal to toInput.minY+<value>
            
            
            Positioning an input next to some other input typically requires TWO of the above arguments to properly set both the x and y position of the input. Say you have two inputs, input1 and input2. Both are the same size. You wish to move input1 such that it is directly to the left of input2. Your end state looks like the bad ascii diagram below.
            
            +=========+=========+
            |         |         |
            | input1  |  input2 |
            |         |         |
            |         |         |
            +=========+=========+
            
            The animation to do this would be: input1.translateRelativeTo(input2, 1.5, left=0, offsetY=0)
            """

        new_coords = self.__calculateRelativeMove(toInput, **kwargs)
        return self.translateTo(new_coords.x, new_coords.y, duration, **kwargs)


    def moveRelativeTo(self, toInput, duration=None, **kwargs):
        """
        Moves this input relative to toInput. The following keyword arguments describe positioning options:
          
          left=<margin>: The input is positioned so that its maximum X coordinate is equal to the x coordinate of toInput's origin. If <margin> is greater than zero, the input is positioned offset <margin> pixels from toInput. 
          right=<margin>: The input is positioned so that its origin x coordinate is equal to the maximum x coordinate of toInput If <margin> is greater than zero, the input is positioned offset <margin> pixels from toInput.
          bottom=<margin>: The input is positioned so that its maximum Y coordinate is equal to the y coordinate of toInput's origin. If <margin> is greater than zero, the input is positioned offset <margin> pixels from toInput.
          top=<margin>: The input is positioned so that its origin y coordinate is equal to the maximum y coordinate of toInput If <margin> is greater than zero, the input is positioned offset <margin> pixels from toInput.

         offsetX=<value>: The input is positioned so that its origin X coordinate is equal to toInput.minX+<value>
         
         offsetY=<value>: The input is positioned so that its origin Y coordinate is equal to toInput.minY+<value>


         Positioning an input next to some other input typically requires TWO of the above arguments to properly set both the x and y position of the input. Say you have two inputs, input1 and input2. Both are the same size. You wish to move input1 such that it is directly to the left of input2. Your end state looks like the bad ascii diagram below.
         
             +=========+=========+
             |         |         |
             | input1  |  input2 |
             |         |         |
             |         |         |
             +=========+=========+
             
             The animation to do this would be: input1.moveRelativeTo(input2, 1.5, left=0, offsetY=0)
        """
        new_coords = self.__calculateRelativeMove(toInput, **kwargs)
        
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


    @objc.signature('v@:@@@')
    def runAnimation_forInput_withSuperlayer_(self, pluginName,input_or_dict,superlayer):
        input_arg = input_or_dict
        duration = None


        if isinstance(input_or_dict, NSDictionary) or isinstance(input_or_dict, NSMutableDictionary):
            input_arg = {}
            for k in input_or_dict:
                if input_or_dict[k]:
                    arg = input_or_dict[k]
                    if hasattr(arg, 'layer'):

                        input_arg[k] = CSAnimationInput(arg)

                    else:
                        if k == 'duration':
                            duration = float(arg)
                        input_arg[k] = arg
                else:
                    input_arg[k] = None



        animation = plugin_source.load_plugin(pluginName)
        reload(animation)
        CSAnimationBlock.superLayer = superlayer


        CSAnimationBlock.beginAnimation(duration)
#CATransaction.setValue_forKey_("RUNNERT", "__cs_transaction_name")
        animation.wait = CSAnimationBlock.wait
        animation.waitAnimation = CSAnimationBlock.waitAnimation
        animation.animationDuration = CSAnimationBlock.animationDuration


        animation.do_animation(input_arg, duration)


        CSAnimationBlock.commitAnimation()





