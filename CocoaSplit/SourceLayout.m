//
//  SourceLayout.m
//  CocoaSplit
//
//  Created by Zakk on 8/31/14.
//  Copyright (c) 2014 Zakk. All rights reserved.
//

#import "SourceLayout.h"
#import "InputSource.h"


@implementation SourceLayout


@synthesize isActive = _isActive;


-(instancetype) init
{
    if (self = [super init])
    {
        _sourceDepthSorter = [[NSSortDescriptor alloc] initWithKey:@"depth" ascending:YES];
        _sourceUUIDSorter = [[NSSortDescriptor alloc] initWithKey:@"uuid" ascending:YES];
        self.sourceCache = [[SourceCache alloc] init];
        _frameRate = 30;
        _canvas_height = 720;
        _canvas_width = 1280;
        _fboTexture = 0;
        _rFbo = 0;
        self.rootLayer = [CALayer layer];
        self.rootLayer.bounds = CGRectMake(0, 0, _canvas_width, _canvas_height);
        self.rootLayer.anchorPoint = CGPointMake(0.0, 0.0);
        self.rootLayer.position = CGPointMake(0.0, 0.0);
        self.rootLayer.masksToBounds = YES;
        self.rootLayer.backgroundColor = CGColorCreateGenericRGB(0, 0, 0, 1);
        //self.rootLayer.geometryFlipped = YES;

        _rootSize = NSMakeSize(_canvas_width, _canvas_height);
        
    }
    
    return self;
}



-(id)copyWithZone:(NSZone *)zone
{
    SourceLayout *newLayout = [[SourceLayout allocWithZone:zone] init];
    
    newLayout.savedSourceListData = self.savedSourceListData;
    newLayout.name = self.name;
    newLayout.canvas_height = self.canvas_height;
    newLayout.canvas_width = self.canvas_width;
    newLayout.frameRate = self.frameRate;
    newLayout.isActive = NO;
    
    return newLayout;
}



 
-(void) encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeObject:self.name forKey:@"name"];
    
    if (self.isActive)
    {
        [self saveSourceList];
    }
    
    
    [aCoder encodeObject:self.savedSourceListData forKey:@"savedSourceData"];
    [aCoder encodeInt:self.canvas_width forKey:@"canvas_width"];
    [aCoder encodeInt:self.canvas_height forKey:@"canvas_height"];
    [aCoder encodeFloat:self.frameRate forKey:@"frameRate"];
    
    
}



-(id) initWithCoder:(NSCoder *)aDecoder
{
    if (self = [self init])
    {
        self.name = [aDecoder decodeObjectForKey:@"name"];
        self.savedSourceListData = [aDecoder decodeObjectForKey:@"savedSourceData"];
        if ([aDecoder containsValueForKey:@"canvas_height"])
        {
            self.canvas_height = [aDecoder decodeIntForKey:@"canvas_height"];
        }
        
        if ([aDecoder containsValueForKey:@"canvas_width"])
        {
            self.canvas_width = [aDecoder decodeIntForKey:@"canvas_width"];
        }
        
        if ([aDecoder containsValueForKey:@"frameRate"])
        {
            self.frameRate = [aDecoder decodeFloatForKey:@"frameRate"];
        }
        
    }
    
    return self;
}


-(NSArray *)sourceListOrdered
{
    NSArray *listCopy = [self.sourceList sortedArrayUsingDescriptors:@[_sourceDepthSorter, _sourceUUIDSorter]];
    return listCopy;
}


-(InputSource *)findSource:(NSPoint)forPoint withExtra:(float)withExtra
{
    /* invert the point due to layer rendering inversion/weirdness */
    
    CGPoint newPoint = CGPointMake(forPoint.x, self.canvas_height-forPoint.y);
    CALayer *foundLayer = [self.rootLayer hitTest:newPoint];
    
    if (foundLayer)
    {
        return foundLayer.delegate;
    }
    
    
    return nil;

}
-(InputSource *)findSource:(NSPoint)forPoint
{
    
    return [self findSource:forPoint withExtra:0];
}


-(void) saveSourceList
{
    
    self.savedSourceListData = [NSKeyedArchiver archivedDataWithRootObject:self.sourceList];
}


-(void)restoreSourceListForSelfGoLive
{
    
    if (self.savedSourceListData)
    {
        
        self.transitionLayer = [CALayer layer];
        
        NSKeyedUnarchiver *unarchiver = [[NSKeyedUnarchiver alloc] initForReadingWithData:self.savedSourceListData];
        
        [unarchiver setDelegate:self];
        
        self.transitionSourceList = [unarchiver decodeObjectForKey:@"root"];
        [unarchiver finishDecoding];
        
    }
    
    if (!self.transitionSourceList)
    {
        self.transitionSourceList = [NSMutableArray array];
    }
    
    for(InputSource *src in self.transitionSourceList)
    {
        src.sourceLayout = self;
        src.is_live = self.isActive;
        
        [self.transitionLayer addSublayer:src.layer];
    }
    

    self.transitionNeeded = YES;
    
    [CATransaction commit];
}


-(void)restoreSourceList
{
    
    if (self.savedSourceListData)
    {

        self.rootLayer.sublayers = [NSArray array];
        
        NSKeyedUnarchiver *unarchiver = [[NSKeyedUnarchiver alloc] initForReadingWithData:self.savedSourceListData];
        
        [unarchiver setDelegate:self];
        
        for(InputSource *src in self.sourceList)
        {
            [src willDelete];
            [src.layer removeFromSuperlayer];
        }
        
        self.sourceList = [unarchiver decodeObjectForKey:@"root"];
        [unarchiver finishDecoding];
        
    }
    
    if (!self.sourceList)
    {
        self.sourceList = [NSMutableArray array];
    }
    
    for(InputSource *src in self.sourceList)
    {
        src.sourceLayout = self;
        src.is_live = self.isActive;
        
        [self.rootLayer addSublayer:src.layer];
    }

    [CATransaction commit];
    
}

-(void)deleteSource:(InputSource *)delSource
{
    
    [delSource willDelete];
    
    [self.sourceList removeObject:delSource];
    [delSource.layer removeFromSuperlayer];

    [CATransaction commit];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:CSNotificationInputDeleted  object:delSource userInfo:nil];

}



-(void) addSource:(InputSource *)newSource
{
    newSource.sourceLayout = self;
    newSource.is_live = self.isActive;
    
    [self.sourceList addObject:newSource];
    [self.rootLayer addSublayer:newSource.layer];
    [CATransaction commit];
    [[NSNotificationCenter defaultCenter] postNotificationName:CSNotificationInputAdded object:newSource userInfo:nil];
}



-(void) setIsActive:(bool)isActive
{
    bool oldActive = _isActive;
    
    _isActive = isActive;
    
    if (oldActive == isActive)
    {
        //If the value didn't change don't do anything
        return;
    }
    
    
    if (isActive)
    {
        [self restoreSourceList];
        for(InputSource *src in self.sourceList)
        {
            src.sourceLayout = self;
            
        }
        
    } else {
        [self saveSourceList];
        for(InputSource *src in self.sourceList)
        {
            src.editorController = nil;
            
        }
        
        self.rootLayer.sublayers = [NSArray array];
        [self.sourceList removeAllObjects];
        
        //self.sourceList = [NSMutableArray array];
    }
}

-(bool) isActive
{
    return _isActive;
}







-(void)frameTick
{
    
    
    NSSize curSize = NSMakeSize(self.canvas_width, self.canvas_height);
    
    if (!NSEqualSizes(curSize, _rootSize))
    {
        NSLog(@"CHANGING SIZE!!!!");
        [CATransaction begin];
        [CATransaction setDisableActions:YES];
        
        self.rootLayer.bounds = CGRectMake(0, 0, self.canvas_width, self.canvas_height);
        [CATransaction commit];
        
        _rootSize = curSize;
    }
    
    NSArray *listCopy = [self sourceListOrdered];
    
    
    for (InputSource *isource in listCopy)
    {
        
        if (isource.active)
        {
            [isource frameTick];
        }
        
    }
}



-(InputSource *)inputForUUID:(NSString *)uuid
{

    NSArray *sources = [self sourceListOrdered];
    
    NSUInteger idx = [sources indexOfObjectPassingTest:^BOOL(id obj, NSUInteger idx, BOOL *stop) {
        return [((InputSource *)obj).uuid isEqualToString:uuid];
        
        
    }];
    
    
    if (idx != NSNotFound)
    {
        return [sources objectAtIndex:idx];
    }
    return nil;
}



@end
