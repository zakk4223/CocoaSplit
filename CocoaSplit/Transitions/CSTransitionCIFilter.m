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

-(id)copyWithZone:(NSZone *)zone
{
    CSTransitionCIFilter *newObj = [super copyWithZone:zone];
    if (newObj)
    {
        newObj.wholeLayout = self.wholeLayout;
        newObj.transitionFilter = self.transitionFilter.mutableCopy;
    }
    return newObj;
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
    CSLayoutTransition *newTransition = [[CSLayoutTransition alloc] init];
    newTransition.transitionFilter = self.transitionFilter;
    if (self.duration)
    {
        newTransition.transitionDuration = [self.duration floatValue];
    }
    
    newTransition.transitionFullScene = self.wholeLayout;
    targetLayout.transitionInfo = newTransition;
    
    return nil;
}

-(NSViewController<CSLayoutTransitionViewProtocol> *)configurationViewController
{
    CSCIFilterLayoutTransitionViewController *vc = [[CSCIFilterLayoutTransitionViewController alloc] init];
    vc.transition = self;
    return vc;
}




@end
