//
//  TextCapture.m
//  CocoaSplit
//
//  Created by Zakk on 7/23/14.
//  Copyright (c) 2014 Zakk. All rights reserved.
//

#import "TextCapture.h"
#import "CSAbstractCaptureDevice.h"

@implementation TextCapture

@synthesize text = _text;

-(id)init
{
    if (self = [super init])
    {
        self.fontSize = 14.0f;
        self.foregroundColor = [NSColor whiteColor];
        self.allowScaling = NO;
        _scroll_Xadjust = 0.0f;
        _scroll_Yadjust = 0.0f;
        self.scrollXSpeed = 0.0f;
        self.scrollYSpeed = 0.0f;
        
        self.activeVideoDevice = [[CSAbstractCaptureDevice alloc] init];
        
        
        [self addObserver:self forKeyPath:@"propertiesChanged" options:NSKeyValueObservingOptionNew context:NULL];
        
        offsetFilter = [CIFilter filterWithName:@"TextureWrapPluginFilter"];
        [offsetFilter setDefaults];
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
    [aCoder encodeFloat:self.scrollXSpeed forKey:@"scrollXSpeed"];
    [aCoder encodeFloat:self.scrollYSpeed forKey:@"scrollYSpeed"];
    
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
        self.scrollXSpeed = [aDecoder decodeFloatForKey:@"scrollXSpeed"];
        self.scrollYSpeed = [aDecoder decodeFloatForKey:@"scrollYSpeed"];
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
    
    if (self.scrollXSpeed || self.scrollYSpeed)
    {
        [offsetFilter setValue:@(_scroll_Xadjust) forKey:@"inputXOffset"];
        [offsetFilter setValue:@(_scroll_Yadjust) forKeyPath:@"inputYOffset"];
        [offsetFilter setValue:_ciimage forKey:kCIInputImageKey];        
        retimg = [[offsetFilter valueForKey:kCIOutputImageKey] imageByCroppingToRect:NSInsetRect(_ciimage.extent, 0.1f, 0.1f)];
        _scroll_Xadjust += self.scrollXSpeed;
        _scroll_Yadjust += self.scrollYSpeed;
        if (fabs(_scroll_Xadjust) >= _ciimage.extent.size.width)
        {
            _scroll_Xadjust = 0.0f;
        }
        
        if (fabs(_scroll_Yadjust) >= _ciimage.extent.size.height)
        {
            _scroll_Yadjust = 0.0f;
        }
    }
    
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
