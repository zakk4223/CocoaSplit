//
//  SourceLayout.m
//  CocoaSplit
//
//  Created by Zakk on 8/31/14.
//

#import "SourceLayout.h"
#import "InputSource.h"
#import "CaptureController.h"
#import "CSTransitionAnimationDelegate.h"
#import "CSCaptureBase+TimerDelegate.h"
#import "CSLayoutTransition.h"
#import "CSLayoutRecorder.h"
#import "CSAudioInputSource.h"

JS_EXPORT void JSSynchronousGarbageCollectForDebugging(JSContextRef ctx);


@implementation SourceLayout


@synthesize isActive = _isActive;
@synthesize frameRate = _frameRate;
@synthesize layoutTimingSource = _layoutTimingSource;

-(instancetype) init
{
    if (self = [super init])
    {
        _sourceDepthSorter = [[NSSortDescriptor alloc] initWithKey:@"depth" ascending:YES];
        _sourceDepthSorterRev = [[NSSortDescriptor alloc] initWithKey:@"depth" ascending:NO];

        _sourceUUIDSorter = [[NSSortDescriptor alloc] initWithKey:@"uuid" ascending:YES];
        self.sourceCache = [[SourceCache alloc] init];
        _frameRate = 30;
        _canvas_height = 720;
        _canvas_width = 1280;
        _fboTexture = 0;
        _rFbo = 0;
        _uuidMap = [NSMutableDictionary dictionary];
        _uuidMapPresentation = [NSMutableDictionary dictionary];
        
        
        _pendingScripts = [NSMutableDictionary dictionary];
        
        _containedLayouts = [[NSMutableArray alloc] init];
        _noSceneTransactions = NO;
        _topLevelSourceArray = [[NSMutableArray alloc] init];
        self.rootLayer = [self newRootLayer];
        
        //self.rootLayer.geometryFlipped = YES;
        _rootSize = NSMakeSize(_canvas_width, _canvas_height);
        self.sourceList = [NSMutableArray array];
        self.sourceListPresentation = [NSMutableArray array];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(inputAttachEvent:) name:CSNotificationInputAttached object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(inputAttachEvent:) name:CSNotificationInputDetached object:nil];

        
        
    }
    
    return self;
}


-(void)runTriggerScriptForInput:(NSObject <CSInputSourceProtocol>*)input withName:(NSString *)scriptName usingContext:(JSContext *)jsCtx
{
    
    if (!jsCtx || !input || !scriptName)
    {
        return;
    }
    
    
    NSString *property_name = [NSString stringWithFormat:@"script_%@", scriptName];
    
    if ([input valueForKey:property_name])
    {
        
        JSValue *scriptFunc = jsCtx[@"runTriggerScriptInput"];
        if (scriptFunc)
        {
            [scriptFunc callWithArguments:@[input, scriptName]];
        }
    }
}


-(void)setLayoutTimingSource:(InputSource *)layoutTimingSource
{
    CSCaptureBase *currentTiming = (CSCaptureBase *)_layoutTimingSource.videoInput;
    
    if (currentTiming.timerDelegate)
    {
        [currentTiming.timerDelegate frameTimerWillStop:currentTiming.timerDelegateCtx];
    }
    
    
    _layoutTimingSource = layoutTimingSource;
}


-(InputSource *)layoutTimingSource
{
    return _layoutTimingSource;
}


-(void)inputAttachEvent:(NSNotification *)notification
{
    NSObject<CSInputSourceProtocol> *src = notification.object;
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
    CGColorRef tmpColor = CGColorCreateGenericRGB(0, 0, 0, 1);
    newRoot.backgroundColor = tmpColor;
    CGColorRelease(tmpColor);
    newRoot.layoutManager = [CAConstraintLayoutManager layoutManager];

    //newRoot.autoresizingMask = kCALayerMinXMargin | kCALayerWidthSizable | kCALayerMaxXMargin | kCALayerMinYMargin | kCALayerHeightSizable | kCALayerMaxYMargin;
    
    
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
    
    
}

- (void)handleMIDICommand:(MIKMIDICommand *)command
{
    return;
}



-(NSArray *)commandIdentifiers
{
    
    NSMutableArray *ret = [NSMutableArray array];
    
    
    return ret;
}








-(NSString *)runAnimationString:(NSString *)animationCode withCompletionBlock:(void (^)(void))completionBlock withExceptionBlock:(void (^)(NSException *exception))exceptionBlock withExtraDictionary:(NSDictionary *)extraDictionary
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
    
    if (extraDictionary)
    {
        [animMap setObject:extraDictionary forKey:@"extraDictionary"];
    }
    
    CFUUIDRef tmpUUID = CFUUIDCreate(NULL);
    NSString *runUUID = (__bridge_transfer NSString *)CFUUIDCreateString(NULL, tmpUUID);
    CFRelease(tmpUUID);
    
    [animMap setObject:runUUID forKey:@"runUUID"];
    

    //[self doAnimation:animMap];
    
    
    
    if (!_animationQueue)
    {
        _animationQueue = dispatch_queue_create("Javascript layout queue", DISPATCH_QUEUE_SERIAL);
    }
    
    dispatch_async(_animationQueue, ^{
        [self doAnimation:animMap];
    });
    
    
    //NSThread *runThread = [[NSThread alloc] initWithTarget:self selector:@selector(doAnimation:) object:animMap];
   // [runThread start];
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
    
    
    @autoreleasepool {
        
    CSAnimationRunnerObj *runner = [CaptureController sharedAnimationObj];

    NSString *modName = threadDict[@"moduleName"];
    CALayer *rootLayer = threadDict[@"rootLayer"];
    NSString *animationCode = threadDict[@"animationString"];
    NSString *runUUID = threadDict[@"runUUID"];
    NSDictionary *extraDictRO = threadDict[@"extraDictionary"];
    NSMutableDictionary *extraDict = nil;
    if (extraDictRO)
    {
        extraDict = extraDictRO.mutableCopy;
    } else {
        extraDict = [NSMutableDictionary dictionary];
    }
    
    extraDict[@"__default_animation_time__"] = @([CaptureController sharedCaptureController].transitionDuration);
    
    
    void (^completionBlock)(void) = [threadDict objectForKey:@"completionBlock"];
    void (^exceptionBlock)(NSException *exception) = [threadDict objectForKey:@"exceptionBlock"];
    
    JSContext *jsCtx = nil;
    
        /*
    if (!_animationVirtualMachine)
    {
        _animationVirtualMachine = [[JSVirtualMachine alloc] init];
    }*/
        
        
    
        jsCtx = [[CaptureController sharedCaptureController] setupJavascriptContext:_animationVirtualMachine];
        
        
    
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
            jsCtx[@"extraDict"] = extraDict;
            jsCtx[@"useLayout"] = self;
            
            
            JSValue *runFunc = jsCtx[@"runAnimationForLayoutWithExtraDictionary"];
            JSValue *scriptRet = [runFunc callWithArguments:@[animationCode, self, extraDict]];
                                  

        
            NSDictionary *pendingAnimations = scriptRet.toDictionary;
            
            
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

        jsCtx = nil;

       // [CATransaction flush];
    }
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
    
    [aCoder encodeBool:self.recordingLayout forKey:@"recordingLayout"];
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
        
        self.recordingLayout = [aDecoder decodeBoolForKey:@"recordingLayout"];
        
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


-(float)setDepthForSource:(InputSource *)src startDepth:(float)startDepth
{
    
    float currentDepth = startDepth;

    src.layer.zPosition = currentDepth;
    currentDepth += 100.0f;
    for (InputSource *cSrc in src.attachedInputs)
    {
        currentDepth = [self setDepthForSource:cSrc startDepth:currentDepth];
    }
    
    return currentDepth;
}


-(void)generateTopLevelSourceList
{
    dispatch_async(dispatch_get_main_queue(), ^{
        
        NSMutableArray *tmpArray = [NSMutableArray array];
        
        NSMutableArray *noLayer = [NSMutableArray array];
        float currentDepth = 0.0f;
        
        [self willChangeValueForKey:@"topLevelSourceList"];

        [self->_topLevelSourceArray removeAllObjects];
        for (NSObject<CSInputSourceProtocol> *src in self.sourceListOrdered)
        {
            if (!src.isVideo)
            {
                [noLayer addObject:src];
            } else if (!((InputSource *)src).parentInput) {
                [tmpArray addObject:src];
                if (src.layer)
                {
                    currentDepth = [self setDepthForSource:(InputSource *)src startDepth:currentDepth];
                }
            }
        }
        
        self->_topLevelSourceArray = tmpArray;
        [self->_topLevelSourceArray addObjectsFromArray:noLayer];
        
        [self didChangeValueForKey:@"topLevelSourceList"];

    });
}


-(NSArray *)topLevelSourceList
{
    
    return _topLevelSourceArray;
    
}


-(NSString *)description
{
    return self.name;
}


-(NSArray *)sourceListOrdered
{
    return [self sourceListOrdered:NO];
}


-(NSArray *)sourceListOrdered:(bool)depthReverse
{
    NSArray *mylist;
    
    @synchronized(self)
    {
        mylist = self.sourceList;
    }
    NSSortDescriptor *depthSorter = nil;
    if (depthReverse)
    {
        depthSorter = _sourceDepthSorterRev;
    } else {
        depthSorter = _sourceDepthSorter;
    }
    
    
    NSArray *listCopy = [mylist sortedArrayUsingDescriptors:@[depthSorter, _sourceUUIDSorter]];
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
    for (NSObject<CSInputSourceProtocol> *src in self.sourceList)
    {
        src.refCount = 1;
    }
    
}




-(NSInteger)incrementInputRef:(NSObject<CSInputSourceProtocol> *)input
{
    
    input.refCount++;
    
    return input.refCount;
}

-(NSInteger)decrementInputRef:(NSObject<CSInputSourceProtocol> *)input
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


-(NSData *)makeAudioSaveData
{
    CAMultiAudioEngine *audioEngine = nil;
    
    if (self.recorder && self.recorder.audioEngine)
    {
        audioEngine = self.recorder.audioEngine;
    }
    
    if (!audioEngine)
    {
        return nil;
    }
    
    NSMutableData *saveData = [NSMutableData data];

    NSKeyedArchiver *archiver = [[NSKeyedArchiver alloc] initForWritingWithMutableData:saveData];
    [archiver encodeObject:audioEngine forKey:@"root"];
    [archiver finishEncoding];

    return saveData;
}


-(CAMultiAudioEngine *)restoreAudioData
{
    if (!self.audioData)
    {
        return nil;
    }
    
    NSKeyedUnarchiver *unarchiver = [[NSKeyedUnarchiver alloc] initForReadingWithData:self.audioData];
    CAMultiAudioEngine *audioRestore = [unarchiver decodeObjectForKey:@"root"];
    [unarchiver finishDecoding];
    
    return audioRestore;
}

-(CAMultiAudioEngine *)findAudioEngine
{
    if (self.audioEngine)
    {
        return self.audioEngine;
    }
    
    if (self.recorder.audioEngine)
    {
        return self.recorder.audioEngine;
    }
    
    return nil;
}


-(void)reapplyAudioSources
{
    for (NSObject <CSInputSourceProtocol> *input in self.sourceList)
    {
        if (input.isAudio)
        {
            CSAudioInputSource *audioSrc = (CSAudioInputSource *)input;
            [audioSrc applyAudioSettings];
        }
    }
}

-(NSData *)makeSaveData

{
    NSObject *timerSrc = self.layoutTimingSource;
    
    if (!timerSrc && self.sourceList.count == 0)
    {
        return nil;
    }
    
    
    
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


-(void) saveSourceListForExport
{
    _doingLayoutExport = YES;
    [self saveSourceList];
    _doingLayoutExport = NO;
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
    
    if ([object conformsToProtocol:@protocol(CSCaptureSourceProtocol)])
    {
        NSObject<CSCaptureSourceProtocol> *capSrc = (NSObject<CSCaptureSourceProtocol> *)object;
        if (_doingLayoutExport)
        {
            [capSrc willExport];
        }
    }
    
    return object;
}

-(void)archiver:(NSKeyedArchiver *)archiver didEncodeObject:(id)object
{
    if ([object conformsToProtocol:@protocol(CSCaptureSourceProtocol)])
    {
        NSObject<CSCaptureSourceProtocol> *capSrc = (NSObject<CSCaptureSourceProtocol> *)object;
        if (_doingLayoutExport)
        {
            [capSrc didExport];
        }
    }
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

    [retDict setObject:[NSMutableArray array] forKey:@"scriptExisting"];
    [retDict setObject:[NSMutableArray array] forKey:@"scriptNew"];

    
    [retDict setObject:[NSMutableArray array] forKey:@"removed"];
    
    for (NSObject<CSInputSourceProtocol> *oSrc in mergeList)
    {
        [uuidMap setObject:oSrc forKey:oSrc.uuid];
        
        NSObject<CSInputSourceProtocol> *eSrc = [self inputForUUID:oSrc.uuid];
        if (eSrc)
        {
            
            if ([eSrc isDifferentInput:oSrc])
            {
                
                [retDict[@"changed"] addObject:oSrc];
                
            } else {
                
                if (eSrc.scriptAlwaysRun)
                {
                    [retDict[@"scriptExisting"] addObject:eSrc];

                }
                if (oSrc.scriptAlwaysRun)
                {
                    [retDict[@"scriptNew"] addObject:oSrc];

                }
                [retDict[@"same"] addObject:eSrc];
            }
        } else {
            [retDict[@"new"] addObject:oSrc];
        }
        
    }
    
    for (NSString *srcKey in _uuidMapPresentation)
    {
    
        NSObject<CSInputSourceProtocol> *sSrc = _uuidMapPresentation[srcKey];
        InputSource *oSrc = [uuidMap objectForKey:sSrc.uuid];
        if (!oSrc)
        {
            if (sSrc.scriptAlwaysRun)
            {
                [retDict[@"scriptExisting"] addObject:sSrc];
            }

            [retDict[@"removed"] addObject:sSrc];

        }
    }

    return retDict;
    
}


-(void)undoReplaceSourceLayout:(NSData *)layoutData usingScripts:(bool)usingScripts withContainedLayouts:(NSArray *)containedLayouts
{
    [self replaceWithSourceData:layoutData usingScripts:usingScripts withCompletionBlock:nil];
    
    for (SourceLayout *cLayout in containedLayouts)
    {
        if (self.removeLayoutBlock)
        {
            self.removeLayoutBlock(cLayout);
        }
        
    }

    if (self.addLayoutBlock)
    {
        for (SourceLayout *newCont in containedLayouts)
        {
            self.addLayoutBlock(newCont);
        }
    }
}


-(void)sequenceThroughLayoutsViaScript:(NSArray *)sequence withCompletionBlock:(void (^)(void))completionBlock withExceptionBlock:(void (^)(NSException *exception))exceptionBlock
{
    NSInteger idx = 0;
    NSMutableDictionary *extraDict = [NSMutableDictionary dictionary];
    NSMutableString *sequenceScript = [NSMutableString string];
    
    for (SourceLayout *layout in sequence)
    {
        NSString *lName = [NSString stringWithFormat:@"%@%ld", layout.name, (long)idx];
        extraDict[lName] = layout;
        [sequenceScript appendFormat:@"switchToLayout(extraDict['%@']);", lName];
        [sequenceScript appendString:@"waitAnimation();"];
    }
    
    [self runAnimationString:sequenceScript withCompletionBlock:completionBlock withExceptionBlock:exceptionBlock withExtraDictionary:extraDict];
}

-(void)replaceWithSourceLayoutViaScript:(SourceLayout *)layout withCompletionBlock:(void (^)(void))completionBlock withExceptionBlock:(void (^)(NSException *exception))exceptionBlock
{
    NSString *replaceScript = @"switchToLayout(extraDict['toLayout']);";
    NSDictionary *extraDict = @{@"toLayout": layout};
    [self runAnimationString:replaceScript withCompletionBlock:completionBlock withExceptionBlock:exceptionBlock withExtraDictionary:extraDict];
}


-(void)replaceWithSourceLayout:(SourceLayout *)layout
{

    [self replaceWithSourceLayout:layout usingScripts:YES withCompletionBlock:nil];
}

-(void)replaceWithSourceLayout:(SourceLayout *)layout usingScripts:(bool)usingScripts
{
    
    
    [self replaceWithSourceLayout:layout usingScripts:usingScripts withCompletionBlock:nil];
}


-(void)replaceWithSourceLayout:(SourceLayout *)layout usingScripts:(bool)usingScripts withCompletionBlock:(void (^)(void))completionBlock
{

    [self replaceWithSourceData:layout.savedSourceListData usingScripts:usingScripts withCompletionBlock:completionBlock];

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

    
    //[self updateCanvasWidth:layout.canvas_width height:layout.canvas_height];
    //self.frameRate = layout.frameRate;
    [self resetAllRefCounts];

}


-(void)replaceWithSourceData:(NSData *)sourceData usingScripts:(bool)usingScripts withCompletionBlock:(void (^)(void))completionBlock
{
    NSDictionary *diffResult = [self diffSourceListWithData:sourceData];
    NSMutableArray *changedRemove = [NSMutableArray array];
    
    NSArray *changedInputs = diffResult[@"changed"];
    NSArray *removedInputs = diffResult[@"removed"];
    NSArray *newInputs = diffResult[@"new"];
    
    
    NSNumber *aStart = nil;
    JSContext *jCtx = [JSContext currentContext];

    NSString *blockUUID = [CATransaction valueForKey:@"__CS_BLOCK_UUID__"];

    NSArray *sortedSources = [self.sourceListPresentation sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"scriptPriority" ascending:YES]]];
    
    for (NSObject <CSInputSourceProtocol> *src in sortedSources)
    {
        if (!src.active)
        {
            continue;
        }
        
        bool isRemoving = NO;
        if ([removedInputs containsObject:src])
        {
            isRemoving = YES;
        }
        
        [src beforeReplace:isRemoving];
        if (usingScripts)
        {
            [self runTriggerScriptForInput:src withName:@"beforeReplace" usingContext:jCtx];
        }
    }
    if (blockUUID)
    {
        if (jCtx)
        {
            JSValue *mapValue = jCtx[@"block_uuid_map"];
            if (mapValue)
            {
                NSDictionary *blockMap = mapValue.toDictionary;
                NSDictionary *blockObj = blockMap[blockUUID];
                
                if (blockMap && blockObj)
                {
                    aStart = blockObj[@"current_begin_time"];
                    if ([aStart isEqual:[NSNull null]])
                    {
                        aStart = nil;
                    }
                }
            }
        }
    }
    if (!aStart)
    {
        aStart = [NSNumber numberWithDouble:CACurrentMediaTime()];
    }
    
    CATransition *rTrans = nil;
    CABasicAnimation *bTrans = nil;
    
    CSTransitionAnimationDelegate *transitionDelegate = [[CSTransitionAnimationDelegate alloc] init];
    transitionDelegate.addedInputs = newInputs;
    transitionDelegate.changedInputs = changedInputs;
    transitionDelegate.removedInputs = removedInputs;
    
    
    CSLayoutTransition *useTransition = self.transitionInfo;
    if (useTransition.preTransition)
    {
        useTransition = useTransition.preTransition;
    }
    
    
    if (useTransition.transitionName || useTransition.transitionFilter)
    {
        rTrans = [CATransition animation];
        
        if (aStart)
        {
            [rTrans setBeginTime:aStart.floatValue];
        }
        
        
        rTrans.type = useTransition.transitionName;
        rTrans.duration = useTransition.transitionDuration;
        rTrans.removedOnCompletion = YES;
        rTrans.subtype = useTransition.transitionDirection;
        if (useTransition.transitionFilter)
        {
            rTrans.filter = useTransition.transitionFilter;
        }
        
    }
    //We always create a dummy animation so we play nice with scripts that do additional animations. This way we don't do final remove/reveal until the proper time
    NSString *dummyKey = [NSString stringWithFormat:@"__DUMMY_KEY_%f", aStart.floatValue];
    bTrans = [CABasicAnimation animationWithKeyPath:dummyKey];
    bTrans.removedOnCompletion = YES;
    bTrans.fillMode = kCAFillModeForwards;
    bTrans.beginTime = aStart.floatValue;
    if (rTrans)
    {
        bTrans.duration = useTransition.transitionDuration;
    }
    transitionDelegate.useAnimation = rTrans;
    
    bTrans.fromValue = @0;
    bTrans.toValue = @1;
    bTrans.delegate = transitionDelegate;
    if (aStart)
    {
        bTrans.beginTime = aStart.floatValue;
    }
    
    
    
    if (jCtx && rTrans)
    {
        JSValue *runFunc = jCtx[@"addDummyAnimation"];
        [runFunc callWithArguments:@[@(useTransition.transitionDuration)]];
    }
    [CATransaction begin];
    
    [CATransaction setCompletionBlock:^{
        
        for (NSObject<CSInputSourceProtocol> *rSrc in removedInputs)
        {
            [self deleteSource:rSrc];
        }
        
        for (NSObject<CSInputSourceProtocol> *cSrc in changedRemove)
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
    
    
    if (bTrans)
    {
        transitionDelegate.forLayout = self;
        transitionDelegate.fullScreen = useTransition.transitionFullScene;
        
        [self.rootLayer addAnimation:bTrans forKey:bTrans.keyPath];
    }
    
    
    for (NSObject<CSInputSourceProtocol> *rSrc in removedInputs)
    {
        [self deleteSourceFromPresentation:rSrc];
    }
    
    for (NSObject<CSInputSourceProtocol> *cSrc in changedInputs)
    {
        NSObject<CSInputSourceProtocol> *mSrc = [self inputForUUID:cSrc.uuid];
        
        
        [self deleteSourceFromPresentation:mSrc];
        [changedRemove addObject:mSrc];
        
        if (cSrc.layer)
        {
            cSrc.layer.hidden = YES;
            [mSrc.layer.superlayer addSublayer:cSrc.layer];
        }
        [self addSourceToPresentation:cSrc];
    }
    transitionDelegate.changeremoveInputs = changedRemove;
    
    for (NSObject<CSInputSourceProtocol> *nSrc in newInputs)
    {
        
        if (nSrc.layer && !nSrc.layer.superlayer)
        {
            nSrc.layer.hidden = YES;
            [self.rootLayer addSublayer:nSrc.layer];

        }

        [self addSourceToPresentation:nSrc];
    }
    
    sortedSources = [self.sourceListPresentation sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"scriptPriority" ascending:YES]]];
    
    for (NSObject <CSInputSourceProtocol> *src in sortedSources)
    {
        
        if (!src.active)
        {
            continue;
        }
        
        [src afterReplace];
        if (usingScripts)
        {
            [self runTriggerScriptForInput:src withName:@"afterReplace" usingContext:jCtx];
        }
    }
    
    for (NSObject<CSInputSourceProtocol> *nSrc in newInputs)
    {
        
        if (jCtx && rTrans && nSrc.duration && self.transitionInfo.waitForMedia)
        {
            JSValue *runFunc = jCtx[@"addDummyAnimation"];
            [runFunc callWithArguments:@[@(nSrc.duration)]];
            
        }
    }

    [CATransaction commit];

    [self adjustAllInputs];
    
    _noSceneTransactions = NO;
    
    
}


-(bool)containsLayoutNamed:(NSString *)layoutName
{
    for (SourceLayout *clayout in self.containedLayouts)
    {
        if ([clayout.name isEqualToString:layoutName])
        {
            return YES;
        }
    }
    
    return NO;
}

-(bool)containsLayout:(SourceLayout *)layout
{
    return [self.containedLayouts containsObject:layout];
}





-(void)mergeSourceLayoutViaScript:(SourceLayout *)layout
{
    NSString *mergeScript = @"mergeLayout(extraDict['toLayout']);";
    
    NSDictionary *extraDict = @{@"toLayout": layout};
    [self runAnimationString:mergeScript withCompletionBlock:nil withExceptionBlock:nil withExtraDictionary:extraDict];
}


-(void)mergeSourceLayout:(SourceLayout *)toMerge
{
    [self mergeSourceLayout:toMerge usingScripts:YES withCompletionBlock:nil];
}


-(void)mergeSourceLayout:(SourceLayout *)toMerge usingScripts:(bool)usingScripts
{
    [self mergeSourceLayout:toMerge usingScripts:usingScripts withCompletionBlock:nil];
}

-(void)mergeSourceLayout:(SourceLayout *)toMerge usingScripts:(bool)usingScripts withCompletionBlock:(void (^)(void))completionBlock
{
    
    if ([self.containedLayouts containsObject:toMerge])
    {
        return;
    }

    
    [self mergeSourceData:toMerge.savedSourceListData usingScripts:usingScripts withCompletionBlock:completionBlock];

    [self.containedLayouts addObject:toMerge];
    if (self.addLayoutBlock)
    {
        self.addLayoutBlock(toMerge);
    }

}


-(SourceLayout *)sourceLayoutWithRemoved:(SourceLayout *)withRemoved
{
    SourceLayout *retLayout = [self copy];
    retLayout.transitionInfo = nil;
    [retLayout restoreSourceList:[self makeSaveData]];
    
    [retLayout removeSourceLayout:withRemoved usingScripts:NO];
    [retLayout saveSourceList];
    [retLayout clearSourceList];
    return retLayout;

}
-(SourceLayout *)mergedSourceLayout:(SourceLayout *)withLayout
{
    SourceLayout *retLayout = [self copy];
    retLayout.transitionInfo = nil;
    [retLayout restoreSourceList:[self makeSaveData]];
    
    [retLayout mergeSourceLayout:withLayout usingScripts:NO ];
    [retLayout saveSourceList];
    [retLayout clearSourceList];
    return retLayout;
}



-(void)mergeSourceData:(NSData *)withData usingScripts:(bool)usingScripts withCompletionBlock:(void (^)(void))completionBlock
{
    
    NSDictionary *diffResult = [self diffSourceListWithData:withData];
    NSMutableArray *changedRemove = [NSMutableArray array];
    
    NSArray *changedInputs = diffResult[@"changed"];
    NSArray *sameInputs = diffResult[@"same"];
    NSArray *newInputs = diffResult[@"new"];
    NSArray *newScript = diffResult[@"scriptNew"];
    NSArray *existingScript = diffResult[@"scriptExisting"];
    NSNumber *aStart = nil;
    
    
    
    JSContext *jCtx = [JSContext currentContext];
    
    NSString *blockUUID = [CATransaction valueForKey:@"__CS_BLOCK_UUID__"];
    
    
    
    for (NSObject<CSInputSourceProtocol> *src in changedInputs)
    {
        if (!src.active)
        {
            continue;
        }
        [src beforeMerge:YES];
    }
    
    for (NSObject<CSInputSourceProtocol> *src in sameInputs)
    {
        if (!src.active)
        {
            continue;
        }

        [src beforeMerge:NO];
    }

    if (jCtx && usingScripts)
    {
        JSValue *scriptFunc = jCtx[@"runTriggerScriptInput"];
        
        if (scriptFunc)
        {
            
            NSArray *sortedSources = [[changedInputs arrayByAddingObjectsFromArray:existingScript] sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"scriptPriority" ascending:YES]]];

            for (NSObject<CSInputSourceProtocol> *src in sortedSources)
            {
                NSObject<CSInputSourceProtocol> *mSrc = [self inputForUUID:src.uuid];
                if (!mSrc.active)
                {
                    continue;
                }

                [self runTriggerScriptForInput:mSrc withName:@"beforeMerge" usingContext:jCtx];
            }
        }
    }
    
    if (blockUUID)
    {
        if (jCtx)
        {
            JSValue *mapValue = jCtx[@"block_uuid_map"];
            if (mapValue)
            {
                NSDictionary *blockMap = mapValue.toDictionary;
                NSDictionary *blockObj = blockMap[blockUUID];
                if (blockMap && blockObj)
                {
                    aStart = blockObj[@"current_begin_time"];
                    if ([aStart isEqual:[NSNull null]])
                    {
                        aStart = nil;
                    }
                }
            }
        }
    }

    if (!aStart)
    {
        aStart = [NSNumber numberWithDouble:CACurrentMediaTime()];
    }
    
    
    CATransition *rTrans = nil;
    CABasicAnimation *bTrans = nil;
    CSTransitionAnimationDelegate *transitionDelegate = [[CSTransitionAnimationDelegate alloc] init];
    transitionDelegate.addedInputs = newInputs;
    transitionDelegate.changedInputs = changedInputs;
    
    
    CSLayoutTransition *useTransition = self.transitionInfo;
    
    if (useTransition.preTransition)
    {
        useTransition = useTransition.preTransition;
    }
    
    
    if (useTransition.transitionName || useTransition.transitionFilter)
    {
        rTrans = [CATransition animation];
        
        if (aStart)
        {
            [rTrans setBeginTime:aStart.floatValue];
        }
        
        
        rTrans.type = useTransition.transitionName;
        rTrans.duration = useTransition.transitionDuration;
        rTrans.removedOnCompletion = YES;
        rTrans.subtype = useTransition.transitionDirection;
        if (useTransition.transitionFilter)
        {
            rTrans.filter = useTransition.transitionFilter;
        }
        
    }
    
    //We always create a dummy animation so we play nice with scripts that do additional animations. This way we don't do final remove/reveal until the proper time
    NSString *dummyKey = [NSString stringWithFormat:@"__DUMMY_KEY_%f", aStart.floatValue];
    bTrans = [CABasicAnimation animationWithKeyPath:dummyKey];
    bTrans.removedOnCompletion = YES;
    bTrans.fillMode = kCAFillModeForwards;
    if (aStart)
    {
        bTrans.beginTime = aStart.floatValue;
    }
    bTrans.fromValue = @0;
    bTrans.toValue = @1;
    if (rTrans)
    {
        bTrans.duration = useTransition.transitionDuration;
    }
    transitionDelegate.useAnimation = rTrans;
    bTrans.delegate = transitionDelegate;
    
    if (jCtx && rTrans)
    {
        JSValue *runFunc = jCtx[@"addDummyAnimation"];
        [runFunc callWithArguments:@[@(useTransition.transitionDuration)]];
    }

    [CATransaction begin];
    
    [CATransaction setCompletionBlock:^{
        
        for (NSObject<CSInputSourceProtocol> *cSrc in changedRemove)
        {
            [self deleteSource:cSrc];
        }
        
        if (bTrans)
        {
            for (NSObject<CSInputSourceProtocol> *nSrc in newInputs)
            {
                if (nSrc.layer)
                {
                    nSrc.layer.hidden = NO;
                }
            }
                
            
            for (NSObject<CSInputSourceProtocol> *cSrc in changedInputs)
            {
                if (cSrc.layer)
                {
                    cSrc.layer.hidden = NO;
                }
            }
            
            
            
        }
        
        
        if (completionBlock)
        {
            completionBlock();
        }
        
        
    }];
    
    if (bTrans)
    {
        transitionDelegate.forLayout = self;
        transitionDelegate.fullScreen = useTransition.transitionFullScene;
        
        [self.rootLayer addAnimation:bTrans forKey:bTrans.keyPath];
    }
    
    
    for (NSObject<CSInputSourceProtocol> *nSrc in newInputs)
    {
        
        if (nSrc.layer && !nSrc.layer.superlayer)
        {
            nSrc.layer.hidden = YES;
            [self.rootLayer addSublayer:nSrc.layer];

        }

        [self addSourceToPresentation:nSrc];
        

        if (jCtx && rTrans && nSrc.duration && self.transitionInfo.waitForMedia)
        {
            JSValue *runFunc = jCtx[@"addDummyAnimation"];
            [runFunc callWithArguments:@[@(nSrc.duration)]];
            
        }

    }
    
    for (NSObject<CSInputSourceProtocol> *cSrc in changedInputs)
    {
        NSObject<CSInputSourceProtocol> *mSrc = [self inputForUUID:cSrc.uuid];
        [self deleteSourceFromPresentation:mSrc];
        [changedRemove addObject:mSrc];
        
        
        if (cSrc.layer && !cSrc.layer.superlayer)
        {
            cSrc.layer.hidden = YES;
            [mSrc.layer.superlayer addSublayer:cSrc.layer];

        }
        
        
        [self addSourceToPresentation:cSrc];
        [self incrementInputRef:cSrc];
    }
    
    
    transitionDelegate.changeremoveInputs = changedRemove;
    
    
    for (NSObject<CSInputSourceProtocol> *src in changedInputs)
    {
        if (!src.active)
        {
            continue;
        }

        [src afterMerge:YES];
    }
    
    for (NSObject<CSInputSourceProtocol> *src in sameInputs)
    {
        if (!src.active)
        {
            continue;
        }

        [src afterMerge:NO];
    }

    for (NSObject<CSInputSourceProtocol> *src in newInputs)
    {
        if (!src.active)
        {
            continue;
        }

        [src afterMerge:NO];
    }

    
    if (jCtx && usingScripts)
    {
        JSValue *scriptFunc = jCtx[@"runTriggerScriptInput"];
        
        if (scriptFunc)
        {
            NSMutableArray *scriptSrcs = [NSMutableArray arrayWithCapacity:newInputs.count+changedInputs.count+newScript.count];
            [scriptSrcs addObjectsFromArray:newInputs];
            [scriptSrcs addObjectsFromArray:changedInputs];
            [scriptSrcs addObjectsFromArray:newScript];

            
            NSArray *sortedSources = [scriptSrcs sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"scriptPriority" ascending:YES]]];

            for (InputSource *src in sortedSources)
            {
                if (!src.active)
                {
                    continue;
                }

                [self runTriggerScriptForInput:src withName:@"afterMerge" usingContext:jCtx];
            }
        }
    }

    [CATransaction commit];
    [CATransaction flush];
    
    [self adjustAllInputs];
    
}


-(void)removeSourceLayoutViaScript:(SourceLayout *)layout
{
    NSString *removeScript = @"removeLayout(extraDict['toLayout']);";
    NSDictionary *extraDict = @{@"toLayout": layout};
    [self runAnimationString:removeScript withCompletionBlock:nil withExceptionBlock:nil withExtraDictionary:extraDict];
}

-(void)removeSourceLayout:(SourceLayout *)toRemove
{
    [self removeSourceLayout:toRemove usingScripts:YES withCompletionBlock:nil];

}
-(void)removeSourceLayout:(SourceLayout *)toRemove usingScripts:(bool)usingScripts
{
    [self removeSourceLayout:toRemove usingScripts:usingScripts withCompletionBlock:nil];
}

-(void)removeSourceLayout:(SourceLayout *)toRemove usingScripts:(bool)usingScripts withCompletionBlock:(void (^)(void))completionBlock
{
    if (![self.containedLayouts containsObject:toRemove])
    {
        return;
    }


    [self removeSourceData:toRemove.savedSourceListData usingScripts:usingScripts withCompletionBlock:completionBlock];
    
    [self.containedLayouts removeObject:toRemove];
    if (self.removeLayoutBlock)
    {
        self.removeLayoutBlock(toRemove);
    }

}


-(void)removeSourceData:(NSData *)toRemove usingScripts:(bool)usingScripts withCompletionBlock:(void (^)(void))completionBlock
{
    NSDictionary *diffResult = nil;
    diffResult = [self diffSourceListWithData:toRemove];
    NSMutableArray *realRemove = [NSMutableArray array];
    
    NSArray *changedInputs = diffResult[@"changed"];
    NSArray *sameInputs = diffResult[@"same"];
    NSArray *newInputs = diffResult[@"new"];
    //NSArray *newScript = diffResult[@"scriptNew"];
    NSArray *existingScript = diffResult[@"scriptExisting"];

    NSMutableArray *removeInputs = [NSMutableArray arrayWithArray:changedInputs];
    [removeInputs addObjectsFromArray:sameInputs];
    [removeInputs addObjectsFromArray:newInputs];
    NSNumber *aStart = nil;
    JSContext *jCtx = [JSContext currentContext];
    
    NSString *blockUUID = [CATransaction valueForKey:@"__CS_BLOCK_UUID__"];
    
    [CATransaction begin];
    [CATransaction setCompletionBlock:^{
        
        @autoreleasepool {
            for (NSObject<CSInputSourceProtocol> *rSrc in realRemove)
            {
                [self decrementInputRef:rSrc];
                [self deleteSource:rSrc];
            }
            
            if (completionBlock)
            {
                completionBlock();
            }
        }
    }];
    for (NSObject<CSInputSourceProtocol> *src in removeInputs)
    {
        NSObject<CSInputSourceProtocol> *mSrc = [self inputForUUID:src.uuid];
        if (!mSrc.active)
        {
            continue;
        }

        
        [mSrc beforeRemove];
    }

    
    if (jCtx && usingScripts)
    {
        JSValue *scriptFunc = jCtx[@"runTriggerScriptInput"];
        
        if (scriptFunc)
        {
            NSArray *sortedSources = [[removeInputs arrayByAddingObjectsFromArray:existingScript] sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"scriptPriority" ascending:YES]]];

            for (NSObject<CSInputSourceProtocol> *src in sortedSources)
            {
                NSObject<CSInputSourceProtocol> *mSrc = [self inputForUUID:src.uuid];
                if (!mSrc.active)
                {
                    continue;
                }

                [self runTriggerScriptForInput:mSrc withName:@"beforeRemove" usingContext:jCtx];
            }
        }
    }
    
    if (blockUUID)
    {
        if (jCtx)
        {
            JSValue *mapValue = jCtx[@"block_uuid_map"];
            if (mapValue)
            {
                NSDictionary *blockMap = mapValue.toDictionary;
                NSDictionary *blockObj = blockMap[blockUUID];
                if (blockMap && blockObj)
                {
                    aStart = blockObj[@"current_begin_time"];
                    if ([aStart isEqual:[NSNull null]])
                    {
                        aStart = nil;
                    }
                }
            }
        }
    }
    
    if (!aStart)
    {
        aStart = [NSNumber numberWithDouble:CACurrentMediaTime()];
    }
    
    
    CATransition *rTrans = nil;
    CABasicAnimation *bTrans = nil;
    
    CSTransitionAnimationDelegate *transitionDelegate = [[CSTransitionAnimationDelegate alloc] init];
    CSLayoutTransition *useTransition = self.transitionInfo;
    if (useTransition.preTransition)
    {
        useTransition = useTransition.preTransition;
    }

    
    if (useTransition.transitionName || useTransition.transitionFilter)
    {
        rTrans = [CATransition animation];
        
        if (aStart)
        {
            [rTrans setBeginTime:aStart.floatValue];
        }
        
        
        rTrans.type = useTransition.transitionName;
        rTrans.duration = useTransition.transitionDuration;
        rTrans.removedOnCompletion = YES;
        rTrans.subtype = useTransition.transitionDirection;
        if (useTransition.transitionFilter)
        {
            rTrans.filter = useTransition.transitionFilter;
        }
    }
    
    
    //We always create a dummy animation so we play nice with scripts that do additional animations. This way we don't do final remove/reveal until the proper time
    NSString *dummyKey = [NSString stringWithFormat:@"__DUMMY_KEY_%f", aStart.floatValue];
    bTrans = [CABasicAnimation animationWithKeyPath:dummyKey];
    bTrans.removedOnCompletion = YES;
    bTrans.fillMode = kCAFillModeForwards;
    if (aStart)
    {
        bTrans.beginTime = aStart.floatValue;
    }
    bTrans.fromValue = @0;
    bTrans.toValue = @1;
    if (rTrans)
    {
        bTrans.duration = useTransition.transitionDuration;
    }
    transitionDelegate.useAnimation = rTrans;

    bTrans.delegate = transitionDelegate;
    if (jCtx && rTrans)
    {
        JSValue *runFunc = jCtx[@"addDummyAnimation"];
        [runFunc callWithArguments:@[@(useTransition.transitionDuration)]];
    }


    
    
    if (bTrans)
    {
        transitionDelegate.forLayout = self;
        transitionDelegate.fullScreen = useTransition.transitionFullScene;
        
        [self.rootLayer addAnimation:bTrans forKey:bTrans.keyPath];
    }
    
    
    if (useTransition.transitionFullScene)
    {
        [self.rootLayer addAnimation:rTrans forKey:nil];
    }
    
    
    for (NSObject<CSInputSourceProtocol> *rSrc in removeInputs)
    {
        NSObject<CSInputSourceProtocol> *eSrc = [self inputForUUID:rSrc.uuid];
        
        if (eSrc)
        {
            [realRemove addObject:eSrc];
            [self deleteSourceFromPresentation:eSrc];
        }
        
        transitionDelegate.removedInputs = realRemove;
    }
    [CATransaction commit];
    
}







-(bool)hasSources
{
    NSUInteger srcCount = 0;
    bool ret = NO;
    
    if (self.sourceList)
    {
        srcCount = self.sourceList.count;
    }
    
    if (!srcCount)
    {
        if (self.savedSourceListData)
        {
            ret = YES;
        } else {
            ret = NO;
        }
    } else {
        ret = YES;
    }
    
    return ret;
}



-(void)cancelTransition
{
    [self.rootLayer removeAnimationForKey:kCATransition];
    for (InputSource *src in self.sourceList)
    {
        [src.layer removeAnimationForKey:kCATransition];
    }
}







-(void)restoreSourceList:(NSData *)withData
{
    
    if (self.savedSourceListData)
    {
        
        [CATransaction begin];
        [CATransaction setCompletionBlock:^{
            for (NSObject<CSInputSourceProtocol> *nSrc in self.sourceList)
            {
                if (nSrc.layer)
                {
                    [((InputSource *)nSrc) buildLayerConstraints];
                }
            }
        }];
        NSMutableArray *oldSourceList = self.sourceList;
        
        
        self.sourceList = [NSMutableArray array];
        _uuidMap = [NSMutableDictionary dictionary];
        self.sourceListPresentation = [NSMutableArray array];
        _uuidMapPresentation = [NSMutableDictionary dictionary];

        
        
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
        
        
        
        for (NSObject<CSInputSourceProtocol> *nSrc in srcList)
        {
            [self addSource:nSrc];
        }
        
        
        for(NSObject<CSInputSourceProtocol> *src in oldSourceList)
        {
            [src beforeDelete];
            [src removeObserver:self forKeyPath:@"depth"];
            [src.layer removeFromSuperlayer];
        }

        
        
        [CATransaction commit];

    }
}


-(bool)containsInput:(NSObject<CSInputSourceProtocol> *)cInput
{
    NSArray *listCopy = [self sourceListOrdered];
    
    for (NSObject<CSInputSourceProtocol> *testSrc in listCopy)
    {
        if (testSrc == cInput)
        {
            return YES;
        }
    }

    return NO;
}


-(void)addSourceToPresentation:(NSObject<CSInputSourceProtocol> *)addSource
{
    NSObject<CSInputSourceProtocol> *eSrc = _uuidMapPresentation[addSource.uuid];
    if (eSrc)
    {
        return;
    }
    
    _uuidMapPresentation[addSource.uuid] = addSource;
    @synchronized(self)
    {
        [self.sourceListPresentation addObject:addSource];
    }
}


-(void)deleteSourceFromPresentation:(NSObject<CSInputSourceProtocol> *)delSource
{
    @synchronized (self) {
        [self.sourceListPresentation removeObject:delSource];
    }

    InputSource *uSrc;
    
    uSrc = _uuidMapPresentation[delSource.uuid];
    if ([uSrc isEqual:delSource])
    {
        [_uuidMapPresentation removeObjectForKey:delSource.uuid];
    }

}
-(void)deleteSource:(NSObject<CSInputSourceProtocol> *)delSource
{
    
    NSObject<CSInputSourceProtocol> *uSrc;

    uSrc = _uuidMapPresentation[delSource.uuid];
    if ([uSrc isEqual:delSource])
    {
        [_uuidMapPresentation removeObjectForKey:delSource.uuid];
    }
    
    //[self.sourceList removeObject:delSource];
    if (delSource == self.layoutTimingSource)
    {
        self.layoutTimingSource = nil;
    }
    
    [delSource.layer removeFromSuperlayer];

   // uSrc = _uuidMap[delSource.uuid];
    if ([self.sourceList containsObject:delSource])
    {
        [delSource beforeDelete];

        uSrc = _uuidMap[delSource.uuid];
        if (uSrc && uSrc == delSource)
        {
            [_uuidMap removeObjectForKey:delSource.uuid];
        }
        
        
        [self willChangeValueForKey:@"topLevelSourceList"];
        @synchronized (self) {
            [[self mutableArrayValueForKey:@"sourceList" ] removeObject:delSource];
            [self.sourceListPresentation removeObject:delSource];
        }
        [self generateTopLevelSourceList];
        [self didChangeValueForKey:@"topLevelSourceList"];
        
        
        //[self.sourceList removeObject:delSource];
        
        [delSource removeObserver:self forKeyPath:@"depth"];
        [[NSNotificationCenter defaultCenter] postNotificationName:CSNotificationInputDeleted  object:delSource userInfo:nil];
    }
    delSource.sourceLayout = nil;

    
    

}



-(void)setupMIDI
{
    [NSApp registerMIDIResponder:self];
    for (NSObject<CSInputSourceProtocol> *src in self.sourceList)
    {
        if (src.layer)
        {
            [NSApp registerMIDIResponder:(InputSource *)src];
        }

    }
}


-(void) adjustAllInputs
{
    
    NSArray *copiedInputs = self.sourceListPresentation.copy;
    
    
    for (NSObject<CSInputSourceProtocol> *src in copiedInputs)
    {
     
        if (src.layer)
        {
            InputSource *vSrc = (InputSource *)src;
            
            vSrc.needsAdjustPosition = YES;
            vSrc.needsAdjustment = YES;
        }
    }
}



-(void) addSource:(NSObject<CSInputSourceProtocol> *)newSource
{
    [self addSource:newSource withParentLayer:self.rootLayer];

}


-(void) addSource:(NSObject<CSInputSourceProtocol> *)newSource withParentLayer:(CALayer *)parentLayer
{
    
    newSource.sourceLayout = self;
    newSource.is_live = self.isActive;
    
    [self addSourceToPresentation:newSource];
    
    [[self mutableArrayValueForKey:@"sourceList" ] addObject:newSource];
    if (newSource.layer && !newSource.layer.superlayer)
    {
        [CATransaction begin];
        [CATransaction setCompletionBlock:^{
            [((InputSource *)newSource) buildLayerConstraints];
          
        }];
        
        [parentLayer addSublayer:newSource.layer];
        [CATransaction commit];
    }

    
    
    
    [_uuidMap setObject:newSource forKey:newSource.uuid];
    
    [self incrementInputRef:newSource];
    
    [self generateTopLevelSourceList];
    [NSApp registerMIDIResponder:newSource];
    [newSource afterAdd];
    
    [newSource addObserver:self forKeyPath:@"depth" options:NSKeyValueObservingOptionNew context:nil];
    [[NSNotificationCenter defaultCenter] postNotificationName:CSNotificationInputAdded object:newSource userInfo:nil];
}


-(void)clearSourceList
{
    self.rootLayer.sublayers = [NSArray array];
    for (NSObject<CSInputSourceProtocol> *src in self.sourceList)
    {
        [src removeObserver:self forKeyPath:@"depth"];
    }
    @synchronized(self)
    {
        [self.sourceList removeAllObjects];
        [self.sourceListPresentation removeAllObjects];
        [self generateTopLevelSourceList];

        
    }
    [_uuidMap removeAllObjects];
    [_uuidMapPresentation removeAllObjects];
}




-(void)setIsActive:(bool)isActive
{
    for(NSObject <CSInputSourceProtocol>*src in self.sourceListOrdered)
    {
        src.is_live = isActive;
    }
    
    _isActive = isActive;
}

-(bool)isActive
{
    return _isActive;
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

    for (NSObject<CSInputSourceProtocol> *src in listCopy)
    {
        
        if (!src.layer)
        {
            continue;
        }
        
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
                    ret = (InputSource *)src;
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
        
        
        
        for (NSObject<CSInputSourceProtocol> *isource in listCopy)
        {
            
            
            if (needsResize && isource.layer)
            {
                InputSource *vsource = (InputSource *)isource;
                vsource.needsAdjustPosition = YES;
                vsource.needsAdjustment = YES;
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



-(void)modifyUUID:(NSString *)uuid withBlock:(void (^)(NSObject<CSInputSourceProtocol> *input))withBlock
{
    NSObject<CSInputSourceProtocol> *useSource = [self inputForUUID:uuid];
    if (useSource)
    {
        withBlock(useSource);
    }
}




-(NSObject<CSInputSourceProtocol> *)inputForName:(NSString *)name
{
    
    NSArray *useList = self.sourceListPresentation;
    
    for (NSObject<CSInputSourceProtocol> *tSrc in useList)
    {
        if (tSrc.name && [tSrc.name isEqualToString:name])
        {
            return tSrc;
        }
    }
    return nil;
}


-(NSObject<CSInputSourceProtocol> *)inputForUUID:(NSString *)uuid
{
    return [_uuidMapPresentation objectForKey:uuid];
}

-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context
{
    if ([keyPath isEqualToString:@"depth"])
    {
        [self generateTopLevelSourceList];
    }
}

-(void)dealloc
{
    
    for (NSObject<CSInputSourceProtocol> *src in self.sourceList)
    {
        [src removeObserver:self forKeyPath:@"depth"];
    }
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
}

@end
