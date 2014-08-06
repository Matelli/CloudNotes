//
//  CNNoteDocument.m
//  CloudNotes
//
//  Created by Florian BUREL on 06/08/2014.
//  Copyright (c) 2014 Mistra. All rights reserved.
//

#import "CNNoteDocument.h"

@implementation CNNoteDocument

#define CNNoteDocumentSerializedText @"text"
#define CNNoteDocumentSerializedTimeStamp   @"lastModif"

// lecture
- (BOOL)loadFromContents:(id)contents ofType:(NSString *)typeName error:(NSError *__autoreleasing *)outError
{
    id serializedObject = [NSJSONSerialization JSONObjectWithData:contents
                                                          options:NSJSONReadingAllowFragments
                                                            error:outError];
    self.text = serializedObject[CNNoteDocumentSerializedText];
    self.lastModified = serializedObject[CNNoteDocumentSerializedTimeStamp];
    
    return outError == nil;
}

// ecriture
- (id)contentsForType:(NSString *)typeName error:(NSError *__autoreleasing *)outError
{
    
    NSDictionary * serializedObject = @{
                                        CNNoteDocumentSerializedText : self.text,
                                        CNNoteDocumentSerializedTimeStamp : self.lastModified
                                        };
    
    id serializedData = [NSJSONSerialization dataWithJSONObject:serializedObject
                                                        options:NSJSONWritingPrettyPrinted
                                                          error:outError];
    
    return serializedData;
    
}

@end
