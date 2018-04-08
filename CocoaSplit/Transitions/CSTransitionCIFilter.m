//
//  CSTransitionCIFilter.m
//  CocoaSplit
//
//  Created by Zakk on 3/18/18.
//

#import "CSTransitionCIFilter.h"
#import "CSLayoutTransition.h"
#import "CSCIFilterLayoutTransitionViewController.h"

@implementation CSTransitionCIFilter

    
    -(instancetype) init
    {
        if (self = [super init])
        {
            self.timingFunction = kCAMediaTimingFunctionDefault;
            self.timingFunctions = @{@"Default": kCAMediaTimingFunctionDefault,
                                     @"Linear": kCAMediaTimingFunctionLinear,
                                     @"Ease In": kCAMediaTimingFunctionEaseIn,
                                     @"Ease Out": kCAMediaTimingFunctionEaseOut,
                                     @"Ease In and Out": kCAMediaTimingFunctionEaseInEaseOut
                                     };
        }
        
        return self;
    }
    
-(id)copyWithZone:(NSZone *)zone
{
    CSTransitionCIFilter *newObj = [super copyWithZone:zone];
    if (newObj)
    {
        newObj.wholeLayout = self.wholeLayout;
        newObj.transitionFilter = self.transitionFilter.mutableCopy;
        newObj.timingFunction = self.timingFunction;
    }
    return newObj;
}

-(void)encodeWithCoder:(NSCoder *)aCoder
{
    [super encodeWithCoder:aCoder];
    [aCoder encodeBool:self.wholeLayout forKey:@"wholeLayout"];
    [aCoder encodeObject:self.transitionFilter forKey:@"transitionFilter"];
    [aCoder encodeObject:self.timingFunction forKey:@"timingFunction"];
}

-(instancetype)initWithCoder:(NSCoder *)aDecoder
{
    if (self = [super initWithCoder:aDecoder])
    {
        self.wholeLayout = [aDecoder decodeBoolForKey:@"wholeLayout"];
        self.transitionFilter = [aDecoder decodeObjectForKey:@"transitionFilter"];
        self.timingFunction = [aDecoder decodeObjectForKey:@"timingFunction"];
        if (!self.timingFunction)
        {
            self.timingFunction = kCAMediaTimingFunctionDefault;
        }
    }
    
    return self;
}

+(NSArray *)subTypes
{
    NSMutableArray *ret = [NSMutableArray array];
    for (NSString *subType in [CIFilter filterNamesInCategory:kCICategoryTransition])
    {
    
        CSTransitionCIFilter *newTransition = [[CSTransitionCIFilter alloc] init];
        newTransition.transitionFilter = [CIFilter filterWithName:subType];
        [newTransition.transitionFilter setDefaults];
        [ret addObject:newTransition];
    }
    
    return ret;
}



+(NSString *)transitionCategory
{
    return @"Core Image";
}


-(NSString *)name
{
    
    NSString *ret = [super name];
    if (!ret && self.transitionFilter)
    {
        ret = [CIFilter localizedNameForFilterName:self.transitionFilter.name];
    }
    return ret;
}


-(NSString *)preChangeAction:(SourceLayout *)targetLayout
{
    
    
    CATransition *newTransition = [CATransition animation];
    newTransition.filter = self.transitionFilter;
    newTransition.duration = self.duration.floatValue;
    newTransition.timingFunction = [CAMediaTimingFunction functionWithName:self.timingFunction];
    self.realTransition = newTransition;
    return @"return createTransition(self.realTransition, self.wholeLayout);";
  
}

-(NSViewController<CSLayoutTransitionViewProtocol> *)configurationViewController
{
    CSCIFilterLayoutTransitionViewController *vc = [[CSCIFilterLayoutTransitionViewController alloc] init];
    vc.transition = self;
    return vc;
}




@end
