//
//  CNNoteDocument.h
//  CloudNotes
//
//  Created by Florian BUREL on 06/08/2014.
//  Copyright (c) 2014 Mistra. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface CNNoteDocument : UIDocument

@property (strong, nonatomic) NSString * text;
@property (strong, nonatomic) NSDate * lastModified;

@end
