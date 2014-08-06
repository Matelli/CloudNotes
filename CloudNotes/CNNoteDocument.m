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
    NSNumber * timeStamp = serializedObject[CNNoteDocumentSerializedTimeStamp];
    self.lastModified = [NSDate dateWithTimeIntervalSince1970:timeStamp.doubleValue];
    
    if(self.text == nil)
    {
        self.text = @"vide";
    }
    return outError == nil;
}

// ecriture
- (id)contentsForType:(NSString *)typeName error:(NSError *__autoreleasing *)outError
{
    if(self.text == nil)
    {
        self.text = @"empty";
    }
    if(!self.lastModified)
    {
        self.lastModified = [NSDate date];
    }
    
    NSDictionary * serializedObject = @{
                                        CNNoteDocumentSerializedText : self.text,
                                        CNNoteDocumentSerializedTimeStamp : @(self.lastModified.timeIntervalSince1970)
                                        };
    
    id serializedData = [NSJSONSerialization dataWithJSONObject:serializedObject
                                                        options:NSJSONWritingPrettyPrinted
                                                          error:outError];
    
    return serializedData;
    
}

- (NSString *)description
{
    return self.text;
}
@end
