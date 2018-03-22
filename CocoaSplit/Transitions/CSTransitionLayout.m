//
//  CSTransitionLayout.m
//  CocoaSplit
//
//  Created by Zakk on 3/19/18.
//

#import "CSTransitionLayout.h"
#import "CaptureController.h"
#import "CSLayoutTransition.h"
#import "CSLayoutLayoutTransitionViewController.h"

@implementation CSTransitionLayout

-(id)copyWithZone:(NSZone *)zone
{
    CSTransitionLayout *newObj = [super copyWithZone:zone];
    if (newObj)
    {
        newObj.layout = self.layout;
    }
    return newObj;
}


    
+(NSArray *)subTypes
{
    NSMutableArray *ret = [NSMutableArray array];
    for (SourceLayout *layout in CaptureController.sharedCaptureController.sourceLayouts)
    {
        
        
        CSTransitionLayout *newTransition = [[CSTransitionLayout alloc] init];
        newTransition.layout = layout;
        [ret addObject:newTransition];
    }
    return ret;
}



+(NSString *)transitionCategory
{
    return @"Layout";
}


-(NSString *)name
{
    
    NSString *ret = [super name];
    if (!ret && self.layout)
    {
        ret = self.layout.name;
    }
    return ret;
}


-(NSString *)preChangeAction:(SourceLayout *)targetLayout
{
    

    NSPasteboardItem *layoutItem = [[NSPasteboardItem alloc] init];
    NSData *uuidData = [NSKeyedArchiver archivedDataWithRootObject:self.layout.uuid];
    [layoutItem setData:uuidData forType:@"cocoasplit.layout"];
    
    self.layoutSource = [CaptureController.sharedCaptureController inputSourceForPasteboardItem:layoutItem];
    self.layoutSource.persistent = YES;

    NSMutableString *scriptRet = [NSMutableString stringWithString:@"addInputToLayout(self.layoutSource);"];
    if (self.waitForMedia)
    {
        [scriptRet appendString:@"waitAnimation(self.layoutSource.duration);"];
    }
    
    if (self.holdDuration > 0.0f)
    {
        [scriptRet appendString:@"wait(self.holdDuration);"];
    }
    return scriptRet;
}


-(NSString *)postChangeAction:(SourceLayout *)targetLayout
{
    NSString *ret = @"removeInputFromLayout(self.layoutSource)";
    return ret;
}



-(NSViewController<CSLayoutTransitionViewProtocol> *)configurationViewController
{
    CSLayoutLayoutTransitionViewController *vc = [[CSLayoutLayoutTransitionViewController alloc] init];
    vc.transition = self;
    return vc;
}


@end
