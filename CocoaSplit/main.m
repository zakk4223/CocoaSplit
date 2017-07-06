//
//  main.m
//  CocoaSplit
//
//  Created by Zakk on 9/2/12.
//

#import <Cocoa/Cocoa.h>

int main(int argc, char *argv[])
{
    signal(SIGPIPE, SIG_IGN);
    return NSApplicationMain(argc, (const char **)argv);
}
