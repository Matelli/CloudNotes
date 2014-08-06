//
//  CNCloudHelper.m
//  CloudNotes
//
//  Created by Florian BUREL on 06/08/2014.
//  Copyright (c) 2014 Mistra. All rights reserved.
//

#import "CNCloudHelper.h"
#import "CNNoteDocument.h"

@interface CNCloudHelper ()

@property (strong, nonatomic) NSMetadataQuery * query;

@end
@implementation CNCloudHelper

+ (instancetype)sharedInstance
{
    static id sharedInstance = nil;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [self new];
        
        
        [[NSNotificationCenter defaultCenter]
         addObserver:sharedInstance
         selector:@selector(queryDidFinishGathering)
         name:NSMetadataQueryDidFinishGatheringNotification
         object:nil];
        
    });
    
    return sharedInstance;
}

- (void) retrieveUserAccountToken:(void(^)(BOOL hasAccount, BOOL accountHasChanged))completion
{
    
    // Récupere le token
    id token = [[NSFileManager defaultManager] ubiquityIdentityToken];
    
    if(!token)
    {
        completion(NO, NO);
    }
    else if([token isEqual:[self storedToken]]) // Utiliser isEqual: pour comparer 2 token
    {
        completion(YES, NO);
    }
    else
    {
        [self setStoredToken:token]; // Cacher le token pour pouvoir le comparer prochainement
        completion(YES, YES);
    }
}

#pragma mark - CRUD operation

- (void)insertNewDocument:(void (^)(id document))completion
{
    NSString * documentName = [self generateRadomFileName];
    
    NSLog(@"Trying to create %@", documentName);
    
    [self retrieveIcloudContainerURL:^(NSURL *urlForIcloudContainer) {
        
        NSURL * fileURL = [urlForIcloudContainer URLByAppendingPathComponent:@"Documents"];
        fileURL = [fileURL URLByAppendingPathComponent:documentName];
        
        id document = [[CNNoteDocument alloc]initWithFileURL:fileURL];
        
        [document saveToURL:fileURL
           forSaveOperation:UIDocumentSaveForCreating
          completionHandler:^(BOOL success) {
              
              [document openWithCompletionHandler:^(BOOL success) {
                  if(success)
                  {
                      completion(document);
                  }
              }];
          }];
    }];
    
}

#pragma mark - monitoriung cloud acitivties

- (NSMetadataQuery *)query
{
    if(!_query)
    {
        _query = [NSMetadataQuery new];
        _query.searchScopes = @[NSMetadataQueryUbiquitousDocumentsScope];
        
        NSString * fileFormat = @"*.not";
        
        NSPredicate * predicate = [NSPredicate predicateWithFormat:@"%K LIKE %@", NSMetadataItemFSNameKey, fileFormat];
        
        _query.predicate = predicate;
    }
    
    return _query;
}

- (void) startMonitoringCloud
{
    [self stopMonitoringCloud];
    
    [self.query startQuery];
    
    
}

- (void) stopMonitoringCloud
{
    if(_query)
    {
        [self.query disableUpdates];
        [self.query stopQuery];
        self.query = nil;
    }
}

#pragma mark - iCloud CallBack

- (void) queryDidFinishGathering
{
    NSMutableArray * documents = [[NSMutableArray alloc]init];
    for (NSMetadataItem * item in _query.results)
    {
        NSURL *url = [item valueForAttribute:NSMetadataItemURLKey];
        CNNoteDocument *doc = [[CNNoteDocument alloc] initWithFileURL:url];
        [documents addObject:doc];
    }
    [self.delegate cloudHelper:self didFindDocuments:[documents copy]];
    [self.query enableUpdates];
}


#pragma mark - helper

- (void) retrieveIcloudContainerURL:(void(^)(NSURL * urlForIcloudContainer))completion
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        id manager = [NSFileManager defaultManager];
        NSURL * container = [manager URLForUbiquityContainerIdentifier:nil];
        dispatch_async(dispatch_get_main_queue(), ^{
            
            if(completion)
                completion(container);
        });
    });
}

- (NSString *) generateRadomFileName
{
    NSString * timeStamp = [[NSDate date] description];
    timeStamp = [timeStamp stringByReplacingOccurrencesOfString:@"-" withString:@""];
    timeStamp = [timeStamp stringByReplacingOccurrencesOfString:@":" withString:@""];
    timeStamp = [timeStamp stringByReplacingOccurrencesOfString:@" " withString:@""];
    timeStamp = [timeStamp stringByReplacingOccurrencesOfString:@"+" withString:@""];
    timeStamp = [timeStamp substringFromIndex:4];
    timeStamp = [timeStamp substringToIndex:10];
    
    NSString * randomNumber = [@(arc4random() % 100) description];
    return [NSString stringWithFormat:@"%@%@.not", timeStamp, randomNumber];
}


#pragma mark - token storage

#define kIcloudServiceTokenStorage  @"fr.matelli.icloudService.token"

- (id) storedToken
{
    return [[NSUserDefaults standardUserDefaults] objectForKey:kIcloudServiceTokenStorage];
}

- (void) setStoredToken:(id)token
{
    [[NSUserDefaults standardUserDefaults]removeObjectForKey:kIcloudServiceTokenStorage];
    [[NSUserDefaults standardUserDefaults]setObject:token forKey:kIcloudServiceTokenStorage];
}



@end
