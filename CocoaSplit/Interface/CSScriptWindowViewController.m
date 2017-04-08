//
//  CSScriptWindowViewController.m
//  CocoaSplit
//
//  Created by Zakk on 4/7/17.
//  Copyright © 2017 Zakk. All rights reserved.
//

#import "CSScriptWindowViewController.h"

@interface CSScriptWindowViewController ()

@end

@implementation CSScriptWindowViewController
@synthesize sequences = _sequences;

- (void)windowDidLoad {
    [super windowDidLoad];
    
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
}

-(instancetype) init
{
    
    
    return [self initWithWindowNibName:@"CSScriptWindowViewController"];
    
}







-(NSArray *)sequences
{
    if (_sequenceViewController)
    {
        return _sequenceViewController.sequences;
    }
    
    return nil;
}


-(void)setSequences:(NSArray *)sequences
{
    
    if (!_sequenceViewController)
    {
        _sequenceViewController = [[CSSequenceActivatorViewController alloc] init];
        _sequenceViewController.view = self.gridView;
    }
    
    _sequenceViewController.sequences = sequences;
}

-(void)windowWillClose:(NSNotification *)notification
{
    _sequenceViewController = nil;
}


@end
