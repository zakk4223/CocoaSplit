//
//  CSLayoutLayoutTransitionViewController.m
//  CocoaSplit
//
//  Created by Zakk on 8/17/17.
//

#import "CSLayoutLayoutTransitionViewController.h"
#import "CaptureController.h"
#import "CSCIFilterLayoutTransitionViewController.h"
#import "CSSimpleLayoutTransitionViewController.h"
#import "CaptureController.h"


@interface CSLayoutLayoutTransitionViewController ()

@end



@implementation CSLayoutLayoutTransitionViewController

-(instancetype) init
{
    if ([self initWithNibName:@"CSLayoutLayoutTransitionViewController" bundle:nil])
    {
        self.sourceLayouts = [CaptureController sharedCaptureController].sourceLayouts;
    }
    
    return self;
}


- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Do view setup here.
}

    -(NSUndoManager *)windowWillReturnUndoManager:(NSWindow *)window
    {
        return [[NSUndoManager alloc] init];
    }
    
    
    -(IBAction)openInputConfigWindow:(id)sender
    {

        NSObject<CSInputSourceProtocol> *configSrc = self.transition.inputSource;
        NSString *uuid = configSrc.uuid;
        NSViewController *newViewController = [configSrc configurationViewController];
        
        
        
        _configWindow = [[NSWindow alloc] init];
        NSRect newFrame = [_configWindow frameRectForContentRect:NSMakeRect(0.0f, 0.0f, newViewController.view.frame.size.width, newViewController.view.frame.size.height)];
        
        
        
        [_configWindow setFrame:newFrame display:NO];
        [_configWindow center];
        
        [_configWindow setReleasedWhenClosed:NO];
        
        
        [_configWindow.contentView addSubview:newViewController.view];
        _configWindow.title = [NSString stringWithFormat:@"Transition Config (%@)", configSrc.name];
        _configWindow.delegate = self;
        
        _configWindow.styleMask =  NSTitledWindowMask|NSClosableWindowMask|NSMiniaturizableWindowMask;
        _configViewController = newViewController;
        
        _configWindow.identifier = uuid;
        
        [_configWindow makeKeyAndOrderFront:nil];
    }
    
/*
- (IBAction)configureInTransition:(NSButton *)sender
{
    
    if (!self.transition.preTransition)
    {
        self.transition.preTransition = [[CSLayoutTransition alloc] init];
    }
    
    self.subTransition = self.transition.preTransition;
    
    
    [self openSubTransitionPopover:sender spawnRect:sender.frame];
    
    
    
}


- (IBAction)configureOutTransition:(NSButton *)sender
{
    if (!self.transition.postTransition)
    {
        self.transition.postTransition = [[CSLayoutTransition alloc] init];
    }
    
    self.subTransition = self.transition.postTransition;
    
    [self openSubTransitionPopover:sender spawnRect:sender.frame];
}




-(void)openSubTransitionPopover:(NSView *)sender spawnRect:(NSRect)spawnRect
{
    CSSubLayoutTransitionViewController *vc;
    if (!_subPopover)
    {
        _subPopover = [[NSPopover alloc] init];
        
        _subPopover.animates = YES;
        _subPopover.behavior = NSPopoverBehaviorSemitransient;
    }
    
    //if (!_subPopover.contentViewController)
    {
        vc = [[CSSubLayoutTransitionViewController alloc] init];
        
        
        _subPopover.contentViewController = vc;
        _subPopover.delegate = vc;
        //vc.popover = _layoutpopOver;
        
    }
    
    [_subPopover showRelativeToRect:spawnRect ofView:sender.superview preferredEdge:NSMaxXEdge];
    vc.transition = self.subTransition;

}
*/

-(BOOL) commitEditing
{
    [_subTransitionViewController commitEditing];
    return [super commitEditing];
}


@end
