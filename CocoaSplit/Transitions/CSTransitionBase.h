//
//  CSTransitionBase.h
//  CocoaSplit
//
//  Created by Zakk on 3/16/18.
//

#import <Foundation/Foundation.h>
#import <JavascriptCore/JavascriptCore.h>
#import "SourceLayout.h"
#import "CSLayoutTransitionViewProtocol.h"


@protocol CSTransitionExport <JSExport>
@property (strong) NSNumber *duration;
@property (strong) NSString *name;
@property (strong) NSString *subType;
@property (assign) bool active;

-(NSString *)preChangeAction:(SourceLayout *)targetLayout;
-(NSString *)postChangeAction:(SourceLayout *)targetLayout;

@end

@interface CSTransitionBase : NSObject <CSTransitionExport, NSCopying>
{
    NSString *_name;
}


@property (strong) NSNumber *duration;
@property (strong) NSString *name;
@property (strong) NSString *subType;
@property (assign) bool active;
+(NSArray *)subTypes;
+(NSString *)transitionCategory;

-(NSString *)preChangeAction:(SourceLayout *)targetLayout;
-(NSString *)postChangeAction:(SourceLayout *)targetLayout;
-(NSViewController<CSLayoutTransitionViewProtocol> *)configurationViewController;

@end
