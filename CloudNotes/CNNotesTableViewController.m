//
//  CNNotesTableViewController.m
//  CloudNotes
//
//  Created by Florian BUREL on 06/08/2014.
//  Copyright (c) 2014 Mistra. All rights reserved.
//

#import "CNNotesTableViewController.h"
#import "CNCloudHelper.h"
#import "CNNoteDocument.h"

@interface CNNotesTableViewController () <CNCloudHelperDelegate>

@property (strong, nonatomic) NSArray * notesDocuments;
@property (readonly) CNCloudHelper * service;

@end

@implementation CNNotesTableViewController

#pragma mark - Lazy getter

- (CNCloudHelper *)service
{
    return [CNCloudHelper sharedInstance];
}

- (NSArray *)notesDocuments
{
    if(!_notesDocuments)
    {
        self.notesDocuments = [NSArray new];
    }
    return _notesDocuments;
}

#pragma mark - View LifeCycle

- (void)viewDidLoad
{
    
    UIBarButtonItem * insertButton = [[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(insertNewNote)];
    self.navigationItem.rightBarButtonItem = insertButton;
    
    [self.service retrieveUserAccountToken:^(BOOL hasAccount, BOOL accountHasChanged) {
        if(hasAccount)
        {
            [self.service startMonitoringCloud];
            self.service.delegate = self;
        }
        else
        {
            [[[UIAlertView alloc]initWithTitle:@"iCloud est necessaire pour fonctionner"
                                       message:@"So go and get it"
                                      delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil] show];
        }
    }];
    
    
    
}

#pragma mark - user Interraction

- (void) insertNewNote
{
    [self.service insertNewDocument:^(CNNoteDocument * document) {
        document.text = @"new";
        document.lastModified = [NSDate date];
        self.notesDocuments = [self.notesDocuments arrayByAddingObject:document];
        [self.tableView reloadData];
    }];
}


#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    self.title = [NSString stringWithFormat:@"%d items", self.notesDocuments.count];
    return self.notesDocuments.count;
    
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    id notesDocument = self.notesDocuments[indexPath.row];
    
    // Recupération de la cellule
    static NSString * CellIdentifier = @"Cell";
    
    UITableViewCell * cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if(!cell)
    {
        cell = [[UITableViewCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    
    // Configuration de la cellule
    cell.textLabel.text = [notesDocument description];
    
    return cell;
}

#pragma mark - iCNCloudHelperDelegate

- (void)cloudHelper:(id)sender didFindDocuments:(NSArray *)documents
{
    self.notesDocuments = documents;
    
    [self.tableView reloadData];
}
@end
