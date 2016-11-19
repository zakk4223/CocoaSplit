//
//  CSFileStreamRTMPServiceViewController.h
//  CSFileStreamServicePlugin
//
//  Created by Zakk on 7/16/16.
//  Copyright © 2016 Zakk. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "CSFileStreamRTMPService.h"

@interface CSFileStreamRTMPServiceViewController : NSViewController

@property (weak) CSFileStreamRTMPService *serviceObj;
@property (strong) IBOutlet NSObjectController *fileStreamRTMPServiceController;


@end
