//
//  CSTextCaptureViewControllerBase.m
//  CocoaSplit
//
//  Created by Zakk on 12/31/14.
//  Copyright (c) 2014 Zakk. All rights reserved.
//

#import "CSTextCaptureViewControllerBase.h"

@implementation CSTextCaptureViewControllerBase

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        
        self.textAlignmentModes = @[kCAAlignmentNatural, kCAAlignmentLeft, kCAAlignmentRight, kCAAlignmentCenter, kCAAlignmentJustified];
        
        // Initialization code here.
    }
    return self;
}

- (IBAction)openFontPanel:(id)sender
{
    
    NSFontManager *fontManager = [NSFontManager sharedFontManager];
    
    NSFontPanel *fontPanel = [fontManager fontPanel:YES];
    fontPanel.delegate = self;
    
    
    [fontPanel makeKeyAndOrderFront:self];
    [fontManager setSelectedFont:self.captureObj.font isMultiple:NO];
    [fontManager setAction:@selector(fontChanged:)];
    [fontManager setSelectedAttributes:self.captureObj.fontAttributes isMultiple:NO];
    
}

- (void)fontChanged:(id)sender
{
    NSFont *currentFont = self.captureObj.font;
    NSFont *newFont = [sender convertFont:currentFont];
    
    self.captureObj.font = newFont;
}

-(void)changeAttributes:(id)sender
{
    self.captureObj.fontAttributes = [sender convertAttributes:self.captureObj.fontAttributes];
}

-(void)dealloc
{

    
    NSFontManager *fontManager = [NSFontManager sharedFontManager];
    
    NSFontPanel *fontPanel = [fontManager fontPanel:NO];

    if (!fontPanel)
    {
        return;
    }
    fontPanel.delegate = nil;
    
    if (fontPanel.visible)
    {
        [fontPanel orderOut:self];
    }
}

@end
