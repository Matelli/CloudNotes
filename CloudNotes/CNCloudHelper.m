//
//  CNCloudHelper.m
//  CloudNotes
//
//  Created by Florian BUREL on 06/08/2014.
//  Copyright (c) 2014 Mistra. All rights reserved.
//

#import "CNCloudHelper.h"
#import "CNNoteDocument.h"

@implementation CNCloudHelper
{
    NSMetadataQuery * _query;
}

+ (instancetype)sharedInstance
{
    static id sharedInstance = nil;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [self new];
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
    NSString * documentName = @"toto.not"; //[self generateRadomFileName];
    
    [self retrieveIcloudContainerURL:^(NSURL *urlForIcloudContainer) {
        
        NSURL * fileURL = [urlForIcloudContainer URLByAppendingPathComponent:documentName
                                                                 isDirectory:NO];
        
        id document = [[CNNoteDocument alloc]initWithFileURL:fileURL];
        
        [document saveToURL:fileURL
           forSaveOperation:UIDocumentSaveForCreating
          completionHandler:^(BOOL success) {
              [document openWithCompletionHandler:^(BOOL success) {
                  completion(document);
              }];
          }];
    }];
    
}

#pragma mark - monitoriung cloud acitivties

- (NSMetadataQuery *)documentQuery
{
    
    if(!_query)
    {
        _query = [[NSMetadataQuery alloc] init];
        
        // Search documents subdir only
        [_query setSearchScopes:[NSArray arrayWithObject:NSMetadataQueryUbiquitousDocumentsScope]];
        
        // Recherche tout les documents .not
        NSString * filePattern = @"*.*";
        [_query setPredicate:[NSPredicate predicateWithFormat:@"%K LIKE %@",
                                      NSMetadataItemFSNameKey, filePattern]];
        
    }
    return _query;
    
}


- (void) startMonitoringCloud
{
    [self stopMonitoringCloud];
    
    [self.documentQuery startQuery];
    
    [[NSNotificationCenter defaultCenter]
     addObserver:self
     selector:@selector(queryDidFinishGathering)
     name:NSMetadataQueryDidFinishGatheringNotification
     object:nil];
}

- (void) stopMonitoringCloud
{
    [_query stopQuery];
    _query = nil;
    
    @try {
        [[NSNotificationCenter defaultCenter]removeObserver:self name:NSMetadataQueryDidFinishGatheringNotification object:nil];
    }
    @catch (NSException *exception) {
        // do nothing
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
    [self.delegate cloudHelper:self didFindDocuments:documents];
}


#pragma mark - helper

- (void) retrieveIcloudContainerURL:(void(^)(NSURL * urlForIcloudContainer))completion
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        id container = [[NSFileManager defaultManager]URLForUbiquityContainerIdentifier:nil];
        dispatch_async(dispatch_get_main_queue(), ^{
            if(completion)
                completion(container);
        });
    });
}

- (NSString *) generateRadomFileName
{
    NSString * timeStamp = [[NSDate date] description];
    NSString * randomNumber = [@(arc4random() % 100) description];
    return [NSString stringWithFormat:@"%@_%@.not", timeStamp, randomNumber];
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
