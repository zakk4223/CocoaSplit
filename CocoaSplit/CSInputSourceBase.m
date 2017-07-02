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
        self.attachedInputs = [NSMutableArray array];
        self.active = YES;
    }
    
    return self;
}


-(void)createUUID
{
    CFUUIDRef tmpUUID = CFUUIDCreate(NULL);
    self.uuid = (__bridge_transfer NSString *)CFUUIDCreateString(NULL, tmpUUID);
    CFRelease(tmpUUID);
    
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

-(void)willDelete
{
    return;
}

-(bool)isDifferentInput:(NSObject<CSInputSourceProtocol> *)from
{
    return YES;
}

-(NSImage *)libraryImage
{
    return nil;
}

-(NSViewController *)configurationViewController
{
    return nil;
}

-(void)wasAdded
{
    if (self.script_afterAdd)
    {
        JSContext *addCtx = [[CaptureController sharedCaptureController] setupJavascriptContext];
        addCtx[@"source"] = self;
        [addCtx evaluateScript:self.script_afterAdd];
    }
}


-(void)mergedIntoLayout:(bool)changed
{
    return;
}

-(void)removedFromLayout:(bool)changed
{
    return;
}

-(void)replacedWithLayout
{
    return;
}

-(void)replacingIntoLayout
{
    return;
}


-(void)encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeObject:self.name forKey:@"name"];
    [aCoder encodeObject:self.uuid forKey:@"uuid"];
    [aCoder encodeFloat:self.depth forKey:@"CAdepth"];
    [aCoder encodeObject:self.script_afterAdd forKey:@"script_afterAdd"];
    [aCoder encodeObject:self.script_beforeDelete forKey:@"script_beforeDelete"];
    [aCoder encodeObject:self.script_frameTick forKey:@"script_frameTick"];
    [aCoder encodeObject:self.script_beforeMerge forKey:@"script_beforeMerge"];
    [aCoder encodeObject:self.script_afterMerge forKey:@"script_afterMerge"];
    [aCoder encodeObject:self.script_beforeRemove forKey:@"script_beforeRemove"];
    [aCoder encodeObject:self.script_beforeReplace forKey:@"script_beforeReplace"];
    [aCoder encodeObject:self.script_afterReplace forKey:@"script_afterReplace"];


}

-(instancetype)initWithCoder:(NSCoder *)aDecoder {
    
    if (self = [self init])
    {
        self.name = [aDecoder decodeObjectForKey:@"name"];
        self.uuid = [aDecoder decodeObjectForKey:@"uuid"];
        self.depth = [aDecoder decodeFloatForKey:@"CAdepth"];
        self.script_afterAdd = [aDecoder decodeObjectForKey:@"script_afterAdd"];
        self.script_beforeDelete = [aDecoder decodeObjectForKey:@"script_beforeDelete"];
        self.script_frameTick = [aDecoder decodeObjectForKey:@"script_frameTick"];
        self.script_beforeMerge = [aDecoder decodeObjectForKey:@"script_beforeMerge"];
        self.script_afterMerge = [aDecoder decodeObjectForKey:@"script_afterMerge"];
        self.script_beforeRemove = [aDecoder decodeObjectForKey:@"script_beforeRemove"];
        self.script_beforeReplace = [aDecoder decodeObjectForKey:@"script_beforeReplace"];
        self.script_afterReplace = [aDecoder decodeObjectForKey:@"script_afterReplace"];

    }
    
    
    return self;
}


@end
