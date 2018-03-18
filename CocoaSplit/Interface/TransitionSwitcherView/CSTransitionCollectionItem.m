//
//  CSTransitionCollectionItem.m
//  CocoaSplit
//
//  Created by Zakk on 3/17/18.
//

#import "CSTransitionCollectionItem.h"
#import "CaptureController.h"
#import "CSLayoutTransitionViewProtocol.h"

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
        [self.representedObject removeObserver:self forKeyPath:@"active" context:nil];
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

-(void)buildTransitionMenu
{
    
    NSInteger idx = 0;
    
    NSMenuItem *tmp;
    CSTransitionBase *forTransition = self.representedObject;
    
    self.transitionMenu = [[NSMenu alloc] init];


    tmp = [self.transitionMenu insertItemWithTitle:@"Edit" action:@selector(editTransition:) keyEquivalent:@"" atIndex:idx++];
    tmp.target = self;
    tmp.representedObject = forTransition;
    
    
    
    tmp = [self.transitionMenu insertItemWithTitle:@"Delete" action:@selector(deleteTransition:) keyEquivalent:@"" atIndex:idx++];
    tmp.target = self;
    tmp.representedObject = forTransition;
    
}

-(void)showTransitionMenu:(NSEvent *)clickEvent
{
    NSPoint tmp = [self.view convertPoint:clickEvent.locationInWindow fromView:nil];
    [self buildTransitionMenu];
    [self.transitionMenu popUpMenuPositioningItem:self.transitionMenu.itemArray.firstObject atLocation:tmp inView:self.view];
}


-(void)deleteTransition:(NSMenuItem *)menuItem
{
    if (self.representedObject)
    {
        [[CaptureController sharedCaptureController] deleteTransition:self.representedObject];
    }
}

-(void)editTransition:(NSMenuItem *)menuItem
{
    
    if (!self.representedObject)
    {
        return;
    }
    
    CSTransitionBase *transition = self.representedObject;
    
    NSViewController<CSLayoutTransitionViewProtocol> *vc = transition.configurationViewController;
    
    if (!vc)
    {
        return;
    }
    
    if (!_editPopover)
    {
        _editPopover = [[NSPopover alloc] init];
        _editPopover.animates = YES;
        _editPopover.behavior = NSPopoverBehaviorTransient;
    }
    
    if (!_editPopover.contentViewController)
    {
        _editPopover.contentViewController = vc;
        _editPopover.delegate = vc;
        vc.popover = _editPopover;
    }
    
    [_editPopover showRelativeToRect:self.view.bounds ofView:self.view preferredEdge:NSMinXEdge];
}


-(void)dealloc
{
    if (self.representedObject)
    {
        [self.representedObject removeObserver:self forKeyPath:@"active" context:nil];
    }
}
@end
