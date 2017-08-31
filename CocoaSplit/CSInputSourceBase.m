//
//  CSInputSourceBase.m
//  CocoaSplit
//
//  Created by Zakk on 6/26/17.
//  Copyright © 2017 Zakk. All rights reserved.
//

#import "CSInputSourceBase.h"
#import "CaptureController.h"

@implementation CSInputSourceBase


-(instancetype) init
{
    if (self = [super init])
    {

        [self basecommonInit];
    }
    
    return self;
}



-(void)basecommonInit
{
    self.attachedInputs = [NSMutableArray array];
    self.active = YES;
    self.scriptPriority = 0;

}


-(instancetype)copyWithZone:(NSZone *)zone
{
    CSInputSourceBase *newCopy = [[[self class] allocWithZone:zone] init];
    newCopy.is_live = self.is_live;
    newCopy.name = self.name;
    newCopy.uuid = self.uuid;
    newCopy.active = self.active;
    newCopy.depth = self.depth;
    newCopy.scriptPriority = self.scriptPriority;
    newCopy.script_afterAdd = self.script_afterAdd;
    newCopy.script_beforeDelete = self.script_beforeDelete;
    newCopy.script_frameTick = self.script_frameTick;
    newCopy.script_beforeMerge = self.script_beforeMerge;
    newCopy.script_afterMerge = self.script_afterMerge;
    newCopy.script_beforeRemove = self.script_beforeRemove;
    newCopy.script_beforeReplace = self.script_beforeReplace;
    newCopy.script_afterReplace = self.script_afterReplace;
    newCopy.scriptAlwaysRun = self.scriptAlwaysRun;
    return newCopy;
}


-(void)createUUID
{
    CFUUIDRef tmpUUID = CFUUIDCreate(NULL);
    self.uuid = (__bridge_transfer NSString *)CFUUIDCreateString(NULL, tmpUUID);
    CFRelease(tmpUUID);
    
}


-(void)afterAdd
{
    return;
}

-(void)beforeDelete
{
    return;
}
-(void)beforeMerge:(bool)changed;
{
    return;
}
-(void)afterMerge:(bool)changed
{
    return;
}
-(void)beforeRemove
{
    return;
}
-(void)beforeReplace:(bool)removing
{
    return;
}
-(void)afterReplace
{
    return;
}

-(void)frameTick
{
    if (self.script_frameTick)
    {
        if (!_scriptContext)
        {
            _scriptContext = [[CaptureController sharedCaptureController] setupJavascriptContext];
        }
        //addCtx[@"source"] = self;
        
        [_scriptContext evaluateScript:self.script_frameTick];

    }
    return;
}


-(bool)isDifferentInput:(NSObject<CSInputSourceProtocol> *)from
{
    return ![self.uuid isEqualToString:from.uuid];
}

-(NSImage *)libraryImage
{
    return nil;
}

-(NSViewController *)configurationViewController
{
    return nil;
}

-(void)encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeObject:self.name forKey:@"name"];
    [aCoder encodeObject:self.uuid forKey:@"uuid"];
    
//    [aCoder encodeFloat:self.depth forKey:@"CAdepth"];
    [aCoder encodeObject:self.script_afterAdd forKey:@"script_afterAdd"];
    [aCoder encodeObject:self.script_beforeDelete forKey:@"script_beforeDelete"];
    [aCoder encodeObject:self.script_frameTick forKey:@"script_frameTick"];
     [aCoder encodeObject:self.script_beforeMerge forKey:@"script_beforeMerge"];
    [aCoder encodeObject:self.script_afterMerge forKey:@"script_afterMerge"];
    [aCoder encodeObject:self.script_beforeRemove forKey:@"script_beforeRemove"];
    [aCoder encodeObject:self.script_beforeReplace forKey:@"script_beforeReplace"];
    [aCoder encodeObject:self.script_afterReplace forKey:@"script_afterReplace"];
    [aCoder encodeInteger:self.scriptPriority forKey:@"scriptPriority"];
    [aCoder encodeBool:self.scriptAlwaysRun forKey:@"scriptAlwaysRun"];
}

-(instancetype)initWithCoder:(NSCoder *)aDecoder {
    
    [self basecommonInit];
    
    self.name = [aDecoder decodeObjectForKey:@"name"];
    self.uuid = [aDecoder decodeObjectForKey:@"uuid"];
    
    //self.depth = [aDecoder decodeFloatForKey:@"CAdepth"];
    self.script_afterAdd = [aDecoder decodeObjectForKey:@"script_afterAdd"];
    self.script_beforeDelete = [aDecoder decodeObjectForKey:@"script_beforeDelete"];
    self.script_frameTick = [aDecoder decodeObjectForKey:@"script_frameTick"];
    self.script_beforeMerge = [aDecoder decodeObjectForKey:@"script_beforeMerge"];
    self.script_afterMerge = [aDecoder decodeObjectForKey:@"script_afterMerge"];
    self.script_beforeRemove = [aDecoder decodeObjectForKey:@"script_beforeRemove"];
    self.script_beforeReplace = [aDecoder decodeObjectForKey:@"script_beforeReplace"];
    self.script_afterReplace = [aDecoder decodeObjectForKey:@"script_afterReplace"];
    if ([aDecoder containsValueForKey:@"scriptPriority"])
    {
        self.scriptPriority = [aDecoder decodeIntegerForKey:@"scriptPriority"];
    }
    
    if ([aDecoder containsValueForKey:@"scriptAlwaysRun"])
    {
        self.scriptAlwaysRun = [aDecoder decodeBoolForKey:@"scriptAlwaysRun"];
    }
    
    
    
    return self;
}

/*
-(NSString *)script_beforeDeleteCombined;
@property (readonly) NSString *script_frameTickCombined;
@property (readonly) NSString *script_beforeMergeCombined;
@property (readonly) NSString *script_afterMergeCombined;
@property (readonly) NSString *script_beforeRemoveCombined;
@property (readonly) NSString *script_beforeReplaceCombined;
@property (readonly) NSString *script_afterReplaceCombined;
*/


@end
