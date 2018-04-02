//
//  CSLayoutLayoutTransitionViewController.h
//  CocoaSplit
//
//  Created by Zakk on 8/17/17.
//

//This class name is terrible

#import <Cocoa/Cocoa.h>
#import "CSLayoutTransitionViewProtocol.h"
#import "CSTransitionLayout.h"
#import "CSInputLayoutTransitionViewController.h"

@interface CSLayoutLayoutTransitionViewController : CSInputLayoutTransitionViewController <CSLayoutTransitionViewProtocol, NSWindowDelegate>
{
 
    
}



@property (strong) NSArray *sourceLayouts;


@end
