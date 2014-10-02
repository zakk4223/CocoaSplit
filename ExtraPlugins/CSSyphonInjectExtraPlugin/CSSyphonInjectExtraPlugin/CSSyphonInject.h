//
//  CSSyphonInject.h
//  CSSyphonInjectExtraPlugin
//
//  Created by Zakk on 10/1/14.
//  Copyright (c) 2014 Zakk. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CSExtraPluginProtocol.h"
#import "CSSyphonInjectWindowController.h"


@interface CSSyphonInject : NSObject  <CSExtraPluginProtocol>
{
    CSSyphonInjectWindowController *_windowController;
    
    

}

@property (retain) NSWorkspace *sharedWorkspace;


- (void)doInject:(NSRunningApplication *)toInject;


@end
