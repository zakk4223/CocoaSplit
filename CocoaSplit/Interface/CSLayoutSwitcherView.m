//
//  CSLayoutSwitcherView.m
//  CocoaSplit
//
//  Created by Zakk on 3/6/17.
//  Copyright © 2017 Zakk. All rights reserved.
//

#import "CSLayoutSwitcherView.h"
#import "CSPreviewGLLayer.h"
#import "AppDelegate.h"
#import "CSLayoutSwitcherViewController.h"
#import "CSLayoutRecorder.h"
#import "PreviewView.h"

@implementation CSSTextView

- (NSSize) intrinsicContentSize {
    NSTextContainer* textContainer = [self textContainer];
    NSLayoutManager* layoutManager = [self layoutManager];
    [layoutManager ensureLayoutForTextContainer: textContainer];
    
    return [layoutManager usedRectForTextContainer: textContainer].size;
}

- (void) didChangeText {
    [super didChangeText];
    [self invalidateIntrinsicContentSize];
}


-(NSView *)hitTest:(NSPoint)point
{
    return nil;
}


@end

@implementation CSLayoutSwitcherView
@synthesize sourceLayout = _sourceLayout;






-(instancetype)initWithIsSwitcherView:(bool)isSwitcherView
{
    if (self = [super init])
    {

        self.isSwitcherView = isSwitcherView;
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(themeChanged:) name:CSNotificationThemeChanged object:nil];
        [self setWantsLayer:YES];

        //self.layerContentsRedrawPolicy = NSViewLayerContentsRedrawOnSetNeedsDisplay;
    }
    
    return self;
}



-(void)themeChanged:(NSNotification *)notification
{
    [self setupColors];
}


-(CALayer *)makeBackingLayer
{

    CALayer *newLayer;
    
    if (self.isSwitcherView)
    {
        newLayer = [CSPreviewGLLayer layer];
    } else {
        bool darkMode = [CaptureController sharedCaptureController].useDarkMode;
        newLayer = [CALayer layer];
        if (darkMode)
        {
            newLayer.backgroundColor = [NSColor blackColor].CGColor;
        } else {
            newLayer.backgroundColor = [NSColor controlColor].CGColor;
        }

        newLayer.cornerRadius = 2.5f;
    }
    return newLayer;
}


-(BOOL)wantsUpdateLayer
{
    return YES;
}


-(void)rightMouseDown:(NSEvent *)event
{
    [self.controller showLayoutMenu:event forView:self];
}


-(void)mouseDown:(NSEvent *)event
{
    self.layer.opacity = 0.5f;
    if (self.sourceLayout)
    {
        AppDelegate *appDel = NSApp.delegate;
        
        CaptureController *controller = appDel.captureController;
        
        SourceLayout *useLayout = controller.activePreviewView.sourceLayout;
        
        if (event.modifierFlags & NSCommandKeyMask)
        {
            useLayout = controller.selectedLayout;
        }
        
        
        if (event.modifierFlags & NSShiftKeyMask)
        {
            [controller toggleLayout:self.sourceLayout usingLayout:useLayout];
        } else {
            [controller switchToLayout:self.sourceLayout usingLayout:useLayout];
        }
    }

}


-(void)mouseUp:(NSEvent *)event
{
    self.layer.opacity = 1.0f;
}



-(void)setupColors
{
    
    bool darkMode = [CaptureController sharedCaptureController].useDarkMode;
    
    if (self.isSwitcherView)
    {
        _textView.textColor = [NSColor whiteColor];
        _textView.backgroundColor = [NSColor blackColor];
        _textView.alphaValue = 0.5;
    } else {
        bool darkMode = [CaptureController sharedCaptureController].useDarkMode;
        
        if (darkMode)
        {
            _textView.backgroundColor = [NSColor colorWithRed:1 green:1 blue:1 alpha:0];
            _textView.textColor = [NSColor whiteColor];
        } else {
            _textView.backgroundColor = [NSColor colorWithRed:0 green:0 blue:0 alpha:0];
            _textView.textColor = [NSColor blackColor];
        }
    }
    
    if (!self.isSwitcherView)
    {
        
        if (darkMode)
        {
            self.layer.backgroundColor = [NSColor blackColor].CGColor;
        } else {
            self.layer.backgroundColor = [NSColor controlColor].CGColor;
        }
    }
}


-(SourceLayout *)sourceLayout
{
    return _sourceLayout;
}


-(void)setSourceLayout:(SourceLayout *)sourceLayout
{
    _sourceLayout = sourceLayout;
    if (_sourceLayout)
    {
    
        CALayer *newLayer = self.layer;
        
        newLayer.borderColor = [NSColor lightGrayColor].CGColor;
        newLayer.borderWidth = 2.0f;
        if (self.isSwitcherView)
        {
            CSPreviewGLLayer *glLayer = (CSPreviewGLLayer *)newLayer;
            glLayer.doRender = YES;
            glLayer.renderer = [[LayoutRenderer alloc] init];
            glLayer.renderer.layout = _sourceLayout;
            [_sourceLayout restoreSourceList:nil];
        }
        
        [_sourceLayout addObserver:self forKeyPath:@"in_live" options:NSKeyValueObservingOptionNew context:NULL];
        [_sourceLayout addObserver:self forKeyPath:@"in_staging" options:NSKeyValueObservingOptionNew context:NULL];
        [_sourceLayout addObserver:self forKeyPath:@"audioData" options:NSKeyValueObservingOptionNew context:NULL];
        [_sourceLayout addObserver:self forKeyPath:@"recorder.defaultRecordingActive" options:NSKeyValueObservingOptionNew context:NULL];
        [_sourceLayout addObserver:self forKeyPath:@"name" options:NSKeyValueObservingOptionNew context:NULL];




        if (_sourceLayout.in_live)
        {
            newLayer.borderColor = [NSColor redColor].CGColor;
            newLayer.borderWidth = 4.0f;
        }
        
        if (_sourceLayout.in_staging)
        {
            newLayer.borderColor = [NSColor greenColor].CGColor;
            newLayer.borderWidth = 4.0f;
        }
        
        if (_sourceLayout.in_staging && _sourceLayout.in_live)
        {
            newLayer.borderColor = [NSColor yellowColor].CGColor;
            newLayer.borderWidth = 4.0f;
        }

        
        
        
        if (!_textView)
        {

            _textView = [[CSSTextView alloc] initWithFrame:NSMakeRect(50,50,50,50)];
            [_textView setWantsLayer:YES];
            _textView.layer.cornerRadius = 5;


            _textView.editable = NO;
            _textView.selectable = NO;
            
            [self setupColors];
            
 
            _textView.font = [NSFont userFontOfSize:20.0f];
            [_textView.textContainer setContainerSize:NSMakeSize(1.0e6, 1.0e6)];

            [_textView.textContainer setWidthTracksTextView:NO];
            [_textView.textContainer setHeightTracksTextView:YES];

            _textView.maxSize = NSMakeSize(FLT_MAX, FLT_MAX);
            _textView.minSize = NSMakeSize(0, 0);

        
            [_textView setHorizontallyResizable:YES];
            [_textView setVerticallyResizable:NO];

            [self addSubview:_textView];
            _textView.translatesAutoresizingMaskIntoConstraints = NO;
            _textView.string = _sourceLayout.name;
            
            [_textView sizeToFit];


        }
        
        
        if (!_recordImageView)
        {
            _recordImageView = [[NSImageView alloc] init];
            _recordImageView.image = [NSImage imageNamed:@"Record_Icon"];
            _recordImageView.editable = NO;
            _recordImageView.hidden = YES;
            _recordImageView.frame = NSMakeRect(NSMaxX(self.frame)-16,4,16,16);
            [self addSubview:_recordImageView];
            if (_sourceLayout.recorder && _sourceLayout.recorder.defaultRecordingActive)
            {
                _recordImageView.hidden = NO;
            }

        }
        
        
        [self setNeedsDisplay:YES];
        [self setNeedsLayout:YES];
        
    }
}

-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSString *,id> *)change context:(void *)context
{

    if ([keyPath isEqualToString:@"in_live"] || [keyPath isEqualToString:@"in_staging"])
    {
        
        self.layer.borderColor = [NSColor grayColor].CGColor;
        self.layer.borderWidth = 2.0f;
        if (_sourceLayout.in_live)
        {
            self.layer.borderColor = [NSColor redColor].CGColor;
            self.layer.borderWidth = 4.0f;
        }
        
        if (_sourceLayout.in_staging)
        {
            self.layer.borderColor = [NSColor greenColor].CGColor;
            self.layer.borderWidth = 4.0f;
        }
        
        if (_sourceLayout.in_staging && _sourceLayout.in_live)
        {
            self.layer.borderColor = [NSColor yellowColor].CGColor;
            self.layer.borderWidth = 4.0f;
        }
    } else if ([keyPath isEqualToString:@"audioData"]) {
    } else if ([keyPath isEqualToString:@"recorder.defaultRecordingActive"]) {
    
        if (_sourceLayout.recorder && _sourceLayout.recorder.defaultRecordingActive)
        {
            _recordImageView.hidden = NO;
        } else {
            _recordImageView.hidden = YES;
        }
    }
    
    [self.layer setNeedsDisplay];
    [self setNeedsLayout:YES];
    
    
    
}

-(void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    if (self.sourceLayout)
    {
        [self.sourceLayout removeObserver:self forKeyPath:@"in_live"];
        [self.sourceLayout removeObserver:self forKeyPath:@"in_staging"];
        [self.sourceLayout removeObserver:self forKeyPath:@"audioData"];
        [self.sourceLayout removeObserver:self forKeyPath:@"recorder.defaultRecordingActive"];
        [self.sourceLayout removeObserver:self forKeyPath:@"name"];
    }
}


-(void)layout
{
    
    [super layout];
    if (_recordImageView)
    {
        [_recordImageView setFrame:NSMakeRect(4,NSMaxY(self.bounds)-24,16,16)];

    }
    
    
    if (_textView)
    {

        _textView.string = self.sourceLayout.name;
        NSRect tFrame = _textView.frame;
        NSSize tSize = [_textView intrinsicContentSize];
        CGFloat startFontSize = _textView.font.pointSize;
        
        
        while (tSize.width > self.bounds.size.width)
        {
            _textView.font = [NSFont userFontOfSize:--startFontSize];
            tSize = [_textView intrinsicContentSize];
        }
        
        tFrame.origin.x = NSMidX(self.bounds) - tSize.width/2;
        if (self.isSwitcherView)
        {
            tFrame.origin.y = 5.0f;
        } else {
            tFrame.origin.y = NSMidY(self.bounds) - tSize.height/2;
        }
        
        tFrame.size.width = tSize.width;
        tFrame.size.height = tSize.height;
        [_textView setFrame:tFrame];
    }
}
@end
