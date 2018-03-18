//
//  CSTransitionCollectionItem.m
//  CocoaSplit
//
//  Created by Zakk on 3/17/18.
//

#import "CSTransitionCollectionItem.h"
#import "CaptureController.h"

@interface CSTransitionCollectionItem ()

@end

@implementation CSTransitionCollectionItem

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do view setup here.
}


-(void)setRepresentedObject:(id)representedObject
{
    if (self.representedObject)
    {
        [self.representedObject removeObserver:self];
    }
    
    [super setRepresentedObject:representedObject];
    if (representedObject)
    {
        [representedObject addObserver:self forKeyPath:@"active" options:NSKeyValueObservingOptionNew context:nil];
    }
}

-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context
{
    if ([keyPath isEqualToString:@"active"])
    {
        [self.transitionButton setNeedsDisplay];
    }
}


-(void)transitionClicked
{
    
    CSTransitionBase *myTransition = self.representedObject;
    if (myTransition.active)
    {
        myTransition = nil;
    }
    [CaptureController sharedCaptureController].activeTransition = myTransition;
}




-(void)dealloc
{
    if (self.representedObject)
    {
        [self.representedObject removeObserver:self];
    }
}
@end
