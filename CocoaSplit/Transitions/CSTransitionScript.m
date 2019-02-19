//
//  CSTransitionScript.m
//  CocoaSplit
//
//  Created by Zakk on 3/29/18.
//

#import "CSTransitionScript.h"
#import "CSScriptTransitionViewController.h"

@implementation CSTransitionScript


-(instancetype)copyWithZone:(NSZone *)zone
{
    CSTransitionScript *newObj = [super copyWithZone:zone];
    newObj.preTransitionScript = self.preTransitionScript;
    newObj.postTransitionScript = self.postTransitionScript;
    return newObj;
}

-(void)encodeWithCoder:(NSCoder *)aCoder
{
    [super encodeWithCoder:aCoder];
    [aCoder encodeObject:self.preTransitionScript forKey:@"preTransitionScript"];
    [aCoder encodeObject:self.postTransitionScript forKey:@"postTransitionScript"];
}

-(instancetype)initWithCoder:(NSCoder *)aDecoder
{
    if (self = [super initWithCoder:aDecoder])
    {
        self.preTransitionScript = [aDecoder decodeObjectForKey:@"preTransitionScript"];
        self.postTransitionScript = [aDecoder decodeObjectForKey:@"postTransitionScript"];
    }
    
    return self;
}

-(instancetype)init
{
    if (self = [super init])
    {
        self.name = @"Script";
        self.canToggle = YES;
    }
    
    return self;
}


+(NSString *)transitionCategory
{
    return @"Script";
}

+(NSArray *)subTypes
{
    return nil;
}


-(NSString *)preChangeAction:(SourceLayout *)targetLayout
{
    return self.preTransitionScript;
}

-(NSString *)postChangeAction:(SourceLayout *)targetLayout
{
    return self.postTransitionScript;
}

-(NSViewController<CSLayoutTransitionViewProtocol> *)configurationViewController
{
    CSScriptTransitionViewController *vc = [[CSScriptTransitionViewController alloc] init];
    vc.transition = self;
    return vc;
}

@end
