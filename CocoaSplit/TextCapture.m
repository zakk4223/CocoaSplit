//
//  TextCapture.m
//  CocoaSplit
//
//  Created by Zakk on 7/23/14.
//  Copyright (c) 2014 Zakk. All rights reserved.
//

#import "TextCapture.h"

@implementation TextCapture

@synthesize text = _text;

-(id)init
{
    if (self = [super init])
    {
        self.fontSize = 14.0f;
        self.foregroundColor = [NSColor whiteColor];
        
        [self addObserver:self forKeyPath:@"propertiesChanged" options:NSKeyValueObservingOptionNew context:NULL];

    }
    
    return self;
}

-(void)encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeObject:self.text forKey:@"text"];
    [aCoder encodeDouble:self.fontSize forKey:@"fontSize"];
    [aCoder encodeBool:self.isItalic forKey:@"isItalic"];
    [aCoder encodeBool:self.isBold forKey:@"isBold"];
    [aCoder encodeBool:self.isUnderline forKey:@"isUnderline"];
    [aCoder encodeBool:self.isStrikethrough forKey:@"isStrikethrough"];
    [aCoder encodeObject:self.foregroundColor forKey:@"foregroundColor"];
}


-(id)initWithCoder:(NSCoder *)aDecoder
{
    if (self = [self init])
    {
        self.text = [aDecoder decodeObjectForKey:@"text"];
        self.fontSize = [aDecoder decodeDoubleForKey:@"fontSize"];
        self.isItalic = [aDecoder decodeBoolForKey:@"isItalic"];
        self.isBold = [aDecoder decodeBoolForKey:@"isBold"];
        self.isUnderline = [aDecoder decodeBoolForKey:@"isUnderline"];
        self.isStrikethrough = [aDecoder decodeBoolForKey:@"isStrikethrough"];
        if ([aDecoder containsValueForKey:@"foregroundColor"])
        {
            self.foregroundColor = [aDecoder decodeObjectForKey:@"foregroundColor"];
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
        NSFont *myfont = [NSFont fontWithName:@"Helvetica" size:self.fontSize];
        if (self.isItalic)
        {
            myfont = [[NSFontManager sharedFontManager] convertFont:myfont toHaveTrait:NSFontItalicTrait];
        }
        
        if (self.isBold)
        {
            myfont = [[NSFontManager sharedFontManager] convertFont:myfont toHaveTrait:NSFontBoldTrait];
        }
        
        NSMutableDictionary *strAttrs = [[NSMutableDictionary alloc] init];
        
        strAttrs[NSForegroundColorAttributeName] = self.foregroundColor;
        strAttrs[NSFontAttributeName] = myfont;
        if (self.isUnderline)
        {
            strAttrs[NSUnderlineStyleAttributeName] = @(NSUnderlineStyleSingle);
        }
        
        if (self.isStrikethrough)
        {
            strAttrs[NSStrikethroughStyleAttributeName] = @(NSUnderlineStyleSingle);
        }
        
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
    
    [self renderText];
}
                     
                     
-(CIImage *)currentImage
{
    if (!_ciimage)
    {
        [self renderText];
    }
    
    return _ciimage;
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


+ (NSSet *)keyPathsForValuesAffectingPropertiesChanged
{
    return [NSSet setWithObjects:@"text", @"fontSize", @"isItalic", @"isBold", @"isUnderline", @"isStrikethrough", @"foregroundColor", nil];
}


- (void) observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    
    
    
    if ([keyPath isEqualToString:@"propertiesChanged"])
    {
        [self renderText];
    }
    
}


@end
