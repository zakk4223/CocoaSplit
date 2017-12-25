//
//  CSSequenceActivatorView.m
//  CocoaSplit
//
//  Created by Zakk on 3/12/17.
//  Copyright © 2017 Zakk. All rights reserved.
//

#import "CSSequenceActivatorView.h"
#import "CSSequenceActivatorViewController.h"
#import "CaptureController.h"

@implementation CSSequenceTextView
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

@implementation CSSequenceActivatorView
@synthesize layoutSequence = _layoutSequence;
@synthesize isQueued = _isQueued;



-(instancetype) init
{
    if (self = [super init])
    {
        self.wantsLayer = YES;
    }
    return self;
}




-(CALayer *)makeBackingLayer
{
    
    CALayer *newLayer = [CALayer layer];
    newLayer.backgroundColor = [NSColor controlColor].CGColor;
    return newLayer;
}


-(void)setIsQueued:(bool)isQueued
{
    _isQueued = isQueued;
    [self setNeedsLayout:YES];
}

-(bool)isQueued
{
    return _isQueued;
}


-(void)rightMouseDown:(NSEvent *)event
{
    [self.controller showSequenceMenu:event forView:self];
}
     



-(void)mouseDown:(NSEvent *)event
{
    
    [self.controller sequenceViewClicked:event forView:self];
    
}


-(CSLayoutSequence *)layoutSequence
{
    return _layoutSequence;
}


-(void)setLayoutSequence:(CSLayoutSequence *)layoutSequence
{
    
    if (_layoutSequence)
    {
        [_layoutSequence removeObserver:self forKeyPath:@"name"];
        [_layoutSequence removeObserver:self forKeyPath:@"lastRunUUID"];

    }
    _layoutSequence = layoutSequence;
    if (_layoutSequence)
    {
        
        CALayer *newLayer = self.layer;
        
        newLayer.borderColor = [NSColor lightGrayColor].CGColor;
        newLayer.borderWidth = 2.0f;
        
        [_layoutSequence addObserver:self forKeyPath:@"name" options:NSKeyValueObservingOptionNew context:NULL];

        [_layoutSequence addObserver:self forKeyPath:@"lastRunUUID" options:NSKeyValueObservingOptionNew context:NULL];
        
    
        if (!_textView)
        {
            

            _textView = [[CSSequenceTextView alloc] initWithFrame:NSMakeRect(50,50,50,50)];
            [_textView setWantsLayer:YES];
            _textView.layer.cornerRadius = 5;
            
            _textView.backgroundColor = [NSColor colorWithRed:0 green:0 blue:0 alpha:0];
            
            _textView.editable = NO;
            _textView.selectable = NO;
            
            _textView.textColor = [NSColor blackColor];
            
            
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
            _textView.string = _layoutSequence.name;
            
            [_textView sizeToFit];
            
            
        }
        
        
        [self setNeedsDisplay:YES];
        
    }
}


-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context
{
    
    [self setNeedsLayout:YES];
    
}



-(void)layout
{
    if (_textView)
    {
        
        _textView.string = self.layoutSequence.name;
        NSRect tFrame = _textView.frame;
        NSSize tSize = [_textView intrinsicContentSize];
        CGFloat startFontSize = _textView.font.pointSize;
        if (self.isQueued || self.layoutSequence.lastRunUUID)
        {
            self.layer.opacity = 0.5f;
        } else {
            self.layer.opacity = 1.0f;
        }
        while (tSize.width > self.bounds.size.width)
        {
            _textView.font = [NSFont userFontOfSize:--startFontSize];
            tSize = [_textView intrinsicContentSize];
        }
        
        tFrame.origin.x = NSMidX(self.bounds) - tSize.width/2;
        tFrame.origin.y = NSMidY(self.bounds) - tSize.height/2;
        
        tFrame.size.width = tSize.width;
        tFrame.size.height = tSize.height;
        [_textView setFrame:tFrame];
    }
}

-(void)dealloc
{
    if (_layoutSequence)
    {
        [_layoutSequence removeObserver:self forKeyPath:@"name"];
        [_layoutSequence removeObserver:self forKeyPath:@"lastRunUUID"];

    }
}
@end
