//
//  TextCaptureViewController.m
//  CocoaSplit
//
//  Created by Zakk on 8/28/14.
//  Copyright (c) 2014 Zakk. All rights reserved.
//

#import "TextCaptureViewController.h"

@interface TextCaptureViewController ()

@end

@implementation TextCaptureViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Initialization code here.
    }
    return self;
}

- (IBAction)openFontPanel:(id)sender
{
    [[NSFontPanel sharedFontPanel] makeKeyAndOrderFront:self];
    [[NSFontPanel sharedFontPanel] setPanelFont:self.captureObj.font isMultiple:NO];
    [[NSFontPanel sharedFontPanel] setDelegate:self];
    [[NSFontManager sharedFontManager] setAction:@selector(fontChanged:)];
}

- (void)fontChanged:(id)sender
{
    NSFont *currentFont = self.captureObj.font;
    NSFont *newFont = [sender convertFont:currentFont];
    NSLog(@"FONT %@", newFont);
    
    self.captureObj.font = newFont;
}

-(void)changeAttributes:(id)sender
{
    self.captureObj.fontAttributes = [sender convertAttributes:self.captureObj.fontAttributes];
}

-(void)dealloc
{
    
    [[NSFontPanel sharedFontPanel] setDelegate:nil];
    if ([[NSFontPanel sharedFontPanel] isVisible])
    {
        [[NSFontPanel sharedFontPanel] orderOut:self];
    }
}

@end
