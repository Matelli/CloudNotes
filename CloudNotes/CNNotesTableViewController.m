//
//  CNNotesTableViewController.m
//  CloudNotes
//
//  Created by Florian BUREL on 06/08/2014.
//  Copyright (c) 2014 Mistra. All rights reserved.
//

#import "CNNotesTableViewController.h"

@interface CNNotesTableViewController ()

@property (strong, nonatomic) NSArray * notesDocuments;

@end

@implementation CNNotesTableViewController

#pragma mark - View LifeCycle

- (void)viewDidLoad
{
    
    UIBarButtonItem * insertButton = [[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(insertNewNote)];
    self.navigationItem.rightBarButtonItem = insertButton;
}

#pragma mark - user Interraction

- (void) insertNewNote
{
    
}


#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
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
@end
