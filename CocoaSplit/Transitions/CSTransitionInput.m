//
//  CSTransitionInput.m
//  CocoaSplit
//
//  Created by Zakk on 3/27/18.
//

#import "CSTransitionInput.h"
#import "CSInputLayoutTransitionViewController.h"

@implementation CSTransitionInput
@synthesize holdDuration = _holdDuration;
    @synthesize inputSource = _inputSource;
    
    -(instancetype) init
    {
        if (self = [super init])
        {
            self.transitionAfterPre = YES;
            self.canToggle = YES;
        }
        return self;
    }
    
-(id)copyWithZone:(NSZone *)zone
{
    CSTransitionInput *newObj = [super copyWithZone:zone];
    if (newObj)
    {
        newObj.configuredInputSource = self.configuredInputSource;
        newObj.inputSourceSavedata = self.inputSourceSavedata;
        newObj.holdDuration = self.holdDuration;
        newObj.waitForMedia = self.waitForMedia;
        newObj.transitionAfterPre = self.transitionAfterPre;
        newObj.wholeLayout = self.wholeLayout;
    }
    return newObj;
}

-(void)saveAndClearInputSource
{
    if (_inputSource)
    {
        
        self.inputSourceSavedata = [NSKeyedArchiver archivedDataWithRootObject:_inputSource];
        self.inputSource = nil;
        NSLog(@"SAVE AND CLEAR");
    }
}


-(void)encodeWithCoder:(NSCoder *)aCoder
{
    [super encodeWithCoder:aCoder];
    if (_inputSource)
    {
        
        self.inputSourceSavedata = [NSKeyedArchiver archivedDataWithRootObject:_inputSource];
        
        [aCoder encodeObject:self.inputSourceSavedata forKey:@"inputSourceSavedata"];
    }
    [aCoder encodeObject:self.holdDuration forKey:@"holdDuration"];
    [aCoder encodeBool:self.waitForMedia forKey:@"waitForMedia"];
    [aCoder encodeBool:self.transitionAfterPre forKey:@"transitionAfterPre"];
    [aCoder encodeBool:self.wholeLayout forKey:@"wholeLayout"];
    [aCoder encodeObject:_savedInputName forKey:@"savedInputName"];
    
}


-(instancetype)initWithCoder:(NSCoder *)aDecoder
{
    if (self = [super initWithCoder:aDecoder])
    {
        self.inputSourceSavedata = [aDecoder decodeObjectForKey:@"inputSourceSavedata"];
        self.holdDuration = [aDecoder decodeObjectForKey:@"holdDuration"];
        if ([aDecoder containsValueForKey:@"waitForMedia"])
        {
            self.waitForMedia = [aDecoder decodeBoolForKey:@"waitForMedia"];
        }
        
        if ([aDecoder containsValueForKey:@"transitionAfterPre"])
        {
            self.transitionAfterPre = [aDecoder decodeBoolForKey:@"transitionAfterPre"];
        }
        
        if ([aDecoder containsValueForKey:@"wholeLayout"])
        {
            self.wholeLayout = [aDecoder decodeBoolForKey:@"wholeLayout"];
        }
        
        _savedInputName = [aDecoder decodeObjectForKey:@"savedInputName"];
    }
    
    return self;
}




+(NSArray *)subTypes
{
    return @[];
}

-(bool)usesPreTransitions
{
    return YES;
}

-(bool)usesPostTransitions
{
    return YES;
}

+(NSString *)transitionCategory
{
    return @"Source";
}


-(NSString *)name
{

    
    NSString *ret = [super name];
    
    if (!ret)
    {
        if (_savedInputName)
        {
            ret = _savedInputName;
        }
    }
    
    if (!ret && self.inputSource)
    {
        
        ret = self.inputSource.name;
    }
    return ret;
}

-(void)setInputSource:(NSObject<CSInputSourceProtocol> *)inputSource
{
    _inputSource = inputSource;
    if (inputSource)
    {
        _savedInputName = inputSource.name;
    }
    if (inputSource && inputSource.isVideo)
    {
        [(InputSource *)inputSource frameTick];
        [(InputSource *)inputSource autoSize];

        
    }
}
    
    
    
-(NSObject<CSInputSourceProtocol> *)inputSource
{
    if (!_inputSource)
    {
        _inputSource = [self restoreInputSource];
        if (!_inputSource)
        {
            _inputSource = [self getInputSource];
        }
        if (_inputSource && _inputSource.isVideo)
        {
            [(InputSource *)_inputSource frameTick];
            [(InputSource *)_inputSource autoSize];
            
            
        }
    }
    _savedInputName = _inputSource.name;
    return _inputSource;
}
    
    
-(void)setHoldDuration:(NSNumber *)holdDuration
{
    _holdDuration = holdDuration;
}

    
    
-(NSObject <CSInputSourceProtocol> *)getInputSource
{
    return self.configuredInputSource;
}

    
-(NSNumber *)holdDuration
{
    if (_holdDuration)
    {
        return _holdDuration;
    }
    
    return self.duration;
}

-(NSString *)preChangeAction:(SourceLayout *)targetLayout
{

    if (!self.inputSource)
    {
        return nil;
    }
    
    self.inputSource.persistent = YES;
    self.inputSource.isTransitionInput = YES;

    self.inputSourceUUID = self.inputSource.uuid;
    NSMutableString *scriptRet = [NSMutableString string];
    [scriptRet appendString:@"var usePreTrans = null;"];
    if (self.preTransition)
    {
        [scriptRet appendString:@"var actionScript = self.preTransition.preReplaceAction();"];
        [scriptRet appendString:@"if (actionScript) {var prelTrans = (new Function('self', actionScript))(self.preTransition); if (prelTrans) { usePreTrans = prelTrans.transition;} }"];
        [scriptRet appendString:@"self.realPreTransition = usePreTrans;"];
    }
    
    [scriptRet appendString:@"var transitionCSInput = addInputToLayoutForTransition(self.inputSource, self.realPreTransition, getCurrentLayout(), self.wholeLayout);"];
    
    if (self.preTransition)
    {
        [scriptRet appendString:@"var postPreScript = self.preTransition.postReplaceAction();"];
        [scriptRet appendString:@"if (postPreScript) { (new Function('self', postPreScript))(self.preTransition);}"];
    }
    
    
    if (self.isToggle)
    {
        return scriptRet;
    }
    
    
    if (self.waitForMedia)
    {
        [scriptRet appendString:@"transitionCSInput.waitAnimation(self.inputSource.duration);"];
    }
    self.realHoldDuration = self.holdDuration.floatValue;
    
    if (self.realHoldDuration > 0.0f)
    {
        [scriptRet appendString:@"transitionCSInput.waitAnimation(self.realHoldDuration);"];
    }

    if (self.transitionAfterPre)
    {
        [scriptRet appendString:@"waitAnimation();"];
    }
    return scriptRet;
}


-(NSString *)postChangeAction:(SourceLayout *)targetLayout
{
    
    NSMutableString *scriptRet = [NSMutableString string];
    [scriptRet appendString:@"var usePostTrans = null;"];
    
    if (self.postTransition)
    {
        [scriptRet appendString:@"var actionScript = self.postTransition.preRemoveAction();"];
        [scriptRet appendString:@"if (actionScript) {var prerTrans = (new Function('self', actionScript))(self.postTransition); if (prerTrans) { usePostTrans = prerTrans.transition;} }"];
        [scriptRet appendString:@"self.realPostTransition = usePostTrans;"];
    }
    [scriptRet appendString:@"removeInputFromLayout(self.inputSource, self.realPostTransition, getCurrentLayout(), self.wholeLayout);"];
    if (self.postTransition)
    {
        [scriptRet appendString:@"var postPostScript = self.postTransition.postRemoveAction();"];
        [scriptRet appendString:@"if (postPostScript) { (new Function('self', postPostScript))(self.postTransition);}"];
    }
    
    [scriptRet appendString:@"self.saveAndClearInputSource();"];
    
    //[scriptRet appendString:@"self.inputSource = null;"];
    return scriptRet;
}

-(NSObject<CSInputSourceProtocol> *)restoreInputSource
{
    NSObject<CSInputSourceProtocol> *ret = nil;
    if (self.inputSourceSavedata)
    {
        ret = [NSKeyedUnarchiver unarchiveObjectWithData:self.inputSourceSavedata];
    }
    
    return ret;
}

-(NSViewController<CSLayoutTransitionViewProtocol> *)configurationViewController
{
    CSInputLayoutTransitionViewController *vc = [[CSInputLayoutTransitionViewController alloc] init];
    vc.transition = self;
    return vc;
}
@end
