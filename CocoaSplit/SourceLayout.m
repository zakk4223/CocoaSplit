//
//  SourceLayout.m
//  CocoaSplit
//
//  Created by Zakk on 8/31/14.
//  Copyright (c) 2014 Zakk. All rights reserved.
//

#import "SourceLayout.h"
#import "InputSource.h"
#import "CaptureController.h"


@implementation SourceLayout


@synthesize isActive = _isActive;
@synthesize animationIndexes = _animationIndexes;

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
        
        _animationQueue = dispatch_queue_create("CSAnimationQueue", NULL);
        
        
        self.rootLayer = [self newRootLayer];
        self.animationList = [NSMutableArray array];
        
        
        //self.rootLayer.geometryFlipped = YES;
        _rootSize = NSMakeSize(_canvas_width, _canvas_height);
        self.sourceList = [NSMutableArray array];
        
    }
    
    return self;
}


-(CALayer *)newRootLayer
{
    CALayer *newRoot = [CALayer layer];
    [CATransaction begin];
    newRoot.bounds = CGRectMake(0, 0, _canvas_width, _canvas_height);
    newRoot.anchorPoint = CGPointMake(0.0, 0.0);
    newRoot.position = CGPointMake(0.0, 0.0);
    newRoot.masksToBounds = YES;
    newRoot.backgroundColor = CGColorCreateGenericRGB(0, 0, 0, 1);
    newRoot.layoutManager = [CAConstraintLayoutManager layoutManager];
    
    newRoot.delegate = self;
    [CATransaction commit];

    return newRoot;
    
}

-(NSString *)MIDIIdentifier
{
    NSString *liveStr = @"Staging";
    if (self.isActive)
    {
        liveStr = @"Live";
    }
    
    return [NSString stringWithFormat:@"%@Layout:%@", liveStr, self.name];
}


-(MIKMIDIResponderType)MIDIResponderTypeForCommandIdentifier:(NSString *)commandID
{
    return MIKMIDIResponderTypeButton;
}

-(BOOL)respondsToMIDICommand:(MIKMIDICommand *)command
{
    return YES;
}

-(void)handleMIDICommand:(MIKMIDICommand *)command forIdentifier:(NSString *)identifier
{
    
    
    __weak SourceLayout *weakSelf = self;
    
    if ([identifier hasPrefix:@"Animation:"])
    {
        NSString *animName = [identifier substringFromIndex:10];
        NSUInteger indexOfAnim = [self.animationList indexOfObjectPassingTest:^BOOL(id obj, NSUInteger idx, BOOL *stop) {
            CSAnimationItem *testAnim = obj;
            if ([testAnim.name isEqualToString:animName])
            {
                *stop = YES;
                return YES;
            }
            return NO;
        }];
        
        if (indexOfAnim != NSNotFound)
        {
            CSAnimationItem *anim = [self.animationList objectAtIndex:indexOfAnim];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [weakSelf runSingleAnimation:anim];
                
            });
            
        }
        return;
    }
    
}


-(NSArray *)commandIdentifiers
{
    
    NSMutableArray *ret = [NSMutableArray array];
    
    for (CSAnimationItem *anim in self.animationList)
    {
        NSString *ident = [NSString stringWithFormat:@"Animation:%@", anim.name];
        [ret addObject:ident];
    }
    
    return ret;
}


-(void)setAnimationIndexes:(NSIndexSet *)animationIndexes
{
    _animationIndexes = animationIndexes;
    NSUInteger firstIndex = animationIndexes.firstIndex;
    if (firstIndex < self.animationList.count)
    {
        self.selectedAnimation = [self.animationList objectAtIndex:firstIndex];
    }
}

-(NSIndexSet *)animationIndexes
{
    return _animationIndexes;
}


-(IBAction)runAnimations:(id)sender
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
    if (self.selectedAnimation)
    {
        
        NSArray *animations = [self.animationList objectsAtIndexes:self.animationIndexes];
        
        for (CSAnimationItem *anim in animations)
        {
            [self runSingleAnimation:anim];
            
        }
    }
    });
    

}

-(void)runSingleAnimation:(CSAnimationItem *)animation
{
    if (!animation)
    {
        return;
    }
    NSMutableDictionary *inputMap = [NSMutableDictionary dictionary];

    for (NSDictionary *item in animation.inputs)
    {
        if (item[@"value"])
        {
            inputMap[item[@"label"]] = item[@"value"];
        } else {
            inputMap[item[@"label"]] = [NSNull null];
        }
    }

    NSDictionary *animMap = @{@"moduleName": animation.module_name, @"inputs": inputMap, @"rootLayer": self.rootLayer};

    //[self doAnimation:animMap];
    
    NSThread *runThread = [[NSThread alloc] initWithTarget:self selector:@selector(doAnimation:) object:animMap];
    [runThread start];

}


-(void)saveAnimationSource
{
    CSAnimationRunnerObj *runner = [CaptureController sharedAnimationObj];
    NSBundle *mybundle = [NSBundle mainBundle];
    NSString *bundlePath = [mybundle.bundleURL path];
    self.animationSaveData = [NSMutableDictionary dictionary];


    
    for (CSAnimationItem *aitem in self.animationList)
    {
        NSString *mName = aitem.module_name;
        
        NSString *path = [runner animationPath:mName];
        
        //Don't save application bundled animations
        
        
        if ([path hasPrefix:bundlePath])
        {
            continue;
        }
        
        NSString *sourceString = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:nil];
        NSString *moduleFile = [path lastPathComponent];
        if (sourceString)
        {
            [self.animationSaveData setObject:sourceString forKey:moduleFile];
        }
     }
}


-(void)doAnimation:(NSDictionary *)threadDict
{
    
    CSAnimationRunnerObj *runner = [CaptureController sharedAnimationObj];

    NSString *modName = threadDict[@"moduleName"];
    NSDictionary *inpMap = threadDict[@"inputs"];
    CALayer *rootLayer = threadDict[@"rootLayer"];
    
    
    @try {
        [runner runAnimation:modName forInput:inpMap withSuperlayer:rootLayer];

    }
    @catch (NSException *exception) {
        NSLog(@"Animation module %@ failed with exception: %@: %@", modName, [exception name], [exception reason]);

    }
    @finally {
        [CATransaction flush];
    }
}


-(void)deleteAnimations:(id)sender
{
    [[self mutableArrayValueForKey:@"animationList"] removeObjectsAtIndexes:self.animationIndexes];
}


-(void)addAnimation:(NSDictionary *)animation
{
    CSAnimationItem *newItem = [[CSAnimationItem alloc] initWithDictionary:animation moduleName:animation[@"module"]];
    [[self mutableArrayValueForKey:@"animationList"] addObject:newItem];
    
    
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
    if (self.animationSaveData)
    {
        [aCoder encodeObject:self.animationSaveData forKey:@"animationSaveData"];
    }
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
        
        if ([aDecoder containsValueForKey:@"animationSaveData"])
        {
            self.animationSaveData = [aDecoder decodeObjectForKey:@"animationSaveData"];
        }
        
    }
    
    return self;
}


-(NSArray *)sourceListOrdered
{
    NSArray *mylist;
    
    @synchronized(self)
    {
        mylist = self.sourceList;
    }
    
    NSArray *listCopy = [mylist sortedArrayUsingDescriptors:@[_sourceDepthSorter, _sourceUUIDSorter]];
    return listCopy;
}


-(InputSource *)findSource:(NSPoint)forPoint withExtra:(float)withExtra deepParent:(bool)deepParent
{
    /* invert the point due to layer rendering inversion/weirdness */
    
    CGPoint newPoint = CGPointMake(forPoint.x, self.canvas_height-forPoint.y);
    CALayer *foundLayer = [self.rootLayer hitTest:newPoint];
    
    InputSource *retInput = nil;
    
    if (foundLayer && [foundLayer isKindOfClass:[CSInputLayer class]])
    {
        retInput = ((CSInputLayer *)foundLayer).sourceInput;
    }
    

    if (deepParent)
    {
        while (retInput && retInput.parentInput && NSEqualRects(retInput.globalLayoutPosition, ((InputSource *)retInput.parentInput).globalLayoutPosition))
        {
            retInput = retInput.parentInput;
        }
    }
    
    
    return retInput;

}
-(InputSource *)findSource:(NSPoint)forPoint deepParent:(bool)deepParent
{
    
    return [self findSource:forPoint withExtra:0 deepParent:deepParent];
}


-(NSData *)makeSaveData
{
    NSObject *timerSrc = self.layoutTimingSource;
    if (!timerSrc)
    {
        timerSrc = [NSNull null];
    }
    
    NSDictionary *saveDict = @{@"sourcelist": self.sourceList, @"animationList": self.animationList, @"timingSource": timerSrc};
    NSMutableData *saveData = [NSMutableData data];
    NSKeyedArchiver *archiver = [[NSKeyedArchiver alloc] initForWritingWithMutableData:saveData];
    archiver.delegate = self;
    [archiver encodeObject:saveDict forKey:@"root"];
    [archiver finishEncoding];
    
    return saveData;
}


-(void) saveSourceList
{
    
    NSData *saveData = [self makeSaveData];
    self.savedSourceListData = saveData;
}

-(id)archiver:(NSKeyedArchiver *)archiver willEncodeObject:(id)object
{
    if ([object isKindOfClass:[InputSource class]])
    {
        InputSource *src = (InputSource *)object;
        if (src.skipSave)
        {
            return nil;
        }
    }
    
    return object;
}




-(NSObject *)mergeSourceListData:(NSData *)mergeData withLayer:(CALayer *)withLayer
{
    
    
    if (!self.sourceList)
    {
        self.sourceList = [NSMutableArray array];
    }

    if (!mergeData)
    {
        return nil;
    }
    
    if (!withLayer)
    {
        withLayer = self.rootLayer;
    }
    
    NSKeyedUnarchiver *unarchiver = [[NSKeyedUnarchiver alloc] initForReadingWithData:mergeData];
    
    [unarchiver setDelegate:self];
    
    NSObject *mergeObj = [unarchiver decodeObjectForKey:@"root"];
    [unarchiver finishDecoding];
    
    NSArray *mergeList;
    
    if ([mergeObj isKindOfClass:[NSDictionary class]])
    {
        mergeList = [((NSDictionary *)mergeObj) objectForKey:@"sourcelist"];
    } else {
        mergeList = (NSArray *)mergeObj;
    }
    
    for(InputSource *src in mergeList)
    {
        src.sourceLayout = self;
        src.is_live = self.isActive;
        
        
        //[NSApp registerMIDIResponder:src];
        
        if (!src.layer.superlayer)
        {
            [CATransaction begin];
            [withLayer addSublayer:src.layer];
            [CATransaction commit];
            
        }
        

            [[self mutableArrayValueForKey:@"sourceList" ] addObject:src];

    }

    
    return mergeObj;
}


-(void)restoreSourceList:(NSData *)withData
{
    
    
    if (self.savedSourceListData)
    {
        CALayer *newRoot = [self newRootLayer];
        
        [CATransaction begin];
        newRoot.sublayers = [NSArray array];
        
        NSMutableArray *oldSourceList = self.sourceList;
        
        
        self.sourceList = [NSMutableArray array];
        
        if (!withData)
        {
            withData = self.savedSourceListData;
        }
        NSObject *restData = [self mergeSourceListData:withData withLayer:newRoot];
        
        
        if (restData && [restData isKindOfClass:[NSDictionary class]])
        {
                self.animationList = [((NSDictionary *)restData) objectForKey:@"animationList"];
                if (!self.animationList)
                {
                    self.animationList = [NSMutableArray array];
                }

            
            NSObject *timerSrc = nil;
            timerSrc = [((NSDictionary *)restData) objectForKey:@"timingSource"];
            if (timerSrc == [NSNull null])
            {
                timerSrc = nil;
            }
            
            
            self.layoutTimingSource = ((InputSource *)timerSrc);
        }
        
        [self.rootLayer.superlayer replaceSublayer:self.rootLayer with:newRoot];
        self.rootLayer = newRoot;

        for(InputSource *src in oldSourceList)
        {
            [src willDelete];
            [src.layer removeFromSuperlayer];
        }

        
        
        [CATransaction commit];

    }
}


-(bool)containsInput:(InputSource *)cInput
{
    NSArray *listCopy = [self sourceListOrdered];
    
    for (InputSource *testSrc in listCopy)
    {
        if (testSrc == cInput)
        {
            return YES;
        }
    }

    return NO;
}


-(void)deleteSource:(InputSource *)delSource
{
    
    [delSource willDelete];
    
    [[self mutableArrayValueForKey:@"sourceList" ] removeObject:delSource];

    //[self.sourceList removeObject:delSource];
    if (delSource == self.layoutTimingSource)
    {
        self.layoutTimingSource = nil;
    }
    
    [delSource.layer removeFromSuperlayer];
    delSource.sourceLayout = nil;

    
    [[NSNotificationCenter defaultCenter] postNotificationName:CSNotificationInputDeleted  object:delSource userInfo:nil];

}



-(void) addSource:(InputSource *)newSource
{
    newSource.sourceLayout = self;
    newSource.is_live = self.isActive;
    
    
    [[self mutableArrayValueForKey:@"sourceList" ] addObject:newSource];

    
    [self.rootLayer addSublayer:newSource.layer];
    [NSApp registerMIDIResponder:newSource];
    
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
            [self restoreSourceList:nil];
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
        @synchronized(self)
        {
            [self.sourceList removeAllObjects];

        }
        [self.animationList removeAllObjects];
        self.selectedAnimation = nil;
        
        //self.sourceList = [NSMutableArray array];
    }
}

-(bool) isActive
{
    return _isActive;
}





-(InputSource *)sourceUnder:(InputSource *)source
{
    
    NSRect sourceFrame = source.layer.frame;
    
    InputSource *ret = nil;
    
    NSArray *listCopy = [self sourceListOrdered];

    for (InputSource *src in listCopy)
    {
        if (src == source)
        {
            continue;
        }
        
        NSRect candidateFrame = src.layer.frame;
        
        NSRect tryFrame;
        
        tryFrame = [self.rootLayer convertRect:candidateFrame fromLayer:src.layer.superlayer];

        if (NSIntersectsRect(sourceFrame, tryFrame))
        {
            if (source.layer.zPosition >= src.layer.zPosition)
            {
                if (!ret || src.layer.zPosition > ret.layer.zPosition || src.layer.superlayer == ret.layer)
                {
                    ret = src;
                }
            }
        }
        
    }
    
    return ret;
}


-(id<CAAction>)actionForLayer:(CALayer *)layer forKey:(NSString *)event
{
    return (id<CAAction>)[NSNull null];
}



-(void)frameTick
{
    
    
    NSSize curSize = NSMakeSize(self.canvas_width, self.canvas_height);
    
    if (!NSEqualSizes(curSize, _rootSize))
    {
        
        self.rootLayer.bounds = CGRectMake(0, 0, self.canvas_width, self.canvas_height);
        
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


-(void)didBecomeVisible
{
    for (CSAnimationItem  *anim in self.animationList)
    {
        if (anim.onLive)
        {
            [self runSingleAnimation:anim];
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
