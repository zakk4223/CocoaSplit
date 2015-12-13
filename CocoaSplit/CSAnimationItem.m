//
//  CSAnimationItem.m
//  CocoaSplit
//
//  Created by Zakk on 3/20/15.
//  Copyright (c) 2015 Zakk. All rights reserved.
//

#import "CSAnimationItem.h"
#import "SourceLayout.h"

@implementation CSAnimationItem



-(instancetype)init
{
    if (self = [super init])
    {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(sourceWasDeleted:) name:CSNotificationInputDeleted object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(sourceWasAdded:) name:CSNotificationInputAdded object:nil];
        [self createUUID];
        self.refCount = 0;
    }
    
    return self;
}


-(void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


-(void)encodeWithCoder:(NSCoder *)aCoder
{
    [self removeDetachedInputs];
    
    [aCoder encodeObject:self.name forKey:@"name"];
    [aCoder encodeObject:self.module_name forKey:@"module_name"];
    [aCoder encodeObject:self.inputs forKey:@"inputs"];
    if (self.uuid)
    {
        [aCoder encodeObject:self.uuid forKey:@"uuid"];
    }
}

-(instancetype)initWithCoder:(NSCoder *)aDecoder
{
    if (self = [self init])
    {
        self.name = [aDecoder decodeObjectForKey:@"name"];
        self.module_name = [aDecoder decodeObjectForKey:@"module_name"];
        self.inputs = [aDecoder decodeObjectForKey:@"inputs"];
        if ([aDecoder containsValueForKey:@"uuid"])
        {
            self.uuid = [aDecoder decodeObjectForKey:@"uuid"];
        }
    }
    
    return self;
}


-(void)createUUID
{
    CFUUIDRef tmpUUID = CFUUIDCreate(NULL);
    self.uuid = (__bridge_transfer NSString *)CFUUIDCreateString(NULL, tmpUUID);
    CFRelease(tmpUUID);
    
}

-(instancetype)copyWithZone:(NSZone *)zone
{
    CSAnimationItem *newItem = [[CSAnimationItem allocWithZone:zone] init];
    newItem.module_name = self.module_name;
    newItem.inputs = self.inputs;
    newItem.name = self.name;
    return newItem;
}


-(void)removeDetachedInputs
{
    for (NSMutableDictionary *inp in self.inputs)
    {
        NSString *inputType = inp[@"type"];
        if ([inputType isEqualToString:@"input"])
        {
            InputSource *inpsrc = inp[@"value"];
            if (!inpsrc || [inpsrc isEqual:[NSNull null]])
            {
                continue;
            }
            
            if (!inpsrc.sourceLayout || ![inpsrc.sourceLayout containsInput:inpsrc])
            {                
                inp[@"value"] = [NSNull null];
            }
        }
    }
}


-(void)sourceWasDeleted:(NSNotification *)notification
{
    InputSource *srcDel = notification.object;
    
    
    for (NSMutableDictionary *inp in self.inputs)
    {
        NSString *inputType = inp[@"type"];
        if ([inputType isEqualToString:@"input"])
        {
            InputSource *inpsrc = inp[@"value"];
            if (inpsrc == srcDel && inpsrc.sourceLayout == srcDel.sourceLayout)
            {
                inp[@"deletedUUID"] = srcDel.uuid;
                inp[@"value"] = [NSNull null];
            }
        }
    }
}


-(void)sourceWasAdded:(NSNotification *)notification
{
    InputSource *srcAdd = notification.object;
    
    for (NSMutableDictionary *inp in self.inputs)
    {
        NSString *inputType = inp[@"type"];
        if ([inputType isEqualToString:@"input"])
        {
            NSString *inpuuid = inp[@"deletedUUID"];
            if (inpuuid && [inpuuid isEqualToString:srcAdd.uuid])
            {
                [inp removeObjectForKey:@"deletedUUID"];
                inp[@"value"] = srcAdd;
            }
        }
    }
}



-(void)purgeInputSource:(InputSource *)src
{
    for (NSMutableDictionary *inp in self.inputs)
    {
        NSString *inputType = inp[@"type"];
        if ([inputType isEqualToString:@"input"])
        {
            InputSource *inpsrc = inp[@"value"];
            if (inpsrc == src)
            {
                inp[@"value"] = [NSNull null];
            }
        }
    }
}


-(instancetype)initWithDictionary:(NSDictionary *)dict moduleName:(NSString *)moduleName
{
    if (self = [self init])
    {
        
        self.module_name = moduleName;
        
        self.name = [dict objectForKey:@"name"];
        NSArray *inputNames = [dict objectForKey:@"inputs"];
        NSArray *paramNames = [dict objectForKey:@"params"];
    
        self.inputs = [NSMutableArray array];
        
        for (NSString *iname in inputNames)
        {
            NSMutableDictionary *inputDict = [NSMutableDictionary dictionary];
            inputDict[@"type"] = @"input";
            inputDict[@"label"] = iname;
            inputDict[@"value"] = [NSNull null];
            
            [self.inputs addObject:inputDict];
        }
        
        for (NSString *iname in paramNames)
        {
            NSMutableDictionary *inputDict = [NSMutableDictionary dictionary];
            inputDict[@"type"] = @"param";
            inputDict[@"label"] = iname;
            inputDict[@"value"] = [NSNull null];
            [self.inputs addObject:inputDict];
        }
        
        NSMutableDictionary *liveDict = [NSMutableDictionary dictionary];
        liveDict[@"type"] = @"bool";
        liveDict[@"label"] = @"onLive";
        liveDict[@"value"] = @NO;
        
        [self.inputs addObject:liveDict];
    }
    
    return self;
}

-(bool)onLive
{
    bool ret = NO;
    for (NSDictionary *input in self.inputs)
    {
        if ([input[@"label"] isEqualToString:@"onLive"])
        {
            ret = [input[@"value"] boolValue];
            
            if (ret)
            {
                break;
            }
        }
    }
    return ret;
}




@end
