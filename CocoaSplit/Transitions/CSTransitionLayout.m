//
//  CSTransitionLayout.m
//  CocoaSplit
//
//  Created by Zakk on 3/19/18.
//

#import "CSTransitionLayout.h"
#import "CaptureController.h"
#import "CSLayoutTransition.h"

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
    

    _savedTransition = CaptureController.sharedCaptureController.activeTransition;
    CaptureController.sharedCaptureController.activeTransition = nil;
    NSPasteboardItem *layoutItem = [[NSPasteboardItem alloc] init];
    NSData *uuidData = [NSKeyedArchiver archivedDataWithRootObject:self.layout.uuid];
    [layoutItem setData:uuidData forType:@"cocoasplit.layout"];
    
    self.layoutSource = [CaptureController.sharedCaptureController inputSourceForPasteboardItem:layoutItem];
    self.layoutSource.persistent = YES;
    //-(NSObject<CSInputSourceProtocol>*)inputSourceForPasteboardItem:(NSPasteboardItem *)item;

    NSLog(@"LAYOUT SRC %@", self.layoutSource.uuid);
    //[[CaptureController sharedCaptureController] switchToLayout:targetLayout];
    
    return @"addInputToLayout(self.layoutSource, getCurrentLayout());waitAnimation(5);";
    //return @"console.log('blah');beginAnimation();target_layout.replaceWithSourceLayoutUsingScripts(captureController.activeTransition.layout, useScripts);;waitAnimation(5);commitAnimation();console.log('done')";
}

-(NSString *)postChangeAction:(SourceLayout *)targetLayout
{
    NSString *ret = @"waitAnimation(5);removeInputFromLayout(self.layoutSource)";
    CaptureController.sharedCaptureController.activeTransition = _savedTransition;
    return ret;
}


-(NSString *)preMergeAction:(SourceLayout *)targetLayout
{
    _savedTransition = CaptureController.sharedCaptureController.activeTransition;
    CaptureController.sharedCaptureController.activeTransition = nil;
    
    return @"mergeLayout(self.layout);waitAnimation(5);removeLayout(self.layout);waitAnimation(0.01);";
    //return @"var endLayout = targetLayout.mergedSourceLayout(mergedLayout); console.log(endLayout); beginAnimation();switchToLayout(self.layout);commitAnimation();beginAnimation(); waitAnimation();switchToLayout(endLayout);commitAnimation();";
}


-(bool)skipMergeAction:(SourceLayout *)targetLayout
{
    return NO;
}
/*
-(NSViewController<CSLayoutTransitionViewProtocol> *)configurationViewController
{
    CSCIFilterLayoutTransitionViewController *vc = [[CSCIFilterLayoutTransitionViewController alloc] init];
    vc.transition = self;
    return vc;
}*/


@end
