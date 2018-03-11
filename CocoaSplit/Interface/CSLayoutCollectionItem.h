//
//  CSLayoutCollectionItem.h
//  CocoaSplit
//
//  Created by Zakk on 10/4/15.
//

#import <Cocoa/Cocoa.h>
#import "CaptureController.h"
#import "CSLayoutButtonView.h"

@interface CSLayoutCollectionItem : NSCollectionViewItem <NSControlTextEditingDelegate>


@property (weak) IBOutlet CaptureController *captureController;
@property (strong) NSMenu *layoutMenu;
- (IBAction)layoutButtonPushed:(id)sender;

-(void)buildLayoutMenu;
-(void)showLayoutMenu:(NSEvent *)clickEvent;
-(void)layoutButtonHovered:(id)sender;

@property (weak) IBOutlet CSLayoutButtonView *layoutButton;
@property (weak) IBOutlet NSTextField *buttonLabel;
@property (weak) IBOutlet NSImageView *upImage;
@property (strong) IBOutlet NSImageView *downImage;

@end
