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
@synthesize frameRate = _frameRate;

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
        _uuidMap = [NSMutableDictionary dictionary];
        
        _pendingScripts = [NSMutableDictionary dictionary];
        
        _animationQueue = dispatch_queue_create("CSAnimationQueue", NULL);
        _containedLayouts = [[NSMutableArray alloc] init];
        _noSceneTransactions = NO;
        _topLevelSourceArray = [[NSMutableArray alloc] init];
        self.rootLayer = [self newRootLayer];
        
        //self.rootLayer.geometryFlipped = YES;
        _rootSize = NSMakeSize(_canvas_width, _canvas_height);
        self.sourceList = [NSMutableArray array];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(inputAttachEvent:) name:CSNotificationInputAttached object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(inputAttachEvent:) name:CSNotificationInputDetached object:nil];

        
        
    }
    
    return self;
}


-(void)inputAttachEvent:(NSNotification *)notification
{
    InputSource *src = notification.object;
    if (src.sourceLayout == self)
    {
        [self generateTopLevelSourceList];
    }
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

    //newRoot.autoresizingMask = kCALayerMinXMargin | kCALayerWidthSizable | kCALayerMaxXMargin | kCALayerMinYMargin | kCALayerHeightSizable | kCALayerMaxYMargin;
    
    
    newRoot.delegate = self;
    [CATransaction commit];

    return newRoot;
    
}

-(NSString *)MIDIIdentifier
{
    return [NSString stringWithFormat:@"Layout:%@", self.name];
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
    
    
}


-(NSArray *)commandIdentifiers
{
    
    NSMutableArray *ret = [NSMutableArray array];
    
    
    return ret;
}








-(NSString *)runAnimationString:(NSString *)animationCode withCompletionBlock:(void (^)(void))completionBlock withExceptionBlock:(void (^)(NSException *exception))exceptionBlock
{
    if (!animationCode)
    {
        return nil;
    }
    
    NSMutableDictionary *animMap = @{@"animationString": animationCode}.mutableCopy;
    if (completionBlock)
    {
        [animMap setObject:completionBlock forKey:@"completionBlock"];
    }
    
    if (exceptionBlock)
    {
        [animMap setObject:exceptionBlock forKey:@"exceptionBlock"];
        
    }
    
    CFUUIDRef tmpUUID = CFUUIDCreate(NULL);
    NSString *runUUID = (__bridge_transfer NSString *)CFUUIDCreateString(NULL, tmpUUID);
    CFRelease(tmpUUID);
    
    [animMap setObject:runUUID forKey:@"runUUID"];
    

    //[self doAnimation:animMap];
    
    NSThread *runThread = [[NSThread alloc] initWithTarget:self selector:@selector(doAnimation:) object:animMap];
    [runThread start];
    return runUUID;
    

    
    
}



-(void)cancelScriptRun:(NSString *)runUUID
{
    if (self.pendingScripts[runUUID])
    {
        NSDictionary *pendingAnimations = self.pendingScripts[runUUID];
        
        for (NSString *anim_key in pendingAnimations)
        {
            CALayer *target = pendingAnimations[anim_key];
            [target removeAnimationForKey:anim_key];
        }
        [self.pendingScripts removeObjectForKey:runUUID];
    }
    
    [self cancelTransition];
    
}


-(void)doAnimation:(NSDictionary *)threadDict
{
    
    CSAnimationRunnerObj *runner = [CaptureController sharedAnimationObj];

    NSString *modName = threadDict[@"moduleName"];
    NSDictionary *inpMap = threadDict[@"inputs"];
    CALayer *rootLayer = threadDict[@"rootLayer"];
    NSString *animationCode = threadDict[@"animationString"];
    NSString *runUUID = threadDict[@"runUUID"];
    
    void (^completionBlock)(void) = [threadDict objectForKey:@"completionBlock"];
    void (^exceptionBlock)(NSException *exception) = [threadDict objectForKey:@"exceptionBlock"];
    
    
    @try {

            [CATransaction begin];
            [CATransaction setCompletionBlock:^{
                [self.pendingScripts removeObjectForKey:runUUID];
                if (completionBlock)
                {
                    completionBlock();
                }
                
            }];
        
        
        if (animationCode)
        {
            NSDictionary *pendingAnimations = [runner runAnimation:animationCode forLayout:self];
            self.pendingScripts[runUUID] = pendingAnimations;
        } else {
            [runner runAnimation:modName forLayout:self  withSuperlayer:rootLayer];
        }
    }
    @catch (NSException *exception) {
        
        [self.pendingScripts removeObjectForKey:runUUID];

        if (exceptionBlock)
        {
            exceptionBlock(exception);
        }
        
        NSLog(@"Animation module %@ failed with exception: %@: %@", modName, [exception name], [exception reason]);
    }
    @finally {
            [CATransaction commit];

        //[CATransaction flush];
    }
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
    newLayout.containedLayouts = self.containedLayouts.mutableCopy;
    
    return newLayout;
}




-(void) encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeObject:self.name forKey:@"name"];
    
    if (self.doSaveSourceList)
    {
        [self saveSourceList];
    }
    
    
    
    [aCoder encodeObject:self.savedSourceListData forKey:@"savedSourceData"];
    [aCoder encodeInt:self.canvas_width forKey:@"canvas_width"];
    [aCoder encodeInt:self.canvas_height forKey:@"canvas_height"];
    [aCoder encodeFloat:self.frameRate forKey:@"frameRate"];
    if (self.containedLayouts)
    {
        [aCoder encodeObject:self.containedLayouts forKey:@"containedLayouts"];
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
        
    
        if ([aDecoder containsValueForKey:@"containedLayouts"])
        {
            self.containedLayouts = [[aDecoder decodeObjectForKey:@"containedLayouts"] mutableCopy];
            //set live/staging status for each layout
        }
        
    }
    
    return self;
}



-(float)frameRate
{
    return _frameRate;
}


-(void)setFrameRate:(float)frameRate
{
    float oldframerate = _frameRate;
    
    _frameRate = frameRate;
    
    if (_frameRate != oldframerate)
    {
        [[NSNotificationCenter defaultCenter] postNotificationName:CSNotificationLayoutFramerateChanged object:self userInfo:nil];
    }
}


-(void)applyAddBlock
{
    if (self.addLayoutBlock)
    {
        for (SourceLayout *layout in self.containedLayouts)
        {
            self.addLayoutBlock(layout);
        }
    }
}


-(void)generateTopLevelSourceList
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self willChangeValueForKey:@"topLevelSourceList"];

        [_topLevelSourceArray removeAllObjects];
        for (InputSource *src in self.sourceListOrdered)
        {
            if (!src.parentInput)
            {
                [_topLevelSourceArray addObject:src];
            }
        }
        [self didChangeValueForKey:@"topLevelSourceList"];

    });
    [_topLevelSourceArray removeAllObjects];
    for (InputSource *src in self.sourceListOrdered)
    {
        if (!src.parentInput)
        {
            [_topLevelSourceArray addObject:src];
        }
    }
}


-(NSArray *)topLevelSourceList
{
    
    return _topLevelSourceArray;
    
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


-(void) resetAllRefCounts
{
    for (InputSource *src in self.sourceList)
    {
        src.refCount = 1;
    }
    
}




-(NSInteger)incrementInputRef:(InputSource *)input
{
    
    input.refCount++;
    
    return input.refCount;
}

-(NSInteger)decrementInputRef:(InputSource *)input
{
    
    input.refCount--;
    
    if (input.refCount < 0)
    {
        input.refCount = 0;
    }
    
    return input.refCount;
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
    
    NSDictionary *saveDict = @{@"sourcelist": self.sourceList,  @"timingSource": timerSrc};
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
    [[NSNotificationCenter defaultCenter] postNotificationName:CSNotificationLayoutSaved object:self userInfo:nil];

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


-(NSDictionary *)diffSourceListWithData:(NSData *)useData
{
    
    NSKeyedUnarchiver *unarchiver = [[NSKeyedUnarchiver alloc] initForReadingWithData:useData];
    
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

    
    
    NSMutableDictionary *uuidMap = [NSMutableDictionary dictionary];
    
    NSMutableDictionary *retDict = [NSMutableDictionary dictionary];
    
    [retDict setObject:[NSMutableArray array] forKey:@"new"];
    [retDict setObject:[NSMutableArray array] forKey:@"changed"];
    [retDict setObject:[NSMutableArray array] forKey:@"same"];

    [retDict setObject:[NSMutableArray array] forKey:@"removed"];
    
    for (InputSource *oSrc in mergeList)
    {
        [uuidMap setObject:oSrc forKey:oSrc.uuid];
        
        InputSource *eSrc = [self inputForUUID:oSrc.uuid];
        if (eSrc)
        {
            if ([eSrc isDifferentInput:oSrc])
            {
                [retDict[@"changed"] addObject:oSrc];
                
            } else {
                [retDict[@"same"] addObject:oSrc];
            }
        } else {
            [retDict[@"new"] addObject:oSrc];
        }
        
    }
    
    for (InputSource *sSrc in self.sourceList)
    {
    
        InputSource *oSrc = [uuidMap objectForKey:sSrc.uuid];
        if (!oSrc)
        {
            [retDict[@"removed"] addObject:sSrc];

        }
    }

    return retDict;
    
}


-(void)replaceWithSourceLayout:(SourceLayout *)layout
{
    [self replaceWithSourceLayout:layout withCompletionBlock:nil];
}


-(void)replaceWithSourceLayout:(SourceLayout *)layout withCompletionBlock:(void (^)(void))completionBlock
{
    

    
    NSDictionary *diffResult = [self diffSourceListWithData:layout.savedSourceListData];
    NSMutableArray *changedRemove = [NSMutableArray array];
    
    NSArray *changedInputs = diffResult[@"changed"];
    NSArray *removedInputs = diffResult[@"removed"];
    NSArray *sameInputs = diffResult[@"same"];
    NSArray *newInputs = diffResult[@"new"];
    
    
    
    CATransition *rTrans = nil;
    
    if (self.transitionName || self.transitionFilter)
    {
        rTrans = [CATransition animation];
        rTrans.type = self.transitionName;
        rTrans.duration = self.transitionDuration;
        rTrans.removedOnCompletion = YES;
        rTrans.subtype = self.transitionDirection;
        if (self.transitionFilter)
        {
            rTrans.filter = self.transitionFilter;
        }
    }

    
    [CATransaction begin];
    
    [CATransaction setCompletionBlock:^{
        
       
        for (InputSource *rSrc in removedInputs)
        {
            [self deleteSource:rSrc];
        }
        
        for (InputSource *cSrc in changedRemove)
        {
            if (cSrc)
            {
                [self deleteSource:cSrc];
            }
        }
        
        if (completionBlock)
        {
            completionBlock();
        }
    }];

    
    
    for (SourceLayout *cLayout in self.containedLayouts.copy)
    {
        if (self.removeLayoutBlock)
        {
            self.removeLayoutBlock(cLayout);
        }
        
        [self.containedLayouts removeObject:cLayout];
    }
    
    
    if (self.addLayoutBlock)
    {
        self.addLayoutBlock(layout);
    }
    
    [self.containedLayouts addObject:layout];

    for (SourceLayout *cLayout in layout.containedLayouts.copy)
    {
        if (self.addLayoutBlock)
        {
            self.addLayoutBlock(cLayout);
        }
        
        [self.containedLayouts addObject:cLayout];
    }
    
    
    if (self.transitionFullScene)
    {
        if (rTrans)
        {
            [self.rootLayer addAnimation:rTrans forKey:kCATransition];
        }
        
    }

    
    for (InputSource *rSrc in removedInputs)
    {
        if (!self.transitionFullScene)
        {
            [rSrc.layer addAnimation:rTrans forKey:nil];
        }
        rSrc.layer.hidden = YES;
    }
    
    for (InputSource *cSrc in changedInputs)
    {
        InputSource *mSrc = [self inputForUUID:cSrc.uuid];
        
        if (!self.transitionFullScene)
        {
            [mSrc.layer addAnimation:rTrans forKey:nil];
        }

        [changedRemove addObject:mSrc];
        
        if (!self.transitionFullScene)
        {
            cSrc.layer.hidden = YES;
        }
        
        
        [self addSource:cSrc withParentLayer:mSrc.layer.superlayer];
        mSrc.layer.hidden = YES;
    }
    
    for (InputSource *nSrc in newInputs)
    {

        if (!self.transitionFullScene)
        {
            nSrc.layer.hidden = YES;
        }

        [self addSource:nSrc];

    }
    
    
    
    
    
    [CATransaction commit];

    [CATransaction flush];
    if (!self.transitionFullScene)
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            [CATransaction begin];
            for (InputSource *nSrc in newInputs)
            {
                
                [nSrc.layer addAnimation:rTrans forKey:nil];
                nSrc.layer.hidden = NO;
            }
            
            for (InputSource *cSrc in changedInputs)
            {
                [cSrc.layer addAnimation:rTrans forKey:nil];
                cSrc.layer.hidden = NO;
            }

            
            [CATransaction commit];
        });
    }

    
    _noSceneTransactions = NO;
    [self updateCanvasWidth:layout.canvas_width height:layout.canvas_height];
    self.frameRate = layout.frameRate;
    [self resetAllRefCounts];
    
    
}



-(bool)containsLayout:(SourceLayout *)layout
{
    return [self.containedLayouts containsObject:layout];
}







-(void)mergeSourceLayout:(SourceLayout *)toMerge
{
    [self mergeSourceLayout:toMerge withCompletionBlock:nil];
}

-(void)mergeSourceLayout:(SourceLayout *)toMerge withCompletionBlock:(void (^)(void))completionBlock
{
    
    
    if ([self.containedLayouts containsObject:toMerge])
    {
        return;
    }
    
    NSDictionary *diffResult = [self diffSourceListWithData:toMerge.savedSourceListData];
    NSMutableArray *changedRemove = [NSMutableArray array];
    
    NSArray *changedInputs = diffResult[@"changed"];
    NSArray *removedInputs = diffResult[@"removed"];
    NSArray *sameInputs = diffResult[@"same"];
    NSArray *newInputs = diffResult[@"new"];

    CATransition *rTrans = nil;
    
    if (self.transitionName || self.transitionFilter)
    {
        rTrans = [CATransition animation];
        rTrans.type = self.transitionName;
        rTrans.duration = self.transitionDuration;
        rTrans.removedOnCompletion = YES;
        rTrans.subtype = self.transitionDirection;
        if (self.transitionFilter)
        {
            rTrans.filter = self.transitionFilter;
        }
    }
    

    
    [CATransaction begin];
    
    [CATransaction setCompletionBlock:^{
        
        for (InputSource *cSrc in changedRemove)
        {
            [self deleteSource:cSrc];
        }
        
        
        if (completionBlock)
        {
            completionBlock();
        }
    }];
    
    if (self.transitionFullScene)
    {
        [self.rootLayer addAnimation:rTrans forKey:nil];
    }
    
    for (InputSource *nSrc in newInputs)
    {
        if (!self.transitionFullScene)
        {
            nSrc.layer.hidden = YES;
        }
        
        [self addSource:nSrc];
    }
    
    for (InputSource *cSrc in changedInputs)
    {
        InputSource *mSrc = [self inputForUUID:cSrc.uuid];
        [changedRemove addObject:mSrc];
        mSrc.layer.hidden = YES;
        cSrc.layer.hidden = YES;
        [self addSource:cSrc];
        [self incrementInputRef:cSrc];
    }
    [CATransaction commit];
    [CATransaction flush];

    if (!self.transitionFullScene)
    {
        
        CABasicAnimation *hackAnim = [CABasicAnimation animationWithKeyPath:@"dummyKeyPath"];
        hackAnim.duration = rTrans.duration;
        hackAnim.fromValue = @0;
        hackAnim.toValue = @100;
        hackAnim.removedOnCompletion = YES;
        
        [self.rootLayer addAnimation:hackAnim forKey:@"dummyKey"];

        dispatch_async(dispatch_get_main_queue(), ^{
            for (InputSource *nSrc in newInputs)
            {
                [nSrc.layer addAnimation:rTrans forKey:nil];
                nSrc.layer.hidden = NO;
            }
            
            for (InputSource *cSrc in changedInputs)
            {
                [cSrc.layer addAnimation:rTrans forKey:nil];
                cSrc.layer.hidden = NO;
            }
        });
    }
    [self adjustAllInputs];
    [self.containedLayouts addObject:toMerge];
    if (self.addLayoutBlock)
    {
        self.addLayoutBlock(toMerge);
    }

    
}

-(void)removeSourceLayout:(SourceLayout *)toRemove
{
    [self removeSourceLayout:toRemove withCompletionBlock:nil];
}

-(void)removeSourceLayout:(SourceLayout *)toRemove withCompletionBlock:(void (^)(void))completionBlock
{
    
    if (![self.containedLayouts containsObject:toRemove])
    {
        return;
    }
    
    NSDictionary *diffResult = [self diffSourceListWithData:toRemove.savedSourceListData];
    
    NSArray *changedInputs = diffResult[@"changed"];
    NSArray *sameInputs = diffResult[@"same"];
    NSArray *newInputs = diffResult[@"new"];
    
    NSMutableArray *removeInputs = [NSMutableArray arrayWithArray:changedInputs];
    [removeInputs addObjectsFromArray:sameInputs];
    [removeInputs addObjectsFromArray:newInputs];
    
    CATransition *rTrans = nil;
    
    if (self.transitionName || self.transitionFilter)
    {
        rTrans = [CATransition animation];
        rTrans.type = self.transitionName;
        rTrans.duration = self.transitionDuration;
        rTrans.removedOnCompletion = YES;
        rTrans.subtype = self.transitionDirection;
        if (self.transitionFilter)
        {
            rTrans.filter = self.transitionFilter;
        }
    }

    [CATransaction begin];
    [CATransaction setCompletionBlock:^{
        
        
        for (InputSource *rSrc in removeInputs)
        {
            InputSource *eSrc = [self inputForUUID:rSrc.uuid];
            [self decrementInputRef:eSrc];
            [self deleteSource:eSrc];
        }
        
        if (completionBlock)
        {
            completionBlock();
        }
    }];
    
    if (self.transitionFullScene)
    {
        [self.rootLayer addAnimation:rTrans forKey:nil];
    }
    
    
    for (InputSource *rSrc in removeInputs)
    {
        InputSource *eSrc = [self inputForUUID:rSrc.uuid];
        
        if (eSrc)
        {
            if (!self.transitionFullScene)
            {
                [eSrc.layer addAnimation:rTrans forKey:kCAOnOrderOut];
            }
            eSrc.layer.hidden = YES;

        }
    }
    [CATransaction commit];
    
    [self.containedLayouts removeObject:toRemove];
    if (self.removeLayoutBlock)
    {
        self.removeLayoutBlock(toRemove);
    }
}








-(void)cancelTransition
{
    [self.rootLayer removeAnimationForKey:kCATransition];
    for (InputSource *src in self.sourceList)
    {
        [src.layer removeAnimationForKey:kCATransition];
    }
}





-(NSObject *)removeSourceListData:(NSData *)mergeData
{
    
    CALayer *withLayer = nil;
    
    if (!self.sourceList)
    {
        return nil;
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
    

    //[self removeSourceInputs:mergeList withLayer:withLayer];
    
    return mergeObj;
}


-(void)restoreSourceList:(NSData *)withData
{
    
    if (self.savedSourceListData)
    {
        
        [CATransaction begin];
        
        NSMutableArray *oldSourceList = self.sourceList;
        
        
        self.sourceList = [NSMutableArray array];
        _uuidMap = [NSMutableDictionary dictionary];
        
        
        if (!withData)
        {
            withData = self.savedSourceListData;
        }
        
        NSKeyedUnarchiver *unarchiver = [[NSKeyedUnarchiver alloc] initForReadingWithData:withData];
        
        [unarchiver setDelegate:self];
        
        NSObject *restData = [unarchiver decodeObjectForKey:@"root"];
        [unarchiver finishDecoding];
        
        NSArray *srcList = nil;
        
        if (restData && [restData isKindOfClass:[NSDictionary class]])
        {
            NSObject *timerSrc = nil;
            timerSrc = [((NSDictionary *)restData) objectForKey:@"timingSource"];
            if (timerSrc == [NSNull null])
            {
                timerSrc = nil;
            }
            
            srcList = [((NSDictionary *)restData) objectForKey:@"sourcelist"];
            
            self.layoutTimingSource = ((InputSource *)timerSrc);
        } else {
            srcList = (NSArray *)restData;
        }
        
        
        
        for (InputSource *nSrc in srcList)
        {
            [self addSource:nSrc];
        }
        
        
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
    
    [self willChangeValueForKey:@"topLevelSourceList"];
    @synchronized (self) {
        [[self mutableArrayValueForKey:@"sourceList" ] removeObject:delSource];
    }
    [self generateTopLevelSourceList];
    [self didChangeValueForKey:@"topLevelSourceList"];
    

    InputSource *uSrc;
    uSrc = _uuidMap[delSource.uuid];
    if ([uSrc isEqual:delSource])
    {
        [_uuidMap removeObjectForKey:delSource.uuid];
    }
    
    //[self.sourceList removeObject:delSource];
    if (delSource == self.layoutTimingSource)
    {
        self.layoutTimingSource = nil;
    }
    
    [delSource.layer removeFromSuperlayer];

    [[NSNotificationCenter defaultCenter] postNotificationName:CSNotificationInputDeleted  object:delSource userInfo:nil];
    delSource.sourceLayout = nil;

    
    

}



-(void)setupMIDI
{
    [NSApp registerMIDIResponder:self];
    for (InputSource *src in self.sourceList)
    {
        [NSApp registerMIDIResponder:src];

    }
}


-(void) adjustAllInputs
{
    
    NSArray *copiedInputs = [self sourceListOrdered];
    
    for (InputSource *src in copiedInputs)
    {
        src.needsAdjustPosition = YES;
        src.needsAdjustment = YES;
    }
}



-(void) addSource:(InputSource *)newSource
{
    [self addSource:newSource withParentLayer:self.rootLayer];
}


-(void) addSource:(InputSource *)newSource withParentLayer:(CALayer *)parentLayer
{
    newSource.sourceLayout = self;
    newSource.is_live = self.isActive;
    
    [[self mutableArrayValueForKey:@"sourceList" ] addObject:newSource];
    

    [parentLayer addSublayer:newSource.layer];


    newSource.needsAdjustPosition = NO;
    newSource.needsAdjustment = YES;
    
    
    
    [_uuidMap setObject:newSource forKey:newSource.uuid];
    
    [self incrementInputRef:newSource];
    
    [self generateTopLevelSourceList];
    [NSApp registerMIDIResponder:newSource];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:CSNotificationInputAdded object:newSource userInfo:nil];
}


-(void)clearSourceList
{
    self.rootLayer.sublayers = [NSArray array];
    @synchronized(self)
    {
        [self.sourceList removeAllObjects];
        [self generateTopLevelSourceList];

        
    }
    [_uuidMap removeAllObjects];
}


/*
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

*/





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


-(void)updateCanvasWidth:(int)width height:(int)height 
{
    int old_height = self.canvas_height;
    int old_width = self.canvas_width;
    
    self.canvas_height = height;
    self.canvas_width = width;
    
    if ((old_height != height) || (old_width != width))
    {
        [[NSNotificationCenter defaultCenter] postNotificationName:CSNotificationLayoutCanvasChanged object:self userInfo:nil];
    }
}


-(void)frameTick
{
    @autoreleasepool {
        
        bool needsResize = NO;
        NSSize curSize = NSMakeSize(self.canvas_width, self.canvas_height);
        
        if (!NSEqualSizes(curSize, _rootSize))
        {
            
            self.rootLayer.bounds = CGRectMake(0, 0, self.canvas_width, self.canvas_height);
            _rootSize = curSize;
            needsResize = YES;
        }
        
        
        NSArray *listCopy;
        
        listCopy = [self sourceListOrdered];
        
        
        
        for (InputSource *isource in listCopy)
        {
            if (needsResize)
            {
                isource.needsAdjustPosition = YES;
                isource.needsAdjustment = YES;
            }
            
            if (isource.active)
            {
                [isource frameTick];
            }
            
        }
    }
    
}


-(void)didBecomeVisible
{
    if (self.in_staging)
    {
        return;
    }
    
}



-(void)modifyUUID:(NSString *)uuid withBlock:(void (^)(InputSource *input))withBlock
{
    InputSource *useSource = [self inputForUUID:uuid];
    if (useSource)
    {
        withBlock(useSource);
    }
}




-(InputSource *)inputForName:(NSString *)name
{
    for (InputSource *tSrc in self.sourceList)
    {
        if (tSrc.name && [tSrc.name isEqualToString:name])
        {
            return tSrc;
        }
    }
    return nil;
}


-(InputSource *)inputForUUID:(NSString *)uuid
{
    return [_uuidMap objectForKey:uuid];
}


-(void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
}

@end
