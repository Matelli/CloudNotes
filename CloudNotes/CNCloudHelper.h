//
//  CNCloudHelper.h
//  CloudNotes
//
//  Created by Florian BUREL on 06/08/2014.
//  Copyright (c) 2014 Mistra. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol CNCloudHelperDelegate <NSObject>

// Called when files are found in iCloud
- (void) cloudHelper:(id)sender didFindDocuments:(NSArray *)documents;

@end
@interface CNCloudHelper : NSObject

+ (instancetype)sharedInstance;

- (void) retrieveUserAccountToken:(void(^)(BOOL hasAccount, BOOL accountHasChanged))completion;


- (void)insertNewDocument:(void (^)(id document))completion;

- (void) startMonitoringCloud;
- (void) stopMonitoringCloud;

@property (weak, nonatomic) id<CNCloudHelperDelegate> delegate;

@end
