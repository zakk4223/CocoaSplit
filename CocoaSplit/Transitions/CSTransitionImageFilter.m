//
//  CSTransitionImageFilter.m
//  CocoaSplit
//
//  Created by Zakk on 1/23/19.
//

#import "CSTransitionImageFilter.h"
#import "CSFilterImageLayoutTransitionViewController.h"

@implementation CSTransitionImageFilter
@synthesize filter = _filter;

-(instancetype)init
{
    if (self = [super init])
    {
        self.canToggle = YES;
    }
    
    return self;
}

-(id)copyWithZone:(NSZone *)zone
{
    CSTransitionImageFilter *newObj = [super copyWithZone:zone];
    if (newObj)
    {
        newObj.filter = self.filter;
        newObj.inDuration = self.inDuration;
        newObj.outDuration = self.outDuration;
    }
    return newObj;
}

-(void)encodeWithCoder:(NSCoder *)aCoder
{
    [super encodeWithCoder:aCoder];
    [aCoder encodeObject:self.filter forKey:@"filter"];
    [aCoder encodeObject:self.outDuration forKey:@"outDuration"];
    [aCoder encodeObject:self.inDuration forKey:@"inDuration"];
}

-(instancetype)initWithCoder:(NSCoder *)aDecoder
{
    if (self = [super initWithCoder:aDecoder])
    {
        self.filter = [aDecoder decodeObjectForKey:@"filter"];
        self.outDuration = [aDecoder decodeObjectForKey:@"outDuration"];
        self.inDuration = [aDecoder decodeObjectForKey:@"inDuration"];
    }
    return self;
}

+(NSString *)transitionCategory
{
    return @"Filter";
}

+(NSArray *)subTypes
{
    return nil;
}

-(NSString *)name
{
    NSString *ret = [super name];
    if (!ret)
    {
        if (self.filter)
        {
            ret = self.filter.attributes[kCIAttributeFilterDisplayName];
        } else {
            ret = @"Image Filter";
        }
    }

    return ret;
}

-(void)setFilter:(CIFilter *)filter
{
    _filter = filter;
    filter.name = [NSUUID UUID].UUIDString;
}

-(CIFilter *)filter
{
    return _filter;
}

-(NSString *)preChangeAction:(SourceLayout *)targetLayout
{
    NSMutableString *retStr = [NSMutableString string];
    self.realDuration = self.duration.floatValue;
    self.realInDuration = self.inDuration.floatValue;
    
    if (self.filter)
    {
        [retStr appendString:@"addFilterToLayoutForTransition(self.filter, self.realInDuration, getCurrentLayout());"];
    }
    
    if (self.isToggle)
    {
        return retStr;
    }
    
    self.realDuration = self.duration.floatValue;
    if (self.realDuration > 0.0f)
    {
        [retStr appendString:@"waitAnimation(self.realDuration);"];
    }
    
    return retStr;
    
}

-(NSString *)postChangeAction:(SourceLayout *)targetLayout
{
    self.realOutDuration = self.outDuration.floatValue;

    return @"removeFilterFromLayoutForTransition(self.filter, self.realOutDuration, getCurrentLayout());";
}

-(NSViewController<CSLayoutTransitionViewProtocol> *)configurationViewController
{
    CSFilterImageLayoutTransitionViewController *vc = [[CSFilterImageLayoutTransitionViewController alloc] init];
    vc.transition = self;
    return vc;
}

+(NSSet *)keyPathsForValuesAffectingName
{
    return [NSSet setWithObjects:@"filter", nil];
}
@end
