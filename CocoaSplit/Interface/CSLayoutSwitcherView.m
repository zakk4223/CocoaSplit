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



@end

@implementation CSLayoutSwitcherView
@synthesize sourceLayout = _sourceLayout;





-(instancetype)init
{
    if (self = [super init])
    {
        [self setWantsLayer:YES];

        //self.layerContentsRedrawPolicy = NSViewLayerContentsRedrawOnSetNeedsDisplay;
    }
    
    return self;
}


-(CALayer *)makeBackingLayer
{
    CSPreviewGLLayer *newLayer = [CSPreviewGLLayer layer];
    newLayer.layoutManager = [CAConstraintLayoutManager layoutManager];
    return newLayer;
}

-(void)mouseDown:(NSEvent *)event
{
    self.layer.opacity = 0.5f;
    if (self.sourceLayout)
    {
        AppDelegate *appDel = NSApp.delegate;
        
        CaptureController *controller = appDel.captureController;
        if (event.modifierFlags & NSShiftKeyMask)
        {
            [controller toggleLayout:self.sourceLayout];
        } else {
            [controller switchToLayout:self.sourceLayout];
        }
    }

}

-(void)mouseUp:(NSEvent *)event
{
    self.layer.opacity = 1.0f;
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
        CSPreviewGLLayer *newLayer = (CSPreviewGLLayer *)self.layer;
        newLayer.borderColor = [NSColor lightGrayColor].CGColor;
        newLayer.borderWidth = 2.0f;
        newLayer.doRender = YES;
        newLayer.renderer = [[LayoutRenderer alloc] init];
        newLayer.renderer.layout = _sourceLayout;
        [_sourceLayout restoreSourceList:nil];
        [_sourceLayout addObserver:self forKeyPath:@"in_live" options:NSKeyValueObservingOptionNew context:NULL];
        [_sourceLayout addObserver:self forKeyPath:@"in_staging" options:NSKeyValueObservingOptionNew context:NULL];

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

            _textView.backgroundColor = [NSColor blackColor];
            _textView.alphaValue = 0.5;
            _textView.editable = NO;
            _textView.textColor = [NSColor whiteColor];
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
        
        
        [self setNeedsDisplay:YES];
        
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


    }
}

-(void)dealloc
{
    if (self.sourceLayout)
    {
        [self.sourceLayout removeObserver:self forKeyPath:@"in_live"];
        [self.sourceLayout removeObserver:self forKeyPath:@"in_staging"];

    }
}


-(void)layout
{
    if (_textView)
    {
        
        _textView.string = self.sourceLayout.name;
        NSRect tFrame = _textView.frame;
        NSSize tSize = [_textView intrinsicContentSize];
        
        
        tFrame.origin.x = NSMidX(self.bounds) - tSize.width/2;
        tFrame.origin.y = 5.0f;
        tFrame.size.width = tSize.width;
        tFrame.size.height = tSize.height;
        [_textView setFrame:tFrame];
    }
}
@end
