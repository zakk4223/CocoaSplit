//
//  main.m
//  H264Streamer
//
//  Created by Zakk on 9/2/12.
//  Copyright (c) 2012 Zakk. All rights reserved.
//

#import <Cocoa/Cocoa.h>

int main(int argc, char *argv[])
{
    signal(SIGPIPE, SIG_IGN);
    return NSApplicationMain(argc, (const char **)argv);
}
