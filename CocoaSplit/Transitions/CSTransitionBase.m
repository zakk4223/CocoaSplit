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
        self.uuid = [NSUUID UUID].UUIDString;
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

-(NSString *)preReplaceAction:(SourceLayout *)targetLayout
{
    return [self preChangeAction:targetLayout];
}

-(NSString *)postReplaceAction:(SourceLayout *)targetLayout
{
    return [self postChangeAction:targetLayout];
}


-(NSString *)preMergeAction:(SourceLayout *)targetLayout
{
    return [self preChangeAction:targetLayout];
}
-(NSString *)postMergeAction:(SourceLayout *)targetLayout
{
    return [self postChangeAction:targetLayout];
}

-(NSString *)preRemoveAction:(SourceLayout *)targetLayout
{
    return [self preChangeAction:targetLayout];
}

-(NSString *)postRemoveAction:(SourceLayout *)targetLayout
{
    return [self postChangeAction:targetLayout];
}

-(NSViewController<CSLayoutTransitionViewProtocol> *)configurationViewController
{
    return nil;
}

@end
