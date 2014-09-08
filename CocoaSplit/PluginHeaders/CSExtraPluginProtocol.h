//
//  CSExtrasPluginProtocol.h
//  CocoaSplit
//
//  Created by Zakk on 9/5/14.
//  Copyright (c) 2014 Zakk. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>


@protocol CSExtraPluginProtocol <NSObject, NSCoding>



+(NSString *) label;

@optional
-(void)extraTopLevelMenuClicked;
-(NSMenu *)extraPluginMenu;


@end
