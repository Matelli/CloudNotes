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
@property (readonly, nonatomic) CNCloudHelper * service;
@property (strong, nonatomic) NSMutableDictionary * openOperations;

@end

@implementation CNNotesTableViewController
{
    NSMutableDictionary * _openOperations;
}

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

- (NSMutableDictionary *)openOperations
{
    if(!_openOperations)
    {
        _openOperations = [NSMutableDictionary new];
    }
    return _openOperations;
}

#pragma mark - View LifeCycle

- (void)viewDidLoad
{
    // Ajoute un bouton +
    UIBarButtonItem * insertButton = [[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(insertNewNote)];
    self.navigationItem.rightBarButtonItem = insertButton;
    
    [self launchIcloudSync];
 
}

- (void) launchIcloudSync
{
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
    [self.service insertNewDocument:^(CNNoteDocument * document)
    {
        document.text = @"new";
        document.lastModified = [NSDate date];
       
        self.notesDocuments = [self.notesDocuments arrayByAddingObject:document];
        
        self.notesDocuments = [self.notesDocuments sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"lastModified" ascending:NO]]];
        
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
    CNNoteDocument * notesDocument = self.notesDocuments[indexPath.row];
    
    // Recupération de la cellule
    static NSString * CellIdentifier = @"Cell";
    
    UITableViewCell * cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if(!cell)
    {
        cell = [[UITableViewCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    
    // Configuration de la cellule
    if(notesDocument.text)
    {
        cell.textLabel.text = [notesDocument text];
    }
    else
    {
        cell.textLabel.text = @"...";
        [self openDocumentForCellAtIndexPath:indexPath];
    }
    
    return cell;
}

- (void) openDocumentForCellAtIndexPath:(NSIndexPath *)indexPAth
{
    if(self.openOperations[indexPAth] != nil)
    {
        // Already performing
        return;
    }
    
    CNNoteDocument * document = self.notesDocuments[indexPAth.row];
    
    NSBlockOperation * operation = [NSBlockOperation blockOperationWithBlock:^
    {
        [self.tableView reloadRowsAtIndexPaths:@[indexPAth]
                              withRowAnimation:UITableViewRowAnimationAutomatic];
        
        [self.openOperations removeObjectForKey:indexPAth];
    }];
    
    self.openOperations[indexPAth] = operation;
    
    [document openWithCompletionHandler:^(BOOL success)
    {
        [[NSOperationQueue mainQueue]addOperation:operation];
    }];
}


NSIndexPath * _ip; // Stocke l'indexPath de la cellule en cours d'édition

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    _ip = indexPath;
    
    CNNoteDocument * doc = self.notesDocuments[indexPath.row];
    
    // Cree une alertView pour modifier le text
    UIAlertView * alert = [[UIAlertView alloc]initWithTitle:@"Entrer le text" message:nil delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"OK", nil];
    alert.alertViewStyle = UIAlertViewStylePlainTextInput;
    [[alert textFieldAtIndex:0] setText:doc.text];
    [alert show];
    
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    CNNoteDocument * doc = self.notesDocuments[_ip.row];
    
    if(buttonIndex != alertView.cancelButtonIndex)
    {
        // Modifie le text et le lastModified
        doc.text = [[alertView textFieldAtIndex:0] text];
        doc.lastModified = [NSDate date];
        
        // Sauvegarde du document
        [doc saveToURL:doc.fileURL
       forSaveOperation:UIDocumentSaveForOverwriting completionHandler:^(BOOL success)
        {
            // Met a jour la cellule
           [self.tableView reloadRowsAtIndexPaths:@[_ip] withRowAnimation:UITableViewRowAnimationNone];
            
            // déplace la cellule en haut de liste
           [self.tableView moveRowAtIndexPath:_ip toIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
            
            // Retrie la datasource
           self.notesDocuments = [self.notesDocuments sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"lastModified" ascending:NO]]];
            
           _ip = nil;
       }];
        
    }
}

#pragma mark - iCNCloudHelperDelegate

- (void)cloudHelper:(id)sender didFindDocuments:(NSArray *)documents
{
    self.notesDocuments = documents;
    
    self.notesDocuments = [self.notesDocuments sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"lastModified" ascending:NO]]];
    
    [self.tableView reloadData];
}

@end
