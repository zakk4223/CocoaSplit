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
#import "CSLayoutRecorder.h"

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


-(void)setMidiActive:(bool)midiActive
{
    _glLayer.midiActive = midiActive;
}


-(bool)midiActive
{
    return _glLayer.midiActive;
}



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
        _glLayer.doRender = self.isEditWindow;
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
    
    if (_sourceLayout && !self.isEditWindow)
    {
        [NSApp unregisterMIDIResponder:_sourceLayout];
        
    }
    _sourceLayout = sourceLayout;
    [self.undoManager removeAllActions];
    sourceLayout.undoManager = self.undoManager;
    
    if (!self.isEditWindow)
    {
        [NSApp registerMIDIResponder:sourceLayout];
    }
    
    
    if (_sourceLayout.recorder)
    {
        self.layoutRenderer = _sourceLayout.recorder.renderer;
        [self disablePrimaryRender];
        
    } else {
        if (self.layoutRenderer)
        {
            self.layoutRenderer.layout = _sourceLayout;
        }
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

        [self.controller openMidiLearnerForResponders:@[self.selectedSource]];
    }
}


- (IBAction)addInputToLibrary:(id)sender
{
    
    InputSource *toAdd = nil;
    
    if (sender)
    {
        if ([sender isKindOfClass:[NSMenuItem class]])
        {
            NSMenuItem *item = (NSMenuItem *)sender;
            toAdd = (InputSource *)item.representedObject;
        } else if ([sender isKindOfClass:[InputSource class]]) {
            toAdd = (InputSource *)sender;
        }
    }
    
    if (!toAdd)
    {
        toAdd = self.selectedSource;
    }
    
    if (toAdd)
    {
        [self.controller addInputToLibrary:toAdd];
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
    tmp = [self.sourceSettingsMenu insertItemWithTitle:@"Settings" action:@selector(showInputSettings:) keyEquivalent:@"" atIndex:idx++];
    tmp.target = self;
    tmp = [self.sourceSettingsMenu insertItemWithTitle:@"Clone" action:@selector(cloneInputSource:) keyEquivalent:@"" atIndex:idx++];
    tmp.target = self;
    
    NSString *freezeString = @"Freeze";
    if (self.selectedSource.isFrozen)
    {
        freezeString = @"Unfreeze";
    }
    
    
    tmp = [self.sourceSettingsMenu insertItemWithTitle:freezeString action:@selector(freezeInputSource:) keyEquivalent:@"" atIndex:idx++];
    tmp.target = self;

    
    tmp = [self.sourceSettingsMenu insertItemWithTitle:@"Add to Library" action:@selector(addInputToLibrary:) keyEquivalent:@"" atIndex:idx++];
    tmp.target = self;

    tmp = [self.sourceSettingsMenu insertItemWithTitle:@"Midi Mapping" action:@selector(midiMapSource:) keyEquivalent:@"" atIndex:idx++];
    tmp.target = self;
    
    if (self.selectedSource.videoInput && [self.selectedSource.videoInput canProvideTiming])
    {
        
        if (self.sourceLayout.layoutTimingSource == self.selectedSource)
        {
            tmp = [self.sourceSettingsMenu insertItemWithTitle:@"Stop using as master timing" action:@selector(removeSourceTimer:) keyEquivalent:@"" atIndex:idx++];
            tmp.target = self;

        } else {
            tmp = [self.sourceSettingsMenu insertItemWithTitle:@"Use as master timing" action:@selector(setSourceAsTimer:) keyEquivalent:@"" atIndex:idx++];
            tmp.target = self;
        }
    }
    
    if (self.selectedSource.parentInput)
    {
        tmp = [self.sourceSettingsMenu insertItemWithTitle:@"Detach from parent" action:@selector(detachSource:) keyEquivalent:@"" atIndex:idx++];
    } else {
        tmp = [self.sourceSettingsMenu insertItemWithTitle:@"Attach to underlying input" action:@selector(subLayerInputSource:) keyEquivalent:@"" atIndex:idx++];
    }
    
    tmp.target = self;
    
    tmp = [self.sourceSettingsMenu insertItemWithTitle:@"Reset to source AR" action:@selector(resetSourceAR:) keyEquivalent:@"" atIndex:idx++];
    tmp.target = self;
}



-(void)doToggleTransitions:(id)sender
{
    if (self.controller)
    {
        self.controller.useTransitions = !self.controller.useTransitions;
    }
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


-(void)menu:(NSMenu *)menu willHighlightItem:(nullable NSMenuItem *)item
{
    if (item.representedObject)
    {
        InputSource *hInput = (InputSource *)item.representedObject;
        if (_overlayView)
        {
            _overlayView.parentSource = hInput;
        }
    }
}



-(void)resolutionMenuAction:(NSMenuItem *)sender
{
    NSInteger tag = sender.tag;
    
    if (!self.sourceLayout)
    {
        return;
    }
    
    if (tag < 2)
    {
        [self.sourceLayout updateCanvasWidth:1280 height:720];
    } else if (tag < 4) {
        [self.sourceLayout updateCanvasWidth:1920 height:1080];
    }
    
    if ((tag % 2) == 0)
    {
        self.sourceLayout.frameRate = 60.0f;
    } else {
        self.sourceLayout.frameRate = 30.0f;
    }
}



-(NSMenu *) buildSourceMenu
{
    
    
    NSArray *sourceList = [self.sourceLayout sourceListOrdered];
    
    NSMenu *sourceListMenu = [[NSMenu allocWithZone:[NSMenu menuZone]] init];
    sourceListMenu.delegate = self;
    
    
    NSString *resTitle = [NSString stringWithFormat:@"%dx%d@%.2f", self.sourceLayout.canvas_width, self.sourceLayout.canvas_height, self.sourceLayout.frameRate];
    
    NSMenuItem *resItem = [[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:resTitle action:nil keyEquivalent:@""];
    
    NSMenu *resSubmenu = [[NSMenu allocWithZone:[NSMenu menuZone]] init];
    
    [LAYOUT_RESOLUTIONS enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        NSString *resOpt = obj;
        SEL menuAction = @selector(resolutionMenuAction:);
        
        if ([resOpt isEqualToString:@"Custom"])
        {
            menuAction = @selector(showLayoutSettings:);
        }
        
        
        NSMenuItem *item = [resSubmenu addItemWithTitle:resOpt action:menuAction keyEquivalent:@""];
        item.target = self;
        item.enabled = YES;
        item.tag = idx;
        
    }];

    [resItem setSubmenu:resSubmenu];
    
    
    
    [sourceListMenu insertItem:resItem atIndex:[sourceListMenu.itemArray count]];
    
    if (self.showTransitionToggle)
    {
        bool transitionState = self.controller.useTransitions;
        NSString *transitionTitle = @"Enable Transitions";
        if (transitionState)
        {
            transitionTitle = @"Disable Transitions";
        }
        
        NSMenuItem *transitionItem = [[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:transitionTitle action:@selector(doToggleTransitions:) keyEquivalent:@""];
        [transitionItem setTarget:self];
        [transitionItem setEnabled:YES];
        [sourceListMenu insertItem:transitionItem atIndex:[sourceListMenu.itemArray count]];

    }
    if (self.viewOnly)
    {
        return sourceListMenu;
    }
    
    NSMenuItem *midiItem = [[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:@"Midi Mapping" action:@selector(doLayoutMidi:) keyEquivalent:@""];
    [midiItem setTarget:self];
    [midiItem setEnabled:YES];
    
    [sourceListMenu insertItem:midiItem atIndex:[sourceListMenu.itemArray count]];

    [sourceListMenu insertItem:[NSMenuItem separatorItem] atIndex:[sourceListMenu.itemArray count]];
    
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
        
        NSMenuItem *libraryItem = [[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:@"Add to Library" action:@selector(addInputToLibrary:) keyEquivalent:@""];
        [libraryItem setEnabled:YES];
        [libraryItem setRepresentedObject:src];
        [libraryItem setTarget:self];
        [submenu addItem:libraryItem];

        NSMenuItem *cloneItem = [[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:@"Clone" action:@selector(cloneInputSource:) keyEquivalent:@""];
        [cloneItem setEnabled:YES];
        [cloneItem setRepresentedObject:src];
        [cloneItem setTarget:self];
        [submenu addItem:cloneItem];
        
        [srcItem setSubmenu:submenu];
        [srcItem setRepresentedObject:src];

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
    
    NSPoint tmp;
    
    tmp = [self convertPoint:theEvent.locationInWindow fromView:nil];

    
    if (self.viewOnly)
    {
        NSMenu *srcListMenu = [self buildSourceMenu];
        
        [srcListMenu popUpMenuPositioningItem:srcListMenu.itemArray.firstObject atLocation:tmp inView:self];

    }
    
    bool doDeep = YES;
    
    if (theEvent.modifierFlags & NSControlKeyMask)
    {
        doDeep = NO;
    }
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



- (void)mouseDragged:(NSEvent *)theEvent
{
    
    NSPoint tmp;
    
    
    NSPoint worldPoint;
    if (self.selectedSource)
    {
        
        if (!_inDrag)
        {
            NSRect curFrame = self.selectedSource.layoutPosition;
            
            [[self.sourceLayout.undoManager prepareWithInvocationTarget:self.sourceLayout] modifyUUID:self.selectedSource.uuid withBlock:^(InputSource *input) {
                if (input)
                {
                    [input updateSize:curFrame.size.width height:curFrame.size.height];
                    [input positionOrigin:curFrame.origin.x y:curFrame.origin.y];
                }

                
            }];
        }
        
        _inDrag = YES;
        tmp = [self convertPoint:theEvent.locationInWindow fromView:nil];
        
        
        worldPoint = [self realPointforWindowPoint:tmp];
        
        
        NSRect worldRect = NSIntegralRect(NSMakeRect(worldPoint.x, worldPoint.y , self.selectedSource.globalLayoutPosition.size.width, self.selectedSource.globalLayoutPosition.size.height));
        
        worldPoint = worldRect.origin;
        
        
        
        CGFloat dx, dy;
        dx = (worldPoint.x - self.selectedOriginDistance.x);
        dy = (worldPoint.y - self.selectedOriginDistance.y);
        
        
        
        [self adjustDeltas:&dx dy:&dy];

        
        self.selectedOriginDistance = worldPoint;
        

        if (self.isResizing)
        {
            
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
                
                if (self.resizeType & kResizeRight && dx)
                {
                    new_width = worldPoint.x - sPosition.origin.x;
                    
                    
                }
                
                if (self.resizeType & kResizeLeft && dx)
                {
                    new_width = (sPosition.origin.x+sPosition.size.width) - worldPoint.x;
                }
                
                
                if (self.resizeType & kResizeTop && dy)
                {
                    
                    new_height = worldPoint.y - sPosition.origin.y;
                }
                
                if (self.resizeType & kResizeBottom && dy)
                {
                    
                    new_height = NSMaxY(sPosition) - worldPoint.y;
                }
            
            
            
            
            
                [self.selectedSource updateSize:new_width height:new_height];

            
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
    
    NSPoint *c_snaps;
    int c_snap_size = 0;
    
    if (!self.selectedSource)
    {
        return;
    }

    if (superInput)
    {
        NSRect super_rect = superInput.globalLayoutPosition;
        
        c_lb_snap = super_rect.origin;
        c_rt_snap = NSMakePoint(NSMaxX(super_rect), NSMaxY(super_rect));
        c_center_snap = NSMakePoint(NSMidX(super_rect), NSMidY(super_rect));
        c_snaps = malloc(sizeof(NSPoint) * 3);
        c_snaps[0] = c_lb_snap;
        c_snaps[1] = c_rt_snap;
        c_snaps[2] = c_center_snap;
        c_snap_size = 3;
    } else {
    //define snap points. basically edges and the center of the canvas
        c_lb_snap = NSMakePoint(0, 0);
        c_rt_snap = NSMakePoint(self.sourceLayout.canvas_width, self.sourceLayout.canvas_height);
        c_center_snap = NSMakePoint(self.sourceLayout.canvas_width/2, self.sourceLayout.canvas_height/2);
        c_snap_size = 3;

        NSArray *srcs = self.sourceLayout.topLevelSourceList;
        
        
        c_snap_size += srcs.count*3;
        
        c_snaps = malloc(sizeof(NSPoint) * c_snap_size);
        c_snaps[0] = c_lb_snap;
        c_snaps[1] = c_rt_snap;
        c_snaps[2] = c_center_snap;
        
        int snap_idx = 3;
        for (InputSource *src in srcs)
        {
            if (src == self.selectedSource)
            {
                continue;
            }
            NSRect srect = src.globalLayoutPosition;
            c_snaps[snap_idx++] = srect.origin;
            c_snaps[snap_idx++] = NSMakePoint(NSMaxX(srect), NSMaxY(srect));
            c_snaps[snap_idx++] = NSMakePoint(NSMidX(srect), NSMidY(srect));
            
        }
    }
    
    

    
    //selected source snap points. edges, and center
    
    
    NSRect src_rect = self.selectedSource.globalLayoutPosition;

    NSPoint s_lb_snap = src_rect.origin;
    NSPoint s_rt_snap = NSMakePoint(src_rect.origin.x+src_rect.size.width, src_rect.origin.y+src_rect.size.height);
    NSPoint s_center_snap = NSMakePoint(src_rect.origin.x+roundf(src_rect.size.width/2), src_rect.origin.y+roundf(src_rect.size.height/2));
    
    
    NSPoint dist;
    
    NSPoint s_snaps[3] = {s_lb_snap, s_rt_snap, s_center_snap};
    
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
        for(int j=0; j < c_snap_size; j++)
        {
            
            NSPoint c_snap = c_snaps[j];
            dist = [self pointDistance:s_snap b:c_snap];
            if (*dx && !did_snap_x && (copysignf(dist.x, *dx) != dist.x) && (fabs(dist.x) < SNAP_THRESHOLD))
            {
                if ((s_snap.x != c_snap.x) && (_snap_x == -1))
                {
                    
                    *dx = -dist.x;
                    _snap_x = c_snap.x;
                    _snap_x_accum = 0;
                    did_snap_x = YES;
                }
            }
            
            if (*dy && !did_snap_y && (copysignf(dist.y, *dy) != dist.y) && (fabs(dist.y) < SNAP_THRESHOLD))
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
    
    if (c_snaps)
    {
        free(c_snaps);
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
        
        if (self.mousedSource)
        {
            [self stopHighlightingSource:self.mousedSource];
        } else {
            [self.controller resetInputTableHighlights];
        }
    }
}




-(void) highlightSource:(InputSource *)source
{
    if (!_highlightedSourceMap)
    {
        _highlightedSourceMap = [[NSMutableDictionary alloc] init];
    }
    
    
    NSString *srcUUID = source.uuid;
    
    InputSource *realSrc = [self.sourceLayout inputForUUID:srcUUID];
    if (!_highlightedSourceMap[srcUUID] && realSrc)
    {
        CSPreviewOverlayView *oview = [[CSPreviewOverlayView alloc] init];
        oview.renderControls = NO;
        oview.previewView = self;
        oview.parentSource = realSrc;
        _highlightedSourceMap[srcUUID] = oview;
    }
}


-(void)stopHighlightingSource:(InputSource *)source
{
    if (!_highlightedSourceMap)
    {
        _highlightedSourceMap = [[NSMutableDictionary alloc] init];
    }

    NSString *srcUUID = source.uuid;
    
    if (_highlightedSourceMap[srcUUID])
    {
        CSPreviewOverlayView *oview = _highlightedSourceMap[srcUUID];
        [oview removeFromSuperview];
        [_highlightedSourceMap removeObjectForKey:srcUUID];
    }
}

-(void)stopHighlightingAllSources
{
    if (!_highlightedSourceMap)
    {
        _highlightedSourceMap = [[NSMutableDictionary alloc] init];
    }
    for (NSString *key in _highlightedSourceMap)
    {
        CSPreviewOverlayView *oview = _highlightedSourceMap[key];
        if (oview)
        {
            [oview removeFromSuperview];
        }
    }
    [_highlightedSourceMap removeAllObjects];
}


- (IBAction)moveInputUp:(id)sender
{
    InputSource *toMove = nil;
    
    if (sender)
    {
        if ([sender isKindOfClass:[NSMenuItem class]])
        {
            NSMenuItem *item = (NSMenuItem *)sender;
            toMove = (InputSource *)item.representedObject;
        } else if ([sender isKindOfClass:[InputSource class]]) {
            toMove = (InputSource *)sender;
        } else if ([sender isKindOfClass:[NSString class]]) {
            toMove = [self.sourceLayout inputForUUID:sender];
        }
    }
    
    if (!toMove)
    {
        toMove = self.selectedSource;
    }

    if (toMove)
    {

        toMove.depth += 1;
        

        [[self.undoManager prepareWithInvocationTarget:self] moveInputDown:toMove.uuid];
        
    }
}


- (IBAction)moveInputDown:(id)sender
{
    InputSource *toMove = nil;
    
    if (sender)
    {
        if ([sender isKindOfClass:[NSMenuItem class]])
        {
            NSMenuItem *item = (NSMenuItem *)sender;
            toMove = (InputSource *)item.representedObject;
        } else if ([sender isKindOfClass:[InputSource class]]) {
            toMove = (InputSource *)sender;
        } else if ([sender isKindOfClass:[NSString class]]) {
            toMove = [self.sourceLayout inputForUUID:sender];
        }
    }
    
    if (!toMove)
    {
        toMove = self.selectedSource;
    }
    
    if (toMove)
    {
        toMove.depth -= 1;

        
        [[self.undoManager prepareWithInvocationTarget:self] moveInputUp:toMove.uuid];
        
    }
}


-(void)removeSourceTimer:(id)sender
{
    self.sourceLayout.layoutTimingSource = nil;
    
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



-(void)resetSourceAR:(id)sender
{
    InputSource *toReset = nil;
    
    if (sender)
    {
        if ([sender isKindOfClass:[NSMenuItem class]])
        {
            NSMenuItem *item = (NSMenuItem *)sender;
            toReset = (InputSource *)item.representedObject;
        } else if ([sender isKindOfClass:[InputSource class]]) {
            toReset = (InputSource *)sender;
        }
    }
    
    if (!toReset)
    {
        toReset = self.selectedSource;
    }
    
    if (toReset)
    {
        [((InputSource *)toReset) resetAspectRatio];
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


-(void)freezeInputSource:(id)sender
{
    InputSource *toFreeze = nil;
    
    if (sender)
    {
        if ([sender isKindOfClass:[NSMenuItem class]])
        {
            NSMenuItem *item = (NSMenuItem *)sender;
            toFreeze = (InputSource *)item.representedObject;
        } else if ([sender isKindOfClass:[InputSource class]]) {
            toFreeze = (InputSource *)sender;
        }
    }
    
    if (!toFreeze)
    {
        toFreeze = self.selectedSource;
    }
    
    if (toFreeze)
    {
        toFreeze.isFrozen = !toFreeze.isFrozen;
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


-(void)undoAddInput:(NSString *)uuid
{
    InputSource *toDelete = [self.sourceLayout inputForUUID:uuid];
    if (toDelete)
    {
        [self deleteInput:toDelete];
    }
}


-(void)addInputSourceWithInput:(InputSource *)source
{
    if (self.sourceLayout)
    {
        
        [self.sourceLayout addSource:source];
        [[self.undoManager prepareWithInvocationTarget:self] undoAddInput:source.uuid];
    }
}


- (IBAction)addInputSource:(id)sender
{
    
    if (self.sourceLayout)
    {
        InputSource *newSource = [[InputSource alloc] init];
        
        [self.sourceLayout addSource:newSource];
        [[self.undoManager prepareWithInvocationTarget:self] undoAddInput:newSource.uuid];
        [self spawnInputSettings:newSource atRect:NSZeroRect];
    }
}


-(void)undoEditsource:(NSData *)withData
{
    
    
    InputSource *restoredSource = [NSKeyedUnarchiver unarchiveObjectWithData:withData];
    InputSource *currentSource = [self.sourceLayout inputForUUID:restoredSource.uuid];
    if (currentSource)
    {
        [self.sourceLayout deleteSource:currentSource];
        NSData *curData = [NSKeyedArchiver archivedDataWithRootObject:currentSource];
        [[self.undoManager prepareWithInvocationTarget:self] undoEditsource:curData];
    }
    
    
    [self.sourceLayout addSource:restoredSource];
    
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
    
    //[[self.undoManager prepareWithInvocationTarget:self] undoEditsource:[NSKeyedArchiver archivedDataWithRootObject:forInput]];
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
        [self.undoManager setActionName:@"Auto Fit"];
    }
}


- (void)showLayoutSettings:(id)sender
{
    
    
    NSPoint tmp = [self convertPoint:[self.window mouseLocationOutsideOfEventStream] fromView:nil];
    
    NSRect spawnRect = NSMakeRect(tmp.x, tmp.y, 1.0f, 1.0f);
    
    if (!NSPointInRect(NSMakePoint(tmp.x, 0), self.bounds))
    {
        spawnRect = NSMakeRect(self.bounds.size.width-5, tmp.y, 1.0f, 1.0f);
    } else if (!NSPointInRect(NSMakePoint(0, tmp.y), self.bounds)) {
        spawnRect = NSMakeRect(tmp.x, 5.0f, 1.0f, 1.0f);
    }
    
    [self.controller openBuiltinLayoutPopover:self spawnRect:spawnRect forLayout:self.sourceLayout];
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
    
    
    [self openInputConfigWindow:configSource.uuid];

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
    

    _configWindowCascadePoint = NSZeroPoint;
    
    _snap_x = _snap_y = -1;
    
    int opts = (NSTrackingActiveAlways | NSTrackingInVisibleRect | NSTrackingMouseMoved | NSTrackingMouseEnteredAndExited);
    _trackingArea = [[NSTrackingArea alloc] initWithRect:[self bounds]
                                                 options:opts
                                                   owner:self
                                                userInfo:nil];
    
    [self addTrackingArea:_trackingArea];

    [self setWantsLayer:YES];
    
    self.layer.backgroundColor = CGColorCreateGenericRGB(0.184314f, 0.309804f, 0.309804f, 1);
    [self registerForDraggedTypes:@[@"cocoasplit.library.item"]];
    
}

-(NSDragOperation)draggingEntered:(id<NSDraggingInfo>)sender
{
    NSPasteboard *pboard;
    pboard = [sender draggingPasteboard];
    if ([pboard.types containsObject:@"cocoasplit.library.item"] && !self.viewOnly)
    {
        return NSDragOperationGeneric;
    }
    return NSDragOperationNone;
}

-(BOOL)performDragOperation:(id<NSDraggingInfo>)sender
{
    NSPasteboard *pboard;
    
    pboard = [sender draggingPasteboard];
    
    
    if ([pboard canReadItemWithDataConformingToTypes:@[@"cocoasplit.library.item"]])
    {
        
        NSArray *classes = @[[CSInputLibraryItem class]];
        NSArray *draggedObjects = [pboard readObjectsForClasses:classes options:@{}];
        
        for (CSInputLibraryItem *item in draggedObjects)
        {
            NSData *iData = item.inputData;
            
            NSKeyedUnarchiver *unarchiver = [[NSKeyedUnarchiver alloc] initForReadingWithData:iData];
            
            
            InputSource *iSrc = [unarchiver decodeObjectForKey:@"root"];
            [unarchiver finishDecoding];

            NSPoint mouseLoc = [NSEvent mouseLocation];
            
            NSRect rect = NSRectFromCGRect((CGRect){mouseLoc, CGSizeZero});
            
            mouseLoc = [self.window convertRectFromScreen:rect].origin;
            mouseLoc = [self convertPoint:mouseLoc fromView:nil];
            
            if (![self mouse:mouseLoc inRect:self.bounds])
            {
                return NO;
            }
            
            
            NSPoint worldPoint = [self realPointforWindowPoint:mouseLoc];


            [iSrc createUUID];
            
            [self.sourceLayout addSource:iSrc];
            //[iSrc positionOrigin:worldPoint.x y:worldPoint.y];
            iSrc.x_pos = worldPoint.x;
            iSrc.y_pos = worldPoint.y;
        }
        return YES;
    }
    return NO;
}


-(CALayer *)makeBackingLayer
{
    _glLayer = [CSPreviewGLLayer layer];
    _glLayer.doRender = self.isEditWindow;
    return _glLayer;
}


-(void)disablePrimaryRender
{
    _glLayer.doRender = NO;
}

-(void)enablePrimaryRender
{
    _glLayer.doRender = YES;
}


-(void)sourceWasDeleted:(NSNotification *)notification
{

    InputSource *toDel = notification.object;
    [self purgeConfigForInput:toDel];
}


-(void)purgeConfigForInput:(InputSource *)src
{
    NSString *uuid = src.uuid;
    
    [self stopHighlightingSource:src];
    
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


-(NSUndoManager *)windowWillReturnUndoManager:(NSWindow *)window
{
    return self.undoManager;
}

-(void)openInputConfigWindows:(NSArray *)uuids
{
    _configWindowCascadePoint = NSZeroPoint;
    for (NSString *uuid in uuids)
    {
        [self openInputConfigWindow:uuid];
    }
}


-(void)openInputConfigWindow:(NSString *)uuid
{
    
    
    InputSource *configSrc = [self.sourceLayout inputForUUID:uuid];
    
    if (!configSrc)
    {
        return;
    }
    
    InputPopupControllerViewController *newViewController = [[InputPopupControllerViewController alloc] init];
    
    newViewController.inputSource = configSrc;
    
    NSWindow *configWindow = [[NSWindow alloc] init];
    
    NSRect newFrame = [configWindow frameRectForContentRect:NSMakeRect(0.0f, 0.0f, newViewController.view.frame.size.width, newViewController.view.frame.size.height)];
    
    
    
    [configWindow setFrame:newFrame display:NO];
    if (NSEqualPoints(_configWindowCascadePoint, NSZeroPoint))
    {
        [configWindow center];
        
        _configWindowCascadePoint = NSMakePoint(NSMinX(configWindow.frame), NSMaxY(configWindow.frame));
    } else {
        _configWindowCascadePoint = [configWindow cascadeTopLeftFromPoint:_configWindowCascadePoint];
    }

    [configWindow setReleasedWhenClosed:NO];
    
    
    [configWindow.contentView addSubview:newViewController.view];
    configWindow.title = [NSString stringWithFormat:@"CocoaSplit Input (%@)", newViewController.inputSource.name];
    configWindow.delegate = self;
    
    configWindow.styleMask =  NSTitledWindowMask|NSClosableWindowMask|NSMiniaturizableWindowMask;

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
    
    
    [self.activeConfigWindows setObject:configWindow forKey:uuid];
    [self.activeConfigControllers setObject:newViewController forKey:uuid];

    [configWindow makeKeyAndOrderFront:nil];
    
    
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
