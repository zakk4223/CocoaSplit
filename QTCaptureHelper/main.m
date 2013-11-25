//
//  main.m
//  QTCaptureHelper
//
//  Created by Zakk on 11/10/12.
//  Copyright (c) 2012 Zakk. All rights reserved.
//

#include <Foundation/Foundation.h>
#import "XPCListenerDelegate.h"
int main(int argc, const char *argv[])
{


    
    xpc_main(qt_xpc_handle_connection);
    
    
    /*
    XPCListenerDelegate *listenDelegate = [[XPCListenerDelegate new] retain];
    NSLog(@"LISTEN DELEGATE %@", listenDelegate);
    
    NSXPCListener *listener = [[NSXPCListener serviceListener] retain];
    
    //NSString *bundleId = [[NSBundle mainBundle] bundleIdentifier];
	//NSXPCListener *listener = [[NSXPCListener alloc] initWithMachServiceName:bundleId];
    
    NSLog(@"LISTENER %@", listener);
    listener.delegate = listenDelegate;

    [listener resume];
    NSLog(@"SETUP XPC LISTENER");
    exit(EXIT_FAILURE);
     */
    
}
