//
//  PreviewView.m
//  CocoaSplit
//
//  Created by Zakk on 11/22/12.
//  Copyright (c) 2012 Zakk. All rights reserved.
//
#import <QuartzCore/QuartzCore.h>
#import <OpenGL/OpenGL.h>
#import <OpenGL/glu.h>

#import "PreviewView.h"
#import "InputPopupControllerViewController.h"
#import "SourceLayout.h"
#import "CreateLayoutViewController.h"

//wtf apple

@interface NSCursor (CSApplePrivate)
+ (instancetype)_bottomLeftResizeCursor;
+ (instancetype)_topLeftResizeCursor;
+ (instancetype)_bottomRightResizeCursor;
+ (instancetype)_topRightResizeCursor;
+ (instancetype)_windowResizeNorthEastSouthWestCursor;
+ (instancetype)_windowResizeNorthWestSouthEastCursor;
@end





@implementation PreviewView

@synthesize sourceLayout = _sourceLayout;
@synthesize layoutRenderer = _layoutRenderer;
@synthesize mousedSource = _mousedSource;
@synthesize selectedSource = _selectedSource;




-(void)cursorUpdate:(NSEvent *)event
{
    return;
}

-(void)setSelectedSource:(InputSource *)selectedSource
{
    _selectedSource = selectedSource;
    if (_glLayer)
    {
        _glLayer.outlineSource = selectedSource;
        if (selectedSource)
        {
            _glLayer.doSnaplines = YES;
        } else {
            _glLayer.doSnaplines = NO;
        }
    }
    
}

-(InputSource *)selectedSource
{
    return _selectedSource;
}


-(void)setMousedSource:(InputSource *)mousedSource
{
    _mousedSource = mousedSource;
    if (_glLayer)
    {
        _glLayer.outlineSource = mousedSource;
    }

}

-(InputSource *)mousedSource
{
    return _mousedSource;
}


-(void)setLayoutRenderer:(LayoutRenderer *)layoutRenderer
{
    if (_glLayer)
    {
        _glLayer.renderer = layoutRenderer;
    }
    
    _layoutRenderer = layoutRenderer;
}



-(LayoutRenderer *)layoutRenderer
{
    return _layoutRenderer;
}
-(SourceLayout *)sourceLayout
{
    return _sourceLayout;
}

-(void) setSourceLayout:(SourceLayout *)sourceLayout
{
    
    if (_sourceLayout)
    {
        [NSApp unregisterMIDIResponder:_sourceLayout];
    }
    _sourceLayout = sourceLayout;
    
    
    [NSApp registerMIDIResponder:sourceLayout];
    
    if (self.layoutRenderer)
    {
        self.layoutRenderer.layout = _sourceLayout;
    }

}



-(SourceLayout *)sourceLayoutPreview
{
    return self.sourceLayout;
}





-(BOOL)acceptsFirstResponder
{
    return YES;
}

-(void)cancelOperation:(id)sender
{
    if (self.isInFullScreenMode)
    {
        [self toggleFullscreen:self];
    }
}

-(void)keyDown:(NSEvent *)theEvent
{
    if ([theEvent.charactersIgnoringModifiers isEqualToString:@"f"] && (theEvent.modifierFlags & NSCommandKeyMask))
    {
        [self toggleFullscreen:self];
    }

}



-(NSRect)windowRectforWorldRect:(NSRect)worldRect
{
    
    if (_glLayer)
    {
        return [_glLayer windowRectforWorldRect:worldRect];
    }
    
    return NSZeroRect;
}


-(NSPoint)realPointforWindowPoint:(NSPoint)winPoint
{
    
    
    if (_glLayer)
    {
        return [_glLayer realPointforWindowPoint:winPoint];
    }
    
    return NSZeroPoint;
}


-(void)midiMapSource:(id)sender
{
    if (self.selectedSource)
    {

        InputSource *mapCopy = self.selectedSource.copy;
        mapCopy.uuid = self.selectedSource.uuid;
        
        mapCopy.is_live = !self.selectedSource.is_live;
        
        [self.controller openMidiLearnerForResponders:@[self.selectedSource, mapCopy]];
    }
}


-(void) buildSettingsMenu
{
    
    NSInteger idx = 0;
    
    NSMenuItem *tmp;
    self.sourceSettingsMenu = [[NSMenu allocWithZone:[NSMenu menuZone]] init];
    tmp = [self.sourceSettingsMenu insertItemWithTitle:@"Move Up" action:@selector(moveInputUp:) keyEquivalent:@"" atIndex:idx++];
    tmp.target = self;
    tmp = [self.sourceSettingsMenu insertItemWithTitle:@"Move Down" action:@selector(moveInputDown:) keyEquivalent:@"" atIndex:idx++];
    tmp.target = self;
    tmp = [self.sourceSettingsMenu insertItemWithTitle:@"Auto Fit" action:@selector(autoFitInput:) keyEquivalent:@"" atIndex:idx++];
    tmp.target = self;
    tmp = [self.sourceSettingsMenu insertItemWithTitle:@"Settings" action:@selector(showInputSettings:) keyEquivalent:@"" atIndex:idx++];
    tmp.target = self;
    tmp = [self.sourceSettingsMenu insertItemWithTitle:@"Delete" action:@selector(deleteInput:) keyEquivalent:@"" atIndex:idx++];
    tmp.target = self;
    tmp = [self.sourceSettingsMenu insertItemWithTitle:@"Clone" action:@selector(cloneInputSource:) keyEquivalent:@"" atIndex:idx++];
    tmp.target = self;
    
    tmp = [self.sourceSettingsMenu insertItemWithTitle:@"Midi Mapping" action:@selector(midiMapSource:) keyEquivalent:@"" atIndex:idx++];
    tmp.target = self;
    
    if (self.selectedSource.videoInput && [self.selectedSource.videoInput canProvideTiming])
    {
        tmp = [self.sourceSettingsMenu insertItemWithTitle:@"Use as master timing" action:@selector(setSourceAsTimer:) keyEquivalent:@"" atIndex:idx++];
        tmp.target = self;
    }
    
    if (self.selectedSource.parentInput)
    {
        tmp = [self.sourceSettingsMenu insertItemWithTitle:@"Detach from parent" action:@selector(detachSource:) keyEquivalent:@"" atIndex:idx++];
    } else {
        tmp = [self.sourceSettingsMenu insertItemWithTitle:@"Attach to underlying input" action:@selector(subLayerInputSource:) keyEquivalent:@"" atIndex:idx++];
    }
    tmp.target = self;
}


-(void)doLayoutMidi:(id)sender
{
    if (self.sourceLayout)
    {
        //We need to do mappings for both staging and live, so create a dummy copy that isn't in the same state as ours
        SourceLayout *layoutCopy = [self.sourceLayout copy];
        
        //Default on copy is isActive = NO, so only tweak it if we aren't the active version
        if (!self.sourceLayout.isActive)
        {
            layoutCopy.isActive = YES;
        }
        [self.controller openMidiLearnerForResponders:@[self.sourceLayout, layoutCopy]];
        layoutCopy = nil;
    }
}


-(NSMenu *) buildSourceMenu
{
    
    
    NSArray *sourceList = [self.sourceLayout sourceListOrdered];
    
    NSMenu *sourceListMenu = [[NSMenu allocWithZone:[NSMenu menuZone]] init];
    
    
    

    NSMenuItem *midiItem = [[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:@"Midi Mapping" action:@selector(doLayoutMidi:) keyEquivalent:@""];
    [midiItem setTarget:self];
    [midiItem setEnabled:YES];
    
    [sourceListMenu insertItem:midiItem atIndex:[sourceListMenu.itemArray count]];

    for (InputSource *src in sourceList)
    {
        NSString *srcName = src.name;
        if (!srcName)
        {
            srcName = [NSString stringWithFormat:@"%@-noname", src.selectedVideoType];
            
        }
    
        NSMenuItem *srcItem = [[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:srcName action:nil keyEquivalent:@""];
        [srcItem setEnabled:YES];
        NSMenu *submenu = [[NSMenu allocWithZone:[NSMenu menuZone]] init];
        NSMenuItem *setItem = [[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:@"Settings" action:@selector(showInputSettings:) keyEquivalent:@""];
        [setItem setEnabled:YES];
        [setItem setRepresentedObject:src];
        [setItem setTarget:self];
        [submenu addItem:setItem];
        NSMenuItem *delItem = [[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:@"Delete" action:@selector(deleteInput:) keyEquivalent:@""];
        [delItem setEnabled:YES];
        [delItem setRepresentedObject:src];
        [delItem setTarget:self];
        [submenu addItem:delItem];
        NSMenuItem *cloneItem = [[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:@"Clone" action:@selector(cloneInputSource:) keyEquivalent:@""];
        [cloneItem setEnabled:YES];
        [cloneItem setRepresentedObject:src];
        [cloneItem setTarget:self];
        [submenu addItem:cloneItem];
        
        [srcItem setSubmenu:submenu];
        
        [sourceListMenu insertItem:srcItem atIndex:[sourceListMenu.itemArray count]];
        
    }
    
    return sourceListMenu;
}

-(void)trackMousedSource
{
    
    if (self.selectedSource)
    {
        self.mousedSource = self.selectedSource;
        return;
    }
    
    
    NSPoint mouseLoc = [NSEvent mouseLocation];
    
    NSRect rect = NSRectFromCGRect((CGRect){mouseLoc, CGSizeZero});
    
    mouseLoc = [self.window convertRectFromScreen:rect].origin;
    mouseLoc = [self convertPoint:mouseLoc fromView:nil];
    
    if (![self mouse:mouseLoc inRect:self.bounds])
    {
        return;
    }
    
    
    NSPoint worldPoint = [self realPointforWindowPoint:mouseLoc];
    
    InputSource *newSrc = [self.sourceLayout findSource:worldPoint withExtra:2 deepParent:YES];
    

    if (!newSrc)
    {
        [NSCursor pop];
    }
    
    NSArray *resizeRects = [self resizeRectsForSource:newSrc withExtra:2];

    NSCursor *newCursor = [NSCursor openHandCursor];
    
    bool hitResize = NO;
    
    //bottom left, top left, top right, bottom right
    for(int i=0; i < resizeRects.count; i++)
    {
        NSValue *rVal = [resizeRects objectAtIndex:i];
        
        NSRect reRect = [rVal rectValue];
        if (NSPointInRect(mouseLoc, reRect))
        {
            if (i == 0 || i == 2)
            {
                newCursor = [NSCursor _windowResizeNorthEastSouthWestCursor];
            } else {
                newCursor = [NSCursor _windowResizeNorthWestSouthEastCursor];
            }
            hitResize = YES;
            break;
        }
        
        
    }
    
    if ((newSrc != self.mousedSource) || (hitResize != _in_resize_rect))
    {
        [NSCursor pop];
        [newCursor push];
    }
 
    self.mousedSource = newSrc;
    _in_resize_rect = hitResize;
}




-(void)rightMouseDown:(NSEvent *)theEvent
{
    
    if (self.viewOnly)
    {
        return;
    }
    
    bool doDeep = YES;
    
    if (theEvent.modifierFlags & NSControlKeyMask)
    {
        doDeep = NO;
    }
    NSPoint tmp;
    
    tmp = [self convertPoint:theEvent.locationInWindow fromView:nil];
    NSPoint worldPoint = [self realPointforWindowPoint:tmp];
    self.selectedSource = [self.sourceLayout findSource:worldPoint deepParent:doDeep];
    
    if (self.selectedSource)
    {
        [self buildSettingsMenu];
        [self.sourceSettingsMenu popUpMenuPositioningItem:self.sourceSettingsMenu.itemArray.firstObject atLocation:tmp inView:self];
    } else {
        
        NSMenu *srcListMenu = [self buildSourceMenu];
        
        [srcListMenu popUpMenuPositioningItem:srcListMenu.itemArray.firstObject atLocation:tmp inView:self];
    }
}


//bottom left, top left, top right, bottom right

-(NSArray *)resizeRectsForSource:(InputSource *)inputSource withExtra:(float)withExtra
{
    
    NSRect layoutRect = inputSource.globalLayoutPosition;
    
    
    NSRect extraRect = NSInsetRect(layoutRect, -withExtra, -withExtra);
    
    NSRect viewRect = [self windowRectforWorldRect:extraRect];
    
    
    NSRect bottomLeftRect = NSMakeRect(viewRect.origin.x, viewRect.origin.y, 10.0f, 10.0f);
    NSRect bottomRightRect = NSMakeRect(viewRect.origin.x+viewRect.size.width-10.0f, viewRect.origin.y, 10.0f, 10.0f);
    
    NSRect topLeftRect = NSMakeRect(viewRect.origin.x, viewRect.origin.y+viewRect.size.height-10.0f, 10.0f, 10.0f);
    
    NSRect topRightRect = NSMakeRect(viewRect.origin.x+viewRect.size.width-10.0f, viewRect.origin.y+viewRect.size.height-10.0f, 10.0f, 10.0f);
    
    
    return @[[NSValue valueWithRect:bottomLeftRect], [NSValue valueWithRect:topLeftRect], [NSValue valueWithRect:topRightRect],[NSValue valueWithRect:bottomRightRect]];
    
}



-(void)drawRect:(NSRect)dirtyRect
{
    if (self.mousedSource)
    {
        NSArray *resizeRects = [self resizeRectsForSource:self.selectedSource withExtra:2];
        for (NSValue *rVal in resizeRects)
        {
            NSRect rect = [rVal rectValue];
            CGContextRef currentContext = (CGContextRef)[[NSGraphicsContext currentContext] graphicsPort];
            CGContextSetFillColorWithColor(currentContext, [NSColor colorWithDeviceRed:1.0f green:0.0f blue:0.0f alpha:0.2].CGColor);
            CGContextFillRect(currentContext, rect);
        }
    }
}


- (void)mouseDown:(NSEvent *)theEvent
{
    
    if (self.viewOnly)
    {
        return;
    }
    
    
    NSPoint tmp;
    
    tmp = [self convertPoint:theEvent.locationInWindow fromView:nil];
    
    NSPoint worldPoint = [self realPointforWindowPoint:tmp];
    
    InputSource *oldSource = self.selectedSource;
    
    InputSource *topSource = [self.sourceLayout findSource:worldPoint deepParent:NO];

    InputSource *deepSource = [self.sourceLayout findSource:worldPoint deepParent:YES];
;
    
    if (theEvent.modifierFlags & NSControlKeyMask)
    {
        self.selectedSource = topSource;
    } else {
        self.selectedSource = deepSource;
    }
    
    if (!self.selectedSource)
    {
        return;
    }
    
    
    self.selectedSource.is_selected = YES;
    if (oldSource)
    {
        oldSource.is_selected = NO;
    }
    
    
    NSArray *resizeRects = [self resizeRectsForSource:self.selectedSource withExtra:2];
    
    //bottom left, top left, top right, bottom right

    
    NSRect bottomLeftRect = [[resizeRects objectAtIndex:0] rectValue];
    NSRect topLeftRect = [[resizeRects objectAtIndex:1] rectValue];
    NSRect topRightRect = [[resizeRects objectAtIndex:2] rectValue];
    NSRect bottomRightRect = [[resizeRects objectAtIndex:3] rectValue];
    
    self.resizeType = kResizeNone;
    
    if (NSPointInRect(tmp, topLeftRect))
    {
        self.resizeType = kResizeLeft | kResizeTop;
    } else if (NSPointInRect(tmp, bottomLeftRect)) {
        self.resizeType = kResizeLeft | kResizeBottom;

    } else if (NSPointInRect(tmp, topRightRect)) {
        self.resizeType = kResizeRight | kResizeTop;
    } else if (NSPointInRect(tmp, bottomRightRect)) {
        self.resizeType = kResizeRight | kResizeBottom;
    }
    
    
    self.isResizing = self.resizeType != kResizeNone;
    
    if (self.isResizing)
    {
        self.selectedSource = deepSource;
    }
    
    
    self.selectedOriginDistance = worldPoint;
    
    if (self.isResizing)
    {
        if (theEvent.modifierFlags & NSAlternateKeyMask)
        {
            self.resizeType |= kResizeCenter;
        }
        
        if (theEvent.modifierFlags & NSControlKeyMask)
        {
            self.resizeType |= kResizeFree;
        }
        
        if (theEvent.modifierFlags & NSShiftKeyMask)
        {
            self.resizeType |= kResizeCrop;
        }


    }
    self.selectedSource.resizeType = self.resizeType;

    
}



-(void)doUndoSourceFrame:(NSRect)oldFrame forInput:(NSString *)forInput
{
    if (forInput)
    {
        InputSource *realInput = [self.sourceLayout inputForUUID:forInput];
        if (realInput)
        {
            [realInput updateSize:oldFrame.size.width height:oldFrame.size.height];
            [realInput positionOrigin:oldFrame.origin.x y:oldFrame.origin.y];
        }
    }
}


- (void)mouseDragged:(NSEvent *)theEvent
{
    
    NSPoint tmp;
    
    
    NSPoint worldPoint;
    if (self.selectedSource)
    {
        
        if (!_inDrag)
        {
            NSRect curFrame = self.selectedSource.layoutPosition;
            
            [[self.undoManager prepareWithInvocationTarget:self] doUndoSourceFrame:curFrame forInput:self.selectedSource.uuid];
        }
        
        _inDrag = YES;
        tmp = [self convertPoint:theEvent.locationInWindow fromView:nil];
        
        worldPoint = [self realPointforWindowPoint:tmp];
        
        
        
        
        CGFloat dx, dy;
        dx = worldPoint.x - self.selectedOriginDistance.x;
        dy = worldPoint.y - self.selectedOriginDistance.y;
        [self adjustDeltas:&dx dy:&dy];

        self.selectedOriginDistance = worldPoint;
        if (self.isResizing)
        {
            if (theEvent.modifierFlags & NSShiftKeyMask)
            {
                //Crop is expressed as a floating point number between 0.0 and 1.0, basically a percentage of that dimension.
                //Convert appropriately.
                
                float x_crop = dx/self.selectedSource.globalLayoutPosition.size.width;
                float y_crop = dy/self.selectedSource.globalLayoutPosition.size.height;
                
                
                if (self.resizeType & kResizeRight)
                {
                    self.selectedSource.crop_right -= x_crop;
                }
                
                if (self.resizeType & kResizeLeft)
                {
                    self.selectedSource.crop_left += x_crop;
                }
                
                if (self.resizeType & kResizeTop)
                {
                    self.selectedSource.crop_top -= y_crop;
                }
                
                if (self.resizeType & kResizeBottom)
                {
                    self.selectedSource.crop_bottom += y_crop;
                }
                
            } else {
                
                if (theEvent.modifierFlags & NSAlternateKeyMask)
                {
                    self.resizeType |= kResizeCenter;
                } else {
                    self.resizeType &= ~kResizeCenter;
                }
                
                CGFloat new_width, new_height;
                
                NSRect sPosition = self.selectedSource.globalLayoutPosition;
                
                new_width = sPosition.size.width;
                new_height = sPosition.size.height;
                
                if (self.resizeType & kResizeRight)
                {
                    new_width += dx;
                    
                }
                
                if (self.resizeType & kResizeLeft)
                {
                    new_width -= dx;
                    
                }
                
                
                if (self.resizeType & kResizeTop)
                {
                    new_height += dy;
                }
                
                if (self.resizeType & kResizeBottom)
                {
                    new_height -= dy;
                }
                
                
                [self.selectedSource updateSize:new_width height:new_height];

            }
            
        } else {
            
            [self.selectedSource updateOrigin:dx y:dy];
            if (_overlayView)
            {
                NSRect newRect = [self windowRectforWorldRect:self.selectedSource.globalLayoutPosition];
                _overlayView.frame = newRect;
            }
        }
    }
    if (_overlayView)
    {
        [_overlayView updatePosition];
    }

    
}


-(void)adjustDeltas:(CGFloat *)dx dy:(CGFloat *)dy
{
    
    InputSource *superInput = self.selectedSource.parentInput;
    
    NSPoint c_lb_snap;
    NSPoint c_rt_snap;
    NSPoint c_center_snap;
    
    if (superInput)
    {
        NSRect super_rect = superInput.globalLayoutPosition;
        
        c_lb_snap = super_rect.origin;
        c_rt_snap = NSMakePoint(NSMaxX(super_rect), NSMaxY(super_rect));
        c_center_snap = NSMakePoint(NSMidX(super_rect), NSMidY(super_rect));
    } else {
    //define snap points. basically edges and the center of the canvas
        c_lb_snap = NSMakePoint(0, 0);
        c_rt_snap = NSMakePoint(self.sourceLayout.canvas_width, self.sourceLayout.canvas_height);
        c_center_snap = NSMakePoint(self.sourceLayout.canvas_width/2, self.sourceLayout.canvas_height/2);
    }
    
    

    
    //selected source snap points. edges, and center
    
    if (!self.selectedSource)
    {
        return;
    }
    
    NSRect src_rect = self.selectedSource.globalLayoutPosition;

    NSPoint s_lb_snap = src_rect.origin;
    NSPoint s_rt_snap = NSMakePoint(src_rect.origin.x+src_rect.size.width, src_rect.origin.y+src_rect.size.height);
    NSPoint s_center_snap = NSMakePoint(src_rect.origin.x+roundf(src_rect.size.width/2), src_rect.origin.y+roundf(src_rect.size.height/2));
    
    
    NSPoint dist;
    
    NSPoint s_snaps[3] = {s_lb_snap, s_rt_snap, s_center_snap};
    NSPoint c_snaps[3] = {c_lb_snap, c_rt_snap, c_center_snap};
    
    bool did_snap_x = NO;
    bool did_snap_y = NO;
    
    //Check if we're already snapped. If we are, check if it's time to break the magnetism.
    if (_snap_x != -1)
    {
        _snap_x_accum += *dx;
        if (fabs(_snap_x_accum) > SNAP_THRESHOLD*2)
        {
            _snap_x = -1;
            *dx = _snap_x_accum;
            _snap_x_accum = 0;
        } else {
            *dx = 0;
        }
        
        did_snap_x = YES;
    }
    
    if (_snap_y != -1)
    {
        _snap_y_accum += *dy;
        if (fabs(_snap_y_accum) > SNAP_THRESHOLD*2)
        {
            _snap_y = -1;
            *dy = _snap_y_accum;
            _snap_y_accum = 0;
        } else {
            *dy = 0;
        }
        
        did_snap_y = YES;
    }


    for(int i=0; i < sizeof(s_snaps)/sizeof(NSPoint); i++)
    {
        NSPoint s_snap = s_snaps[i];
        for(int j=0; j < sizeof(c_snaps)/sizeof(NSPoint); j++)
        {
            
            NSPoint c_snap = c_snaps[j];
            dist = [self pointDistance:s_snap b:c_snap];
            if (!did_snap_x && (copysignf(dist.x, *dx) != dist.x) && (fabs(dist.x) < SNAP_THRESHOLD))
            {
                if ((s_snap.x != c_snap.x) && (_snap_x == -1))
                {
                    *dx = -dist.x;
                    _snap_x = c_snap.x;
                    _snap_x_accum = 0;
                    did_snap_x = YES;
                }
            }
            
            if ((*dy != 0) && !did_snap_y && (copysignf(dist.y, *dy) != dist.y) && (fabs(dist.y) < SNAP_THRESHOLD))
            {

                if ((s_snap.y != c_snap.y) && (_snap_y == -1))
                {
                    *dy = -dist.y;
                    _snap_y = c_snap.y;
                    _snap_y_accum = 0;
                    did_snap_y = YES;

                }
            }
        }
    }
    
    if (_glLayer)
    {
        _glLayer.snap_x = _snap_x;
        _glLayer.snap_y  = _snap_y;
    }
}


-(NSPoint)pointDistance:(NSPoint )a b:(NSPoint )b
{
    NSPoint ret;
    
    ret.x = a.x - b.x;
    ret.y = a.y - b.y;
    return ret;
}


-(void) mouseUp:(NSEvent *)theEvent
{
    _snap_x = -1;
    _snap_y = -1;
    _snap_x_accum = 0;
    _snap_y_accum  = 0;
    
    self.isResizing = NO;
    self.selectedSource.resizeType = kResizeNone;
    self.selectedSource = nil;
    _inDrag = NO;
}


-(void) mouseMoved:(NSEvent *)theEvent
{
    
    if (!self.viewOnly)
    {
        [self trackMousedSource];
        if (!_overlayView)
        {
            _overlayView = [[CSPreviewOverlayView alloc] init];
            _overlayView.previewView = self;
        }
        
        _overlayView.parentSource = self.mousedSource;
    }
    
    
    
}





- (IBAction)moveInputUp:(id)sender
{
    if (self.selectedSource)
    {
        self.selectedSource.depth += 1;
        
    }
}


- (IBAction)moveInputDown:(id)sender
{
    if (self.selectedSource)
    {
        self.selectedSource.depth -= 1;
    }
}


-(void)setSourceAsTimer:(id)sender
{
    NSMenuItem *item = (NSMenuItem *)sender;
    InputSource *useSrc;
    
    if (item.representedObject)
    {
        useSrc = (InputSource *)item.representedObject;
    } else {
        useSrc = self.selectedSource;
    }

    if (useSrc.videoInput && [useSrc.videoInput canProvideTiming])
    {
        self.sourceLayout.layoutTimingSource = useSrc;
    }
}


-(void)detachSource:(id)sender
{
    InputSource *toDetach = nil;
    
    if (sender)
    {
        if ([sender isKindOfClass:[NSMenuItem class]])
        {
            NSMenuItem *item = (NSMenuItem *)sender;
            toDetach = (InputSource *)item.representedObject;
        } else if ([sender isKindOfClass:[InputSource class]]) {
            toDetach = (InputSource *)sender;
        }
    }
    
    if (!toDetach)
    {
        toDetach = self.selectedSource;
    }
    
    if (toDetach && toDetach.parentInput)
    {
        [((InputSource *)toDetach.parentInput) detachInput:toDetach];
        [[self.undoManager prepareWithInvocationTarget:self] subLayerInputSource:toDetach];
    }
}


-(void)attachSource:(InputSource *)src toSource:(InputSource *)toSource
{
    if (src && toSource)
    {
        [toSource attachInput:src];

    }
}
-(void)subLayerInputSource:(id)sender
{
    InputSource *toSub = nil;
    
    if (sender)
    {
        if ([sender isKindOfClass:[NSMenuItem class]])
        {
            NSMenuItem *item = (NSMenuItem *)sender;
            toSub = (InputSource *)item.representedObject;
        } else if ([sender isKindOfClass:[InputSource class]]) {
            toSub = (InputSource *)sender;
        }
    }

    if (!toSub)
    {
        toSub = self.selectedSource;
    }
    
    if (toSub)
    {
        InputSource *underSource = [self.sourceLayout sourceUnder:toSub];
        if (underSource)
        {
            [underSource attachInput:toSub];
            [[self.undoManager prepareWithInvocationTarget:self] detachSource:toSub];
        }
    }
}


-(void)undoCloneInput:(NSString *)inputUUID parentUUID:(NSString *)parentUUID
{
    

    if (inputUUID)
    {
        InputSource *clonedSource = [self.sourceLayout inputForUUID:inputUUID];
        if (clonedSource)
        {
            [self.sourceLayout deleteSource:clonedSource];

        }
    }
    if (parentUUID)
    {
        InputSource *parentSource = [self.sourceLayout inputForUUID:parentUUID];
        if (parentSource)
        {
            [[self.undoManager prepareWithInvocationTarget:self] cloneInputSource:parentSource];
        }
    }
}

- (IBAction)cloneInputSource:(id)sender
{
    
    InputSource *toClone = nil;

    if (sender)
    {
        if ([sender isKindOfClass:[NSMenuItem class]])
        {
            NSMenuItem *item = (NSMenuItem *)sender;
            toClone = (InputSource *)item.representedObject;
        } else if ([sender isKindOfClass:[InputSource class]]) {
            toClone = (InputSource *)sender;
        }
    }
    
    if (!toClone)
    {
        toClone = self.selectedSource;
    }

    if (toClone)
    {
        InputSource *newSource = toClone.copy;
        [self.sourceLayout addSource:newSource];
        [[self.undoManager prepareWithInvocationTarget:self] undoCloneInput:newSource.uuid parentUUID:toClone.uuid];
    }
}



- (IBAction)addInputSource:(id)sender
{
    
    if (self.sourceLayout)
    {
        InputSource *newSource = [[InputSource alloc] init];
        
        [self.sourceLayout addSource:newSource];
        [[self.undoManager prepareWithInvocationTarget:self] deleteInput:newSource];
        [self spawnInputSettings:newSource atRect:NSZeroRect];
    }
}



-(void)addUndoAction
{
    NSData *curData = [self.sourceLayout makeSaveData];
    [self.undoManager registerUndoWithTarget:self selector:@selector(undoLayoutEdit:) object:curData];
}


-(void)undoLayoutEdit:(NSData *)withData
{
    [self.sourceLayout restoreSourceList:withData];
}

-(void)undoDeleteInput:(NSData *)withData parentUUID:(NSString *)parentUUID
{
    InputSource *restoredSource = [NSKeyedUnarchiver unarchiveObjectWithData:withData];
    
    [self.sourceLayout addSource:restoredSource];
    if (parentUUID)
    {
        InputSource *parentSource = [self.sourceLayout inputForUUID:parentUUID];
        if (parentSource)
        {
            [self attachSource:restoredSource toSource:parentSource];
        }
    }
    [[self.undoManager prepareWithInvocationTarget:self] deleteInput:restoredSource];
}



- (IBAction)deleteInput:(id)sender
{
    InputSource *toDelete = nil;

    if ([sender isKindOfClass:[NSMenuItem class]])
    {
        NSMenuItem *item = (NSMenuItem *)sender;
        if (item && item.representedObject)
        {
            toDelete = item.representedObject;
        }
    } else if ([sender isKindOfClass:[InputSource class]]) {
        toDelete = (InputSource *)sender;
    }

    if (!toDelete)
    {
        toDelete = self.selectedSource ? self.selectedSource : self.mousedSource;
    }
    
    if (toDelete)
    {
        self.selectedSource = nil;
        self.mousedSource = nil;

        NSString *pUUID = nil;
        if (toDelete.parentInput)
        {
            pUUID = toDelete.parentInput.uuid;
            [toDelete.parentInput detachInput:toDelete];
        }

        NSData *saveData = [NSKeyedArchiver archivedDataWithRootObject:toDelete];
        
        [[self.undoManager prepareWithInvocationTarget:self] undoDeleteInput:saveData parentUUID:pUUID];
        [self.sourceLayout deleteSource:toDelete];
        if (_overlayView)
        {
            _overlayView.parentSource = nil;
        }
    }
}



-(void)needsUpdate
{
    if (_glLayer)
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            [_glLayer setNeedsDisplay];

            
        });
    }
}


-(void)spawnInputSettings:(InputSource *)forInput atRect:(NSRect)atRect
{
    
    NSRect spawnRect;
    spawnRect = atRect;
    
    if (NSEqualRects(spawnRect, NSZeroRect))
    {
        NSRect inputRect = [self windowRectforWorldRect:forInput.globalLayoutPosition];
        spawnRect = NSInsetRect(inputRect, inputRect.size.width/2-2.0f, inputRect.size.height/2-2.0f);
    }
    
    
    InputPopupControllerViewController *popupController = [[InputPopupControllerViewController alloc] init];
    
    NSPopover *popover = [[NSPopover alloc] init];
    popover.contentViewController = popupController;
    popover.animates = YES;
    popover.delegate = self;
    popover.behavior = NSPopoverBehaviorSemitransient;
    [popover showRelativeToRect:spawnRect ofView:self preferredEdge:NSMaxXEdge];
    
    popupController.inputSource = forInput;
    self.activePopupController = popupController;
}


-(void)undoAutoFit:(NSString *)inputUUID oldFrame:(NSRect)oldFrame
{
    if (inputUUID)
    {
        InputSource *unfit = [self.sourceLayout inputForUUID:inputUUID];
        if (unfit)
        {
            [unfit resetConstraints];
            [unfit updateSize:oldFrame.size.width height:oldFrame.size.height];
            [unfit positionOrigin:oldFrame.origin.x y:oldFrame.origin.y];
            [[self.undoManager prepareWithInvocationTarget:self] autoFitInput:unfit];
        }
    }
}



-(IBAction) autoFitInput:(id)sender
{
    InputSource *autoFitSource = nil;
    
    if ([sender isKindOfClass:[NSMenuItem class]])
    {
        NSMenuItem *item = (NSMenuItem *)sender;
        if (item && item.representedObject)
        {
            autoFitSource = item.representedObject;
        }
    } else if ([sender isKindOfClass:[InputSource class]]) {
        autoFitSource = (InputSource *)sender;
    }
    
    if (!autoFitSource)
    {
        autoFitSource = self.selectedSource;
    }

    if (autoFitSource)
    {
        [autoFitSource autoFit];
        [[self.undoManager prepareWithInvocationTarget:self] undoAutoFit:autoFitSource.uuid oldFrame:autoFitSource.layoutPosition];
    }
}



- (IBAction)showInputSettings:(id)sender
{
    
    
    InputSource *configSource;
    
    NSMenuItem *menuSender = (NSMenuItem *)sender;
    
    
    
    configSource = self.selectedSource;
    if (menuSender.representedObject)
    {
        configSource = (InputSource *)menuSender.representedObject;
    }
    
    
    NSPoint tmp = [self convertPoint:[self.window mouseLocationOutsideOfEventStream] fromView:nil];

    NSRect spawnRect = NSMakeRect(tmp.x, tmp.y, 1.0f, 1.0f);
    
    if (!NSPointInRect(NSMakePoint(tmp.x, 0), self.bounds))
    {
        spawnRect = NSMakeRect(self.bounds.size.width-5, tmp.y, 1.0f, 1.0f);
    } else if (!NSPointInRect(NSMakePoint(0, tmp.y), self.bounds)) {
        spawnRect = NSMakeRect(tmp.x, 5.0f, 1.0f, 1.0f);
    }
    
    [self spawnInputSettings:configSource atRect:spawnRect];

}


-(void)goFullscreen:(NSScreen *)onScreen
{
    
    if (self.isInFullScreenMode)
    {
        
        
        [self exitFullScreenModeWithOptions:nil];
        
        
        [self.controller layoutLeftFullscreen];
        
    } else {
        
        NSNumber *fullscreenOptions = @(NSApplicationPresentationAutoHideMenuBar|NSApplicationPresentationAutoHideDock);
        
        
        _fullscreenOn = onScreen;
        
        
        
        [self.controller layoutWentFullscreen];

        [self enterFullScreenMode:_fullscreenOn withOptions:@{NSFullScreenModeAllScreens: @NO, NSFullScreenModeApplicationPresentationOptions: fullscreenOptions}];
        

    }
    
}


- (IBAction)toggleFullscreen:(id)sender;
{
    [self goFullscreen:[NSScreen mainScreen]];
    
    
}




-(void)awakeFromNib
{
    
    self.activeConfigWindows = [NSMutableDictionary dictionary];
    self.activeConfigControllers = [NSMutableDictionary dictionary];
    
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(sourceWasDeleted:) name:CSNotificationInputDeleted object:nil];
    
    
    _snap_x = _snap_y = -1;
    
    int opts = (NSTrackingActiveAlways | NSTrackingInVisibleRect | NSTrackingMouseMoved | NSTrackingMouseEnteredAndExited);
    _trackingArea = [[NSTrackingArea alloc] initWithRect:[self bounds]
                                                 options:opts
                                                   owner:self
                                                userInfo:nil];
    
    [self addTrackingArea:_trackingArea];

    [self setWantsLayer:YES];
    
    self.layer.backgroundColor = CGColorCreateGenericRGB(0.184314f, 0.309804f, 0.309804f, 1);
    
}

-(CALayer *)makeBackingLayer
{
    _glLayer = [CSPreviewGLLayer layer];

    return _glLayer;
}



-(void)sourceWasDeleted:(NSNotification *)notification
{
    InputSource *toDel = notification.object;
    [self purgeConfigForInput:toDel];
}


-(void)purgeConfigForInput:(InputSource *)src
{
    NSString *uuid = src.uuid;
    
    NSWindow *cWindow = [self.activeConfigWindows objectForKey:uuid];
    InputPopupControllerViewController *cController = [self.activeConfigControllers objectForKey:uuid];
    
    
    if (cController)
    {
        cController.inputSource = nil;
        [self.activeConfigControllers removeObjectForKey:uuid];
    }
    
    if (cWindow)
    {
        [cWindow close];
        [self.activeConfigWindows removeObjectForKey:uuid];
    }
}


- (BOOL)popoverShouldDetach:(NSPopover *)popover
{
    return YES;
}


-(NSWindow *)detachableWindowForPopover:(NSPopover *)popover
{

    
    
    
    InputPopupControllerViewController *newViewController = [[InputPopupControllerViewController alloc] init];
    
    InputPopupControllerViewController *oldViewController = (InputPopupControllerViewController *)popover.contentViewController;
    
    
    
    newViewController.inputSource = oldViewController.inputSource;
    
    NSWindow *popoverWindow;
    popoverWindow = [[NSWindow alloc] init];
    
    
    
    NSRect newFrame = [popoverWindow frameRectForContentRect:NSMakeRect(0.0f, 0.0f, newViewController.view.frame.size.width, newViewController.view.frame.size.height)];
    
    [popoverWindow setFrame:newFrame display:NO];
    
    [popoverWindow setReleasedWhenClosed:NO];
    
    
    [popoverWindow.contentView addSubview:newViewController.view];
    popoverWindow.title = [NSString stringWithFormat:@"CocoaSplit Input (%@)", newViewController.inputSource.name];
    popoverWindow.delegate = self;
    
    popoverWindow.styleMask =  NSTitledWindowMask|NSClosableWindowMask|NSMiniaturizableWindowMask;
    
    NSString *uuid = newViewController.inputSource.uuid;
    
    NSWindow *cWindow = [self.activeConfigWindows objectForKey:uuid];
    InputPopupControllerViewController *cController = [self.activeConfigControllers objectForKey:uuid];
    
    if (cController)
    {
        cController.inputSource = nil;
        [self.activeConfigControllers removeObjectForKey:uuid];
    }
    
    if (cWindow)
    {
        [self.activeConfigWindows removeObjectForKey:uuid];
    }
    
    
    [self.activeConfigWindows setObject:popoverWindow forKey:uuid];
    [self.activeConfigControllers setObject:newViewController forKey:uuid];
    
    return popoverWindow;
}

- (void)popoverDidClose:(NSNotification *)notification
{
    
    
    NSString *closeReason = [[notification userInfo] valueForKey:NSPopoverCloseReasonKey];
    NSPopover *popover = notification.object;
    if (closeReason && closeReason == NSPopoverCloseReasonStandard)
    {
        InputPopupControllerViewController *vcont = (InputPopupControllerViewController *)popover.contentViewController;
        
        vcont.inputSource = nil;
        
    }
    
    if (popover.contentViewController == self.activePopupController)
    {
        self.activePopupController = nil;
        popover.contentViewController = nil;
    }
}


@end
