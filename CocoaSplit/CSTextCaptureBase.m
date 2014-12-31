//
//  CSTextSourceBase.m
//  CocoaSplit
//
//  Created by Zakk on 12/31/14.
//  Copyright (c) 2014 Zakk. All rights reserved.
//

#import "CSTextCaptureBase.h"


#import "CSAbstractCaptureDevice.h"

@implementation CSTextCaptureBase

@synthesize text = _text;

-(instancetype)init
{
    if (self = [super init])
    {
        self.foregroundColor = [NSColor whiteColor];
        self.allowScaling = NO;
        
        self.activeVideoDevice = [[CSAbstractCaptureDevice alloc] init];
        
        
        [self addObserver:self forKeyPath:@"propertiesChanged" options:NSKeyValueObservingOptionNew context:NULL];
        
        _font = [NSFont fontWithName:@"Helvetica" size:50];
        _fontAttributes = [NSDictionary dictionaryWithObject:[NSColor whiteColor] forKey:NSForegroundColorAttributeName];
    }
    
    return self;
}

-(void)encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeObject:self.text forKey:@"text"];
    [aCoder encodeObject:self.font forKey:@"font"];
    [aCoder encodeObject:self.fontAttributes forKey:@"fontAttributes"];
}


-(id)initWithCoder:(NSCoder *)aDecoder
{
    if (self = [self init])
    {
        _text = [aDecoder decodeObjectForKey:@"text"];
        NSFont *savedFont = [aDecoder decodeObjectForKey:@"font"];
        if (savedFont)
        {
            _font = savedFont;
            
        }
        
        
        
        NSDictionary *savedfontAttributes = [aDecoder decodeObjectForKey:@"fontAttributes"];
        if (savedfontAttributes)
        {
            _fontAttributes = savedfontAttributes;
        }
    }
    return self;
}


-(void)dealloc
{
    [self removeObserver:self forKeyPath:@"propertiesChanged"];
}



-(void) buildString
{
    if (self.text)
    {
        self.activeVideoDevice.uniqueID = self.text;
        
        NSMutableDictionary *strAttrs = [NSMutableDictionary dictionaryWithDictionary:self.fontAttributes];
        strAttrs[NSFontAttributeName] = self.font;
        _attribString = [[NSAttributedString alloc] initWithString:self.text attributes:strAttrs];
        
    }
    
    
}
-(NSString *)text
{
    return _text;
}


-(void)setText:(NSString *)text
{
    _text = text;
    self.captureName = text;
    
    [self renderText];
}


-(CIImage *)currentImage
{
    if (!_ciimage)
    {
        [self renderText];
    }
    
    //return _ciimage;
    
    CIImage *retimg = _ciimage;
    
    return retimg;
}


-(void)renderText
{
    
    
    
    if (!self.imageContext || !self.text)
    {
        return;
    }
    
    [self buildString];
    
    
    
    if (!_cgLayer || !NSEqualSizes(CGLayerGetSize(_cgLayer), _attribString.size))
    {
        CGLayerRelease(_cgLayer);
        
        _cgLayer = [self.imageContext createCGLayerWithSize:_attribString.size info:NULL];
        
    }
    
    CGContextRef layerCtx = CGLayerGetContext(_cgLayer);
    
    NSGraphicsContext *savedContext = [NSGraphicsContext currentContext];
    NSGraphicsContext *graphicsContext = [NSGraphicsContext graphicsContextWithGraphicsPort:layerCtx flipped:NO];
    [NSGraphicsContext setCurrentContext:graphicsContext];
    CGContextClearRect(layerCtx, NSMakeRect(0.0f, 0.0f, _attribString.size.width, _attribString.size.height));
    [_attribString drawInRect:NSMakeRect(0.0f, 0.0f, _attribString.size.width, _attribString.size.height)];
    
    _ciimage = [CIImage imageWithCGLayer:_cgLayer];
    
    [NSGraphicsContext setCurrentContext:savedContext];
    
    
}


+(NSString *)label
{
    return @"Text";
}


+ (NSSet *)keyPathsForValuesAffectingPropertiesChanged
{
    return [NSSet setWithObjects:@"text", @"font", @"fontAttributes", nil];
}


- (void) observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    
    if ([keyPath isEqualToString:@"propertiesChanged"])
    {
        [self renderText];
    }
    
}


@end

