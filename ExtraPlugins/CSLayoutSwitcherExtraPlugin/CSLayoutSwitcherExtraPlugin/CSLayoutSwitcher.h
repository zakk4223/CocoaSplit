//
//  CSLayoutSwitcher.h
//  CSLayoutSwitcherExtraPlugin
//
//  Created by Zakk on 9/5/14.
//  Copyright (c) 2014 Zakk. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CSExtraPluginProtocol.h"
#import "CSLayoutSwitcherWindowController.h"
#import "CSLayoutSwitchAction.h"







@interface CSLayoutSwitcher : NSObject <CSExtraPluginProtocol>
{
    CSLayoutSwitcherWindowController *_windowController;
    
    
}
-(void)extraTopLevelMenuClicked;
-(void)pluginWasLoaded;


+(NSString *) label;
+(bool)shouldLoad;

@property (strong) NSMutableArray *switchActions;





@end
