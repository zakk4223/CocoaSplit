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
        self.allowDedup = NO;
        self.alignmentMode = kCAAlignmentNatural;
    }
    
    return self;
}

-(CALayer *)createNewLayer
{
    CATextLayer *newLayer = [CATextLayer layer];
    newLayer.string = _attribString;
    
    newLayer.bounds = CGRectMake(0.0, 0.0, _attribString.size.width, _attribString.size.height);
    newLayer.alignmentMode = self.alignmentMode;
    return newLayer;
}


-(void)encodeWithCoder:(NSCoder *)aCoder
{
    [super encodeWithCoder:aCoder];
    [aCoder encodeObject:self.text forKey:@"text"];
    [aCoder encodeObject:self.font forKey:@"font"];
    [aCoder encodeObject:self.fontAttributes forKey:@"fontAttributes"];
}


-(instancetype)initWithCoder:(NSCoder *)aDecoder
{
    if (self = [super initWithCoder:aDecoder])
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
    
    [self buildString];
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
        
        if ([self.alignmentMode isEqualToString:kCAAlignmentCenter] || [self.alignmentMode isEqualToString:kCAAlignmentRight])
        {
            self.allowScaling = YES;
        } else {
            self.allowScaling = NO;
        }

        [self updateLayersWithBlock:^(CALayer *layer) {
            layer.bounds = CGRectMake(0.0, 0.0, _attribString.size.width, _attribString.size.height);
            ((CATextLayer *)layer).string = _attribString;
            ((CATextLayer *)layer).alignmentMode = self.alignmentMode;
            
            [CATransaction commit];
 
        }];
        
        

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
    
    [self buildString];
}


+(NSString *)label
{
    return @"Text";
}


+ (NSSet *)keyPathsForValuesAffectingPropertiesChanged
{
    return [NSSet setWithObjects:@"text", @"font", @"fontAttributes", @"alignmentMode", nil];
}


- (void) observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    
    if ([keyPath isEqualToString:@"propertiesChanged"])
    {
        [self buildString];
    }
    
}


@end

