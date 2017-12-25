//
//  CSLayoutTransitionViewProtocol.h
//  CocoaSplit
//
//  Created by Zakk on 8/16/17.
//

#import <Foundation/Foundation.h>
#import "CSLayoutTransition.h"

@protocol CSLayoutTransitionViewProtocol <NSObject>

@property (strong) CSLayoutTransition *transition;
@property (strong) NSView *view;

@end
