//
//  CSLayoutTransition.m
//  CocoaSplit
//
//  Created by Zakk on 8/12/17.
//

#import "CSLayoutTransition.h"

@implementation CSLayoutTransition


-(instancetype) init
{
    if (self = [super init])
    {
        self.waitForMedia = YES;
    }
    
    return self;
}


-(instancetype) copyWithZone:(NSZone *)zone
{
    CSLayoutTransition *copy = [[CSLayoutTransition alloc] init];
    copy.transitionFullScene = self.transitionFullScene;
    copy.waitForMedia = self.waitForMedia;
    return copy;
}

-(void)encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeBool:self.transitionFullScene forKey:@"transitionFullScene"];
    [aCoder encodeBool:self.waitForMedia forKey:@"waitForMedia"];
}

+(CSLayoutTransition *)createTransition
{
    return [[CSLayoutTransition alloc] init];
}

-(instancetype) initWithCoder:(NSCoder *)aDecoder
{
    if (self = [self init])
    {
        self.transitionFullScene = [aDecoder decodeBoolForKey:@"transitionFullScene"];
        self.waitForMedia = [aDecoder decodeBoolForKey:@"waitForMedia"];

    }
    return self;
    
    
}
@end
