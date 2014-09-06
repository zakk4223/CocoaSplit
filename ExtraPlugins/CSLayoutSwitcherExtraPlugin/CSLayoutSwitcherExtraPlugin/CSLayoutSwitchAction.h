//
//  CSLayoutSwitchAction.h
//  CSLayoutSwitcherExtraPlugin
//
//  Created by Zakk on 9/6/14.
//  Copyright (c) 2014 Zakk. All rights reserved.
//

#import <Foundation/Foundation.h>


typedef enum layout_switch_event_t {
    
    kEventActivated = 0,
    kEventDeactivated = 1,
} layout_switch_event;


@interface CSLayoutSwitchAction : NSObject <NSCoding>


@property (strong) NSString *applicationString;
@property (assign) layout_switch_event eventType;
@property (strong) NSString *layoutName;
@property (assign) bool active;


@end
