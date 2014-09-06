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

-(NSMenu *)extraPluginMenu;

+(NSString *) label;

@property (strong) NSMutableArray *switchActions;





@end
