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

-(void)rightMouseDown:(NSEvent *)event
{
    [self.controller showSequenceMenu:event forView:self];
}
     

-(void)handleScriptException:(NSException *)exception
{
    
    NSDictionary *errorUserInfo = @{
                                    NSLocalizedDescriptionKey: exception.reason,
                                    NSLocalizedFailureReasonErrorKey: exception.name
                                    };
    
    NSError *pyError = [NSError errorWithDomain:@"zakk.lol.cocoasplit" code:-35 userInfo:errorUserInfo];
    NSAlert *errAlert = [NSAlert alertWithError:pyError];
    dispatch_async(dispatch_get_main_queue(), ^{
        [errAlert beginSheetModalForWindow:[NSApp mainWindow] completionHandler:nil];
        
    });
}


-(void)mouseDown:(NSEvent *)event
{
    self.layer.opacity = 0.5f;
    
    if (self.layoutSequence)
    {
        CaptureController *captureController = [CaptureController sharedCaptureController];
        [self.layoutSequence runSequenceForLayout:captureController.selectedLayout withCompletionBlock:nil withExceptionBlock:^(NSException *exception) {
            [self handleScriptException:exception];
        }];
    }
    /*
    if (self.layoutSequence)
    {
        AppDelegate *appDel = NSApp.delegate;
        
        CaptureController *controller = appDel.captureController;
        if (event.modifierFlags & NSShiftKeyMask)
        {
            [controller toggleLayout:self.sourceLayout];
        } else {
            [controller switchToLayout:self.sourceLayout];
        }
    }*/
    
}

-(void)mouseUp:(NSEvent *)event
{
    self.layer.opacity = 1.0f;
}

-(CSLayoutSequence *)layoutSequence
{
    return _layoutSequence;
}


-(void)setLayoutSequence:(CSLayoutSequence *)layoutSequence
{
    _layoutSequence = layoutSequence;
    if (_layoutSequence)
    {
        
        CALayer *newLayer = self.layer;
        
        newLayer.borderColor = [NSColor lightGrayColor].CGColor;
        newLayer.borderWidth = 2.0f;
        
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




-(void)layout
{
    if (_textView)
    {
        
        _textView.string = self.layoutSequence.name;
        NSRect tFrame = _textView.frame;
        NSSize tSize = [_textView intrinsicContentSize];
        CGFloat startFontSize = _textView.font.pointSize;
        
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
@end
