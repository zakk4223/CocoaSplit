//
//  CSTransitionScript.h
//  CocoaSplit
//
//  Created by Zakk on 3/29/18.
//

#import "CSTransitionBase.h"


@protocol CSTransitionScriptExport <JSExport>
@property (strong) NSString *preTransitionScript;
@property (strong) NSString *postTransitionScript;
@end

@interface CSTransitionScript : CSTransitionBase

@property (strong) NSString *preTransitionScript;
@property (strong) NSString *postTransitionScript;


@end
