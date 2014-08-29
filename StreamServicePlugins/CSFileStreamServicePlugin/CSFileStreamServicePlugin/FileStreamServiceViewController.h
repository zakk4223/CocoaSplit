//
//  FileStreamServiceViewController.h
//  CSFileStreamServicePlugin
//
//  Created by Zakk on 8/29/14.
//  Copyright (c) 2014 Zakk. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "FileStreamService.h"


@interface FileStreamServiceViewController : NSViewController
@property (weak) FileStreamService *serviceObj;
@property (strong) IBOutlet NSObjectController *fileStreamServiceController;

@end
