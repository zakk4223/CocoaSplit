//
//  CSMixerStreamServiceViewController.h
//  CSMixerStreamServicePlugin
//
//  Created by Zakk on 4/13/18.
//

#import <Cocoa/Cocoa.h>
#import "CSMixerStreamService.h"
@interface CSMixerStreamServiceViewController : NSViewController
@property (weak) CSMixerStreamService *serviceObj;

- (IBAction)doMixerAuth:(id)sender;

@end
