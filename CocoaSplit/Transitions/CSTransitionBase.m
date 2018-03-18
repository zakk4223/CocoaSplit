//
//  CSTransitionBase.m
//  CocoaSplit
//
//  Created by Zakk on 3/16/18.
//

#import "CSTransitionBase.h"

@implementation CSTransitionBase


-(instancetype)init
{
    if (self = [super init])
    {
        self.duration = @1.0f;
    }
    
    return self;
}

-(id)copyWithZone:(NSZone *)zone
{
    CSTransitionBase *newObj = [[self.class alloc] init];
    newObj.duration = self.duration;
    newObj.name = self.name;
    newObj.subType = self.subType;
    return newObj;
}


-(void)setName:(NSString *)name
{
    _name = name;
}

-(NSString *)name
{
    return _name;
}


+(NSString *)transitionCategory
{
    return @"Unknown";
}


+(NSArray *)subTypes
{
    return @[];
}

-(NSString *)preChangeAction:(SourceLayout *)targetLayout
{
    return nil;
}

-(NSString *)postChangeAction:(SourceLayout *)targetLayout
{
    return nil;
}

-(NSViewController<CSLayoutTransitionViewProtocol> *)configurationViewController
{
    return nil;
}

@end
