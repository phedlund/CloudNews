//
//  FeedListController.m
//  iOCNews
//

/************************************************************************
 
 Copyright 2012-2016 Peter Hedlund peter.hedlund@me.com
 
 Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions
 are met:
 
 1. Redistributions of source code must retain the above copyright
 notice, this list of conditions and the following disclaimer.
 2. Redistributions in binary form must reproduce the above copyright
 notice, this list of conditions and the following disclaimer in the
 documentation and/or other materials provided with the distribution.
 
 THIS SOFTWARE IS PROVIDED BY THE AUTHOR "AS IS" AND ANY EXPRESS OR
 IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES
 OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
 IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY DIRECT, INDIRECT,
 INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT
 NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
 THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF
 THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 
 *************************************************************************/

#import "OCFeedListController.h"
#import "OCLoginController.h"
#import "OCNewsHelper.h"
#import "Folder+CoreDataClass.h"
#import "Feed+CoreDataClass.h"
#import "CloudNews-Swift.h"
@import AFNetworking;

static NSString *DetailSegueIdentifier = @"showDetail";

@interface OCFeedListController () <NSFetchedResultsControllerDelegate, UIGestureRecognizerDelegate, UIActionSheetDelegate, UISplitViewControllerDelegate, FolderControllerDelegate, FeedSettingsDelegate> {
    NSInteger currentRenameId;
    BOOL networkHasBeenUnreachable;
    NSIndexPath *editingPath;
}

@property (strong, nonatomic) IBOutlet UIBarButtonItem *gearBarButtonItem;
@property (strong, nonatomic) ItemsListViewController *detailViewController;
@property (nonatomic, assign) NSInteger currentIndex;

- (void) networkCompleted:(NSNotification*)n;
- (void) networkError:(NSNotification*)n;
- (void) doHideRead;
- (void) updatePredicate;
- (void) reachabilityChanged:(NSNotification *)n;
- (void) didBecomeActive:(NSNotification *)n;
- (void) drawerOpened;
- (void) drawerClosed;

@end

@implementation OCFeedListController

@synthesize feedRefreshControl;
@synthesize specialFetchedResultsController;
@synthesize foldersFetchedResultsController;
@synthesize feedsFetchedResultsController;
@synthesize folderId;
@synthesize currentIndex;

- (NSFetchedResultsController *)specialFetchedResultsController {
    if (!specialFetchedResultsController) {
        NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
        NSEntityDescription *entity = [NSEntityDescription entityForName:@"Feed" inManagedObjectContext:[OCNewsHelper sharedHelper].context];
        [fetchRequest setEntity:entity];
        
        NSPredicate *pred = [NSPredicate predicateWithFormat:@"myId < 0"];
        [fetchRequest setPredicate:pred];
        
        NSSortDescriptor *sort = [[NSSortDescriptor alloc] initWithKey:@"myId" ascending:YES];
        [fetchRequest setSortDescriptors:[NSArray arrayWithObject:sort]];

        specialFetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest
                                                                              managedObjectContext:[OCNewsHelper sharedHelper].context
                                                                                sectionNameKeyPath:nil
                                                                                         cacheName:@"SpecialCache"];
        specialFetchedResultsController.delegate = self;
    }
    return specialFetchedResultsController;
}

- (NSFetchedResultsController *)foldersFetchedResultsController {
    if (!foldersFetchedResultsController) {
        NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
        NSEntityDescription *entity = [NSEntityDescription entityForName:@"Folder" inManagedObjectContext:[OCNewsHelper sharedHelper].context];
        [fetchRequest setEntity:entity];

        NSSortDescriptor *sort = [[NSSortDescriptor alloc] initWithKey:@"myId" ascending:YES];
        [fetchRequest setSortDescriptors:[NSArray arrayWithObject:sort]];

        foldersFetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest
                                                                              managedObjectContext:[OCNewsHelper sharedHelper].context
                                                                                sectionNameKeyPath:nil
                                                                                         cacheName:@"FolderCache"];
        foldersFetchedResultsController.delegate = self;
    }
    return foldersFetchedResultsController;
}

- (NSFetchedResultsController *)feedsFetchedResultsController {
    if (!feedsFetchedResultsController) {
        NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
        NSEntityDescription *entity = [NSEntityDescription entityForName:@"Feed" inManagedObjectContext:[OCNewsHelper sharedHelper].context];
        [fetchRequest setEntity:entity];

        NSPredicate *pred = [NSPredicate predicateWithFormat:@"myId > 0"];
        [fetchRequest setPredicate:pred];

        NSSortDescriptor *sort = [[NSSortDescriptor alloc] initWithKey:@"myId" ascending:YES];
        [fetchRequest setSortDescriptors:[NSArray arrayWithObject:sort]];
        
        feedsFetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest
                                                                            managedObjectContext:[OCNewsHelper sharedHelper].context
                                                                              sectionNameKeyPath:nil
                                                                                       cacheName:@"FeedCache"];
        feedsFetchedResultsController.delegate = self;
    }
    return feedsFetchedResultsController;
}

- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self) {
        [[NSUserDefaults standardUserDefaults] addObserver:self
                                                forKeyPath:SettingKeys.hideRead
                                                   options:NSKeyValueObservingOptionNew
                                                   context:NULL];
        
        [[NSUserDefaults standardUserDefaults] addObserver:self
                                                forKeyPath:SettingKeys.syncInBackground
                                                   options:NSKeyValueObservingOptionNew
                                                   context:NULL];
        
        [[NSUserDefaults standardUserDefaults] addObserver:self
                                                forKeyPath:SettingKeys.showFavIcons
                                                   options:NSKeyValueObservingOptionNew
                                                   context:NULL];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.clearsSelectionOnViewWillAppear = NO;
    self.tableView.allowsSelection = YES;
    self.tableView.allowsSelectionDuringEditing = YES;
    self.tableView.scrollsToTop = YES;
    self.tableView.tableFooterView = [UIView new];
    
    currentIndex = -1;
    networkHasBeenUnreachable = NO;
    

    self.refreshControl = self.feedRefreshControl;
    if (self.traitCollection.userInterfaceIdiom == UIUserInterfaceIdiomPad) {
        self.splitViewController.delegate = self;
    }
    self.splitViewController.presentsWithGesture = NO;

    //Notifications
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(reachabilityChanged:)
                                                 name:AFNetworkingReachabilityDidChangeNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(didBecomeActive:)
                                                 name:UIApplicationDidBecomeActiveNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(drawerOpened:)
                                                 name:@"DrawerOpened"
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(drawerClosed:)
                                                 name:@"DrawerClosed"
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(doRefresh:)
                                                 name:@"SyncNews"
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(networkCompleted:)
                                                 name:@"NetworkCompleted"
                                               object:nil];
    
    [self updatePredicate];
}

- (void)dealloc {
    [[NSUserDefaults standardUserDefaults] removeObserver:self forKeyPath:SettingKeys.hideRead];
    [[NSUserDefaults standardUserDefaults] removeObserver:self forKeyPath:SettingKeys.syncInBackground];
    [[NSUserDefaults standardUserDefaults] removeObserver:self forKeyPath:SettingKeys.showFavIcons];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    self.feedsFetchedResultsController.delegate = nil;
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    if (SettingsStore.server.length == 0) {
        [self doSettings:nil];
    }
}


#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    return 3;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
    switch (section) {
        case 0:
            return [self.specialFetchedResultsController fetchedObjects].count;
            break;
        case 1:
            return [self.foldersFetchedResultsController fetchedObjects].count;
            break;
        case 2:
            return [self.feedsFetchedResultsController fetchedObjects].count;
            break;
            
        default:
            return 0;
            break;
    }
    
    return 0;
}

- (void)configureCell:(FeedCell *)cell atIndexPath:(NSIndexPath *)indexPath {
    @try {
        NSIndexPath *indexPathTemp = [NSIndexPath indexPathForRow:indexPath.row inSection:0];
        if (indexPathTemp.row < [self.tableView numberOfRowsInSection:indexPath.section]) {
            if (indexPath.section == 1) {
                Folder *folder = [self.foldersFetchedResultsController objectAtIndexPath:indexPathTemp];
                [cell.imageView setImage:[UIImage imageNamed:@"folder"]];
                cell.textLabel.text = folder.name;
                cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
                cell.countBadge.value = folder.unreadCount;
            } else {
                Feed *feed;
                if (indexPath.section == 0) {
                    if (indexPath.row < 2) {
                        feed = [self.specialFetchedResultsController objectAtIndexPath:indexPathTemp];
                    }
                } else {
                    feed = [self.feedsFetchedResultsController objectAtIndexPath:indexPathTemp];
                }
                if (SettingsStore.showFavIcons) {
                    if (cell.tag == indexPathTemp.row) {
                        if ([feed.faviconLink isEqualToString:@"star_icon"]) {
                            [cell.imageView setImage:[UIImage imageNamed:@"star_icon"]];
                        } else {
                            [cell.imageView setFavIconFor:feed];
                        }
                    }
                }
                cell.accessoryType = UITableViewCellAccessoryNone;
                if ((self.folderId > 0) && (indexPath.section == 0) && indexPath.row == 0) {
                    Folder *folder = [[OCNewsHelper sharedHelper] folderWithId:self.folderId] ;
                    cell.countBadge.value = folder.unreadCount;
                    if (SettingsStore.hideRead) {
                        cell.textLabel.text = [NSString stringWithFormat:@"All Unread %@ Articles", folder.name];
                    } else {
                        cell.textLabel.text = [NSString stringWithFormat:@"All %@ Articles", folder.name];
                    }
                } else {
                    cell.countBadge.value = feed.unreadCount;
                    cell.textLabel.text = feed.title;
                }
            }
            
            cell.textLabel.textColor = [[ThemeColors alloc] init].pbhText;
            cell.contentView.backgroundColor = [UIColor clearColor];
        }
    }
    @catch (NSException *exception) {
        //
    }
    @finally {
        //
    }
    
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"Cell";
    FeedCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[FeedCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
        cell.selectionStyle = UITableViewCellSelectionStyleBlue;
        UIView * selectedBackgroundView = [[UIView alloc] initWithFrame:cell.frame];
        [selectedBackgroundView setBackgroundColor:[UIColor colorWithRed:0.87f green:0.87f blue:0.87f alpha:1.0f]]; // set color here
        [cell setSelectedBackgroundView:selectedBackgroundView];
    }
    cell.tag = indexPath.row;
    [self configureCell:cell atIndexPath:indexPath];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (@available(iOS 14.0, *)) {
        if (indexPath.section != 1) {
            NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
            currentIndex = indexPath.row;
            NSIndexPath *indexPathTemp = [NSIndexPath indexPathForRow:currentIndex inSection:0];
            Feed *feed;
            if (indexPath.section == 0) {
                feed = [self.specialFetchedResultsController objectAtIndexPath:indexPathTemp];
            } else {
                feed = [self.feedsFetchedResultsController objectAtIndexPath:indexPathTemp];
            }
            UINavigationController *navController = (UINavigationController *)[self.splitViewController viewControllerForColumn:UISplitViewControllerColumnSecondary];
            self.detailViewController = (ItemsListViewController *)navController.topViewController;
            self.detailViewController.feed = feed;
            if (self.folderId > 0) {
                self.detailViewController.folderId = self.folderId;
            }
            [self.detailViewController configureView];
            [self.splitViewController hideColumn:UISplitViewControllerColumnPrimary];
        }
    }
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be editable.
    return (indexPath.section > 0);
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        NSIndexPath *indexPathTemp = [NSIndexPath indexPathForRow:indexPath.row inSection:0];
        if (indexPath.section == 1) {
            [[OCNewsHelper sharedHelper] deleteFolderOffline:[self.foldersFetchedResultsController objectAtIndexPath:indexPathTemp]];
        } else if (indexPath.section == 2) {
            [[OCNewsHelper sharedHelper] deleteFeedOffline:[self.feedsFetchedResultsController objectAtIndexPath:indexPathTemp]];
        }
    }
}

// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
    //
}

// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    return NO;
}


#pragma mark - Table view delegate

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath {
    return UITableViewCellEditingStyleDelete;
}

- (void)tableView:(UITableView *)tableView settingsActionPressedInRowAtIndexPath:(NSIndexPath *)indexPath {
    NSIndexPath *indexPathTemp = [NSIndexPath indexPathForRow:indexPath.row inSection:0];
    if ((indexPath.section == 1)) {
        Folder *folder = [self.foldersFetchedResultsController objectAtIndexPath:indexPathTemp];
        currentRenameId = folder.myId;
        [[self.renameFolderAlertView.textFields objectAtIndex:0] setText:folder.name];
        [self presentViewController:self.renameFolderAlertView animated:YES completion:nil];
        self.renameFolderAlertView.view.tintColor = [UINavigationBar appearance].tintColor;
    } else if (indexPath.section == 2) {
        currentIndex = indexPathTemp.row;
        [self performSegueWithIdentifier:@"feedSettings" sender:self];
    }
    editingPath = indexPath;
}

- (UISwipeActionsConfiguration *)tableView:(UITableView *)tableView trailingSwipeActionsConfigurationForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0) {
        return nil;
    }

    UIContextualAction *deleteAction = [UIContextualAction contextualActionWithStyle:UIContextualActionStyleDestructive title:@"Delete" handler:^(UIContextualAction * _Nonnull action, __kindof UIView * _Nonnull sourceView, void (^ _Nonnull completionHandler)(BOOL)) {
        [self tableView:self.tableView commitEditingStyle:UITableViewCellEditingStyleDelete forRowAtIndexPath:indexPath];
    }];

    UIContextualAction *settingsAction = [UIContextualAction contextualActionWithStyle:UIContextualActionStyleNormal title:@"Settings" handler:^(UIContextualAction * _Nonnull action, __kindof UIView * _Nonnull sourceView, void (^ _Nonnull completionHandler)(BOOL)) {
        [self tableView:self.tableView settingsActionPressedInRowAtIndexPath:indexPath];
    }];

    UISwipeActionsConfiguration *config = [UISwipeActionsConfiguration configurationWithActions:@[deleteAction, settingsAction]];
    config.performsFirstActionWithFullSwipe = NO;
    return config;
}

- (UIContextMenuConfiguration *)tableView:(UITableView *)tableView contextMenuConfigurationForRowAtIndexPath:(NSIndexPath *)indexPath point:(CGPoint)point API_AVAILABLE(ios(13.0)) {
    if (indexPath.section == 0) {
        return nil;
    }

    self.currentIndex = indexPath.row;

    NSMutableArray *actions = [NSMutableArray new];
    
    UIAction *settingsAction = [UIAction actionWithTitle:@"Settings..." image:[UIImage systemImageNamed:@"gearshape"] identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
        [self tableView:self.tableView settingsActionPressedInRowAtIndexPath:indexPath];
    }];
    [actions addObject:settingsAction];
    
    if (indexPath.section == 2) {
        UIAction *folderAction = [UIAction actionWithTitle:@"Folder..." image:[UIImage systemImageNamed:@"folder"] identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
            NSIndexPath *indexPathTemp = [NSIndexPath indexPathForRow:self.currentIndex inSection:0];
            Feed *feed = [self.feedsFetchedResultsController objectAtIndexPath:indexPathTemp];
            
            UINavigationController *navController = [self.storyboard instantiateViewControllerWithIdentifier:@"FolderNavController"];
            
            FolderTableViewController *folderController = (FolderTableViewController *)navController.topViewController;
            folderController.feed = feed;
            folderController.folders = [[OCNewsHelper sharedHelper] folders];
            folderController.delegate = self;
            [self.navigationController presentViewController:navController animated:YES completion:nil];
        }];
        [actions addObject:folderAction];
    }
    
    UIAction *deleteAction = [UIAction actionWithTitle:@"Delete" image:[UIImage systemImageNamed:@"trash"] identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
        [self tableView:self.tableView commitEditingStyle:UITableViewCellEditingStyleDelete forRowAtIndexPath:indexPath];
    }];
    deleteAction.attributes = UIMenuElementAttributesDestructive;
    [actions addObject:deleteAction];
    
    UIContextMenuConfiguration *config = [UIContextMenuConfiguration configurationWithIdentifier:nil previewProvider:nil actionProvider:^UIMenu * _Nullable(NSArray<UIMenuElement *> * _Nonnull suggestedActions) {
        return [UIMenu menuWithTitle:@"" children:actions];
    }];
    return  config;
}

- (BOOL)shouldPerformSegueWithIdentifier:(NSString *)identifier sender:(id)sender {
    if ([identifier isEqualToString:DetailSegueIdentifier]) {
        if ([sender isKindOfClass:[UITableViewCell class]]) {
            UITableViewCell *cell = (UITableViewCell *)sender;
            if (cell.accessoryType == UITableViewCellAccessoryDisclosureIndicator) {
                if (self.folderId == 0) {
                    NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
                    currentIndex = indexPath.row;
                    NSIndexPath *indexPathTemp = [NSIndexPath indexPathForRow:currentIndex inSection:0];
                    OCFeedListController *folderController = [self.storyboard instantiateViewControllerWithIdentifier:@"feed_list"];
                    Folder *folder = [self.foldersFetchedResultsController objectAtIndexPath:indexPathTemp];
                    folderController.folderId = folder.myId;
                    folderController.navigationItem.title = folder.name;
                    [folderController updatePredicate];
                    folderController.detailViewController = self.detailViewController;
                    [self.navigationController pushViewController:folderController animated:YES];
                    [folderController drawerOpened];
                    [self drawerClosed];
                }
                return NO;
            }
        }
        return YES;
    }
    return YES;
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([[segue identifier] isEqualToString:DetailSegueIdentifier]) {
        NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
        currentIndex = indexPath.row;
        NSIndexPath *indexPathTemp = [NSIndexPath indexPathForRow:currentIndex inSection:0];

        if (@available(iOS 14.0, *)) {
            UINavigationController *navController = (UINavigationController *)[self.splitViewController viewControllerForColumn:UISplitViewControllerColumnSecondary];
            self.detailViewController = (ItemsListViewController *)navController.topViewController;
        } else {
            UINavigationController *navigationController = (UINavigationController *)segue.destinationViewController;
            self.detailViewController = (ItemsListViewController *)navigationController.topViewController;
        }

        if (!self.tableView.isEditing) {
            Folder *folder;
            Feed *feed;
            
            switch (indexPath.section) {
                case 0:
                    @try {
                        if (@available(iOS 14.0, *)) {
                            return;
                        } else {
                            if (self.splitViewController.displayMode == UISplitViewControllerDisplayModeAllVisible || self.splitViewController.displayMode == UISplitViewControllerDisplayModePrimaryOverlay) {
                                [UIView animateWithDuration:0.3 animations:^{
                                    self.splitViewController.preferredDisplayMode = UISplitViewControllerDisplayModePrimaryHidden;
                                } completion: nil];
                                feed = [self.specialFetchedResultsController objectAtIndexPath:indexPathTemp];
                                self.detailViewController.feed = feed;
                                if (self.folderId > 0) {
                                    self.detailViewController.folderId = self.folderId;
                                }
                            }
                        }
                    }
                    @catch (NSException *exception) {
                        //
                    }
                    break;
                case 1:
                    @try {
                        if (self.folderId == 0) {
                            OCFeedListController *folderController = [self.storyboard instantiateViewControllerWithIdentifier:@"feed_list"];
                            folder = [self.foldersFetchedResultsController objectAtIndexPath:indexPathTemp];
                            folderController.folderId = folder.myId;
                            folderController.navigationItem.title = folder.name;
                            [folderController updatePredicate];
                            folderController.detailViewController = self.detailViewController;
                            [self.navigationController pushViewController:folderController animated:YES];
                            [folderController drawerOpened];
                            [self drawerClosed];
                        }
                    }
                    @catch (NSException *exception) {
                        //
                    }
                    break;
                case 2:
                    @try {
                        feed = [self.feedsFetchedResultsController objectAtIndexPath:indexPathTemp];
                        self.detailViewController.feed = feed;
                        if (@available(iOS 14.0, *)) {
                            return;
                        } else {
                            if (self.splitViewController.displayMode == UISplitViewControllerDisplayModeAllVisible || self.splitViewController.displayMode == UISplitViewControllerDisplayModePrimaryOverlay) {
                                [[UIApplication sharedApplication] sendAction:self.splitViewController.displayModeButtonItem.action
                                                                           to:self.splitViewController.displayModeButtonItem.target
                                                                         from:nil
                                                                     forEvent:nil];
                            }
                            [UIView animateWithDuration:0.3 animations:^{
                                self.splitViewController.preferredDisplayMode = UISplitViewControllerDisplayModePrimaryHidden;
                            } completion: nil];
                        }
                    }
                    @catch (NSException *exception) {
                        //
                    }
                    break;
                    
                default:
                    break;
            }
            if (@available(iOS 14.0, *)) {
                self.detailViewController.navigationItem.leftItemsSupplementBackButton = YES;
            } else {
                self.detailViewController.navigationItem.leftBarButtonItem = self.splitViewController.displayModeButtonItem;
                self.detailViewController.navigationItem.leftItemsSupplementBackButton = YES;
            }
        }
    }
    if ([segue.identifier isEqualToString:@"feedSettings"]) {
        Feed *feed = [self.feedsFetchedResultsController.fetchedObjects objectAtIndex:currentIndex];
        UINavigationController *navController = (UINavigationController *)segue.destinationViewController;
        FeedSettings *settingsController = (FeedSettings*)navController.topViewController;
        settingsController.feed = feed;
        settingsController.delegate = self;
    }
}

#pragma mark - Actions

- (IBAction)onSettings:(id)sender {
    
    UIAlertController* alert = [UIAlertController alertControllerWithTitle:nil
                                                                   message:nil
                                                            preferredStyle:UIAlertControllerStyleActionSheet];
    
    UIAlertAction* cancelAction = [UIAlertAction actionWithTitle:@"Cancel"
                                                           style:UIAlertActionStyleCancel
                                                         handler:^(UIAlertAction * action) {
        //
    }];
    
    [alert addAction:cancelAction];
    
    UIAlertAction* settingsAction = [UIAlertAction actionWithTitle:@"Settings"
                                                             style:UIAlertActionStyleDefault
                                                           handler:^(UIAlertAction * action) {
        
        [self doSettings:action];
        
    }];
    
    [alert addAction:settingsAction];
    
    UIAlertAction* addFolderAction = [UIAlertAction actionWithTitle:@"Add Folder"
                                                              style:UIAlertActionStyleDefault
                                                            handler:^(UIAlertAction * action) {
        
        [self presentViewController:self.addFolderAlertView animated:YES completion:nil];
        self.addFolderAlertView.view.tintColor = [UINavigationBar appearance].tintColor;
    }];
    
    [alert addAction:addFolderAction];
    
    UIAlertAction* addFeedAction = [UIAlertAction actionWithTitle:@"Add Feed"
                                                            style:UIAlertActionStyleDefault
                                                          handler:^(UIAlertAction * action) {
        
        [self presentViewController:self.addFeedAlertView animated:YES completion:nil];
        self.addFeedAlertView.view.tintColor = [UINavigationBar appearance].tintColor;
    }];
    
    [alert addAction:addFeedAction];
    
    NSString *hideReadTitle = SettingsStore.hideRead ? @"Show Read" : @"Hide Read";
    UIAlertAction* hideReadAction = [UIAlertAction actionWithTitle:hideReadTitle
                                                             style:UIAlertActionStyleDefault
                                                           handler:^(UIAlertAction * action) {
        
        [self doHideRead];
        
    }];
    
    [alert addAction:hideReadAction];
    
    alert.modalPresentationStyle = UIModalPresentationPopover;
    
    UIPopoverPresentationController *popover = alert.popoverPresentationController;
    if (popover)
    {
        popover.barButtonItem = (UIBarButtonItem *)sender;
        popover.permittedArrowDirections = UIPopoverArrowDirectionAny;
        popover.backgroundColor = [[ThemeColors alloc] init].pbhCellBackground;
    }
    
    [self.navigationController presentViewController:alert animated:YES completion:^{
        alert.view.tintColor = [UINavigationBar appearance].tintColor;
    }];
    
    alert.view.tintColor = [UINavigationBar appearance].tintColor;
}

- (UIAlertController*)addFolderAlertView {
    static UIAlertController *alertController;
    static UIView *container;
    static UITextField *theTextField;
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^{
        alertController = [UIAlertController alertControllerWithTitle:@"Add New Folder" message:@"Enter the name of the folder to add." preferredStyle:UIAlertControllerStyleAlert];
        [alertController addTextFieldWithConfigurationHandler:^(UITextField *textField) {
            theTextField = textField;
            theTextField.keyboardType = UIKeyboardTypeDefault;
            theTextField.placeholder = @"Folder name";
        }];
        id fieldEditor = [theTextField valueForKey:@"fieldEditor"];
        UIView *fieldEditorAsView = (UIView *)fieldEditor;
        fieldEditorAsView.backgroundColor = UIColor.clearColor;
        for (UIView* textField in alertController.textFields) {
            container = textField.superview;
            UIView *effectView = container.superview.subviews[0].subviews[0];
            
            if (effectView && [effectView class] == [UIVisualEffectView class]) {
                container.backgroundColor = [UIColor clearColor];
                container.layer.borderWidth = 1;
                [effectView removeFromSuperview];
            }
        }
        
        UIAlertAction *cancelButton = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil];
        UIAlertAction *addButton = [UIAlertAction actionWithTitle:@"Add" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            [[OCNewsHelper sharedHelper] addFolderOffline:[[alertController.textFields objectAtIndex:0] text]];
        }];
        [alertController addAction:cancelButton];
        [alertController addAction:addButton];
    });
    container.layer.borderColor = [[ThemeColors alloc] init].pbhIcon.CGColor;
    NSDictionary *titleAttributes = @{NSFontAttributeName: [UIFont systemFontOfSize:17 weight:UIFontWeightSemibold], NSForegroundColorAttributeName:[[ThemeColors alloc] init].pbhText};
    NSDictionary *messageAttributes = @{NSFontAttributeName: [UIFont systemFontOfSize:13 weight:UIFontWeightRegular], NSForegroundColorAttributeName:[[ThemeColors alloc] init].pbhText};
    NSAttributedString *title = [[NSAttributedString alloc] initWithString:@"Add New Folder" attributes:titleAttributes];
    NSAttributedString *message = [[NSAttributedString alloc] initWithString:@"Enter the name of the folder to add." attributes:messageAttributes];
    [alertController setValue: title forKey: @"attributedTitle"];
    [alertController setValue: message forKey: @"attributedMessage"];
    return alertController;
}

- (UIAlertController*)renameFolderAlertView {
    static UIAlertController *alertController;
    static UIView *container;
    static UITextField *theTextField;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        alertController = [UIAlertController alertControllerWithTitle:@"Rename Folder" message:@"Enter the new name of the folder." preferredStyle:UIAlertControllerStyleAlert];
        [alertController addTextFieldWithConfigurationHandler:^(UITextField *textField) {
            theTextField = textField;
            theTextField.keyboardType = UIKeyboardTypeDefault;
            theTextField.placeholder = @"Folder name";
        }];
        id fieldEditor = [theTextField valueForKey:@"fieldEditor"];
        UIView *fieldEditorAsView = (UIView *)fieldEditor;
        fieldEditorAsView.backgroundColor = UIColor.clearColor;
        for (UIView* textField in alertController.textFields) {
            container = textField.superview;
            UIView *effectView = container.superview.subviews[0].subviews[0];
            
            if (effectView && [effectView class] == [UIVisualEffectView class]) {
                container.backgroundColor = [UIColor clearColor];
                container.layer.borderWidth = 1;
                [effectView removeFromSuperview];
            }
        }
        
        UIAlertAction *cancelButton = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
            [self.tableView setEditing:NO animated:YES];
        }];
        UIAlertAction *renameButton = [UIAlertAction actionWithTitle:@"Rename" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            [self.tableView setEditing:NO animated:YES];
            [[OCNewsHelper sharedHelper] renameFolderOfflineWithId:self->currentRenameId To:[[alertController.textFields objectAtIndex:0] text]];
        }];
        [alertController addAction:cancelButton];
        [alertController addAction:renameButton];
    });
    container.layer.borderColor = [[ThemeColors alloc] init].pbhIcon.CGColor;
    NSDictionary *placeholderAttributes = @{NSFontAttributeName: theTextField.font, NSForegroundColorAttributeName: [[ThemeColors alloc] init].pbhText};
    theTextField.attributedPlaceholder = [[NSAttributedString alloc] initWithString:@"Folder name" attributes:placeholderAttributes];
    NSDictionary *titleAttributes = @{NSFontAttributeName: [UIFont systemFontOfSize:17 weight:UIFontWeightSemibold], NSForegroundColorAttributeName: [[ThemeColors alloc] init].pbhText};
    NSDictionary *messageAttributes = @{NSFontAttributeName: [UIFont systemFontOfSize:13 weight:UIFontWeightRegular], NSForegroundColorAttributeName: [[ThemeColors alloc] init].pbhText};
    NSAttributedString *title = [[NSAttributedString alloc] initWithString:@"Rename Folder" attributes:titleAttributes];
    NSAttributedString *message = [[NSAttributedString alloc] initWithString:@"Enter the new name of the folder." attributes:messageAttributes];
    [alertController setValue: title forKey: @"attributedTitle"];
    [alertController setValue: message forKey: @"attributedMessage"];
    return alertController;
}

- (UIAlertController*)addFeedAlertView {
    static UIAlertController *alertController;
    static UIView *container;
    static UITextField *theTextField;
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^{
        alertController = [UIAlertController alertControllerWithTitle:@"Add New Feed" message:@"Enter the url of the feed to add." preferredStyle:UIAlertControllerStyleAlert];
        [alertController addTextFieldWithConfigurationHandler:^(UITextField *textField) {
            theTextField = textField;
            theTextField.keyboardType = UIKeyboardTypeURL;
            theTextField.placeholder = @"http://example.com/feed";
        }];
        id fieldEditor = [theTextField valueForKey:@"fieldEditor"];
        UIView *fieldEditorAsView = (UIView *)fieldEditor;
        fieldEditorAsView.backgroundColor = UIColor.clearColor;
        for (UIView* textField in alertController.textFields) {
            container = textField.superview;
            UIView *effectView = container.superview.subviews[0].subviews[0];
            
            if (effectView && [effectView class] == [UIVisualEffectView class]) {
                container.backgroundColor = [UIColor clearColor];
                container.layer.borderWidth = 1;
                [effectView removeFromSuperview];
            }
        }
        UIAlertAction *cancelButton = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil];
        UIAlertAction *addButton = [UIAlertAction actionWithTitle:@"Add" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            [[OCNewsHelper sharedHelper] addFeedOffline:[[alertController.textFields objectAtIndex:0] text]];
        }];
        [alertController addAction:cancelButton];
        [alertController addAction:addButton];
    });
    container.layer.borderColor = [[ThemeColors alloc] init].pbhIcon.CGColor;
    NSDictionary *titleAttributes = @{NSFontAttributeName: [UIFont systemFontOfSize:17 weight:UIFontWeightSemibold], NSForegroundColorAttributeName: [[ThemeColors alloc] init].pbhText};
    NSDictionary *messageAttributes = @{NSFontAttributeName: [UIFont systemFontOfSize:13 weight:UIFontWeightRegular], NSForegroundColorAttributeName: [[ThemeColors alloc] init].pbhText};
    NSAttributedString *title = [[NSAttributedString alloc] initWithString:@"Add New Feed" attributes:titleAttributes];
    NSAttributedString *message = [[NSAttributedString alloc] initWithString:@"Enter the url of the feed to add." attributes:messageAttributes];
    [alertController setValue: title forKey: @"attributedTitle"];
    [alertController setValue: message forKey: @"attributedMessage"];
    
    return alertController;
}

- (void)doHideRead {
    BOOL hideRead = SettingsStore.hideRead;
    SettingsStore.hideRead = !hideRead;
    [[OCNewsHelper sharedHelper] renameFeedOfflineWithId:-2 To:hideRead == YES ? @"All Articles" : @"All Unread Articles"];
}

- (IBAction)doSettings:(id)sender {
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    UINavigationController *nav;
    if ([sender isKindOfClass:[UIAlertAction class]]) {
        nav = [storyboard instantiateViewControllerWithIdentifier:@"login"];
        [nav.topViewController loadView];
        nav.modalPresentationStyle = UIModalPresentationFormSheet;
    } else {
        OCLoginController *lc = [storyboard instantiateViewControllerWithIdentifier:@"server"];
        nav = [[UINavigationController alloc] initWithRootViewController:lc];
        nav.modalPresentationStyle = UIModalPresentationFormSheet;
    }
    [self.navigationController presentViewController:nav animated:YES completion:nil];
}

- (IBAction)doRefresh:(id)sender {
    if (self.folderId == 0) {
        [[OCNewsHelper sharedHelper] sync:nil];
    } else {
        [[OCNewsHelper sharedHelper] updateFolderWithId:self.folderId];
    }
}

- (void)feedSettingsUpdateWithSettings:(FeedSettings * _Nonnull)settings {
    [self.tableView reloadData];
    [self.tableView setEditing:NO animated:YES];
}

- (void)observeValueForKeyPath:(NSString *) keyPath ofObject:(id) object change:(NSDictionary *) change context:(void *) context {
    if([keyPath isEqual:@"HideRead"]) {
        [self updatePredicate];
    }
    if([keyPath isEqual:@"SyncInBackground"]) {
        if (SettingsStore.syncInBackground) {
            [[UIApplication sharedApplication] setMinimumBackgroundFetchInterval:UIApplicationBackgroundFetchIntervalMinimum];
        } else {
            [[UIApplication sharedApplication] setMinimumBackgroundFetchInterval:UIApplicationBackgroundFetchIntervalNever];
        }
    }
    if([keyPath isEqual:@"ShowFavicons"]) {
        [self.tableView reloadData];
    }
}

- (void)updatePredicate {
    [NSFetchedResultsController deleteCacheWithName:@"SpecialCache"];
    [NSFetchedResultsController deleteCacheWithName:@"FolderCache"];
    [NSFetchedResultsController deleteCacheWithName:@"FeedCache"];
    NSPredicate *predFolder = [NSPredicate predicateWithFormat:@"folderId == %@", [NSNumber numberWithLong:self.folderId]];
    if (SettingsStore.hideRead) {
        NSPredicate *pred1 = [NSPredicate predicateWithFormat:@"myId > 0"];
        NSPredicate *pred2 = [NSPredicate predicateWithFormat:@"unreadCount == 0"];
        NSArray *predArray = @[pred1, pred2];
        NSPredicate *pred3 = [NSCompoundPredicate andPredicateWithSubpredicates:predArray];
        NSPredicate *pred4 = [NSCompoundPredicate notPredicateWithSubpredicate:pred3];
        NSArray *predArray1 = @[predFolder, pred1, pred4];
        NSPredicate *pred5 = [NSCompoundPredicate andPredicateWithSubpredicates:predArray1];
        [[self.feedsFetchedResultsController fetchRequest] setPredicate:pred5];
    } else{
        NSPredicate *pred1 = [NSPredicate predicateWithFormat:@"myId > 0"];
        NSArray *predArray = @[predFolder, pred1];
        NSPredicate *pred3 = [NSCompoundPredicate andPredicateWithSubpredicates:predArray];
        [[self.feedsFetchedResultsController fetchRequest] setPredicate:pred3];
    }
    
    if (self.folderId > 0) {
        self.specialFetchedResultsController.fetchRequest.predicate = [NSPredicate predicateWithFormat:@"myId == -2"];
        self.foldersFetchedResultsController.fetchRequest.predicate = [NSPredicate predicateWithValue:NO];
    } else {
        self.specialFetchedResultsController.fetchRequest.predicate = [NSPredicate predicateWithFormat:@"myId < 0"];
        self.foldersFetchedResultsController.fetchRequest.predicate = nil;
    }
    
    NSError *error;
    if (![[self specialFetchedResultsController] performFetch:&error]) {
        // Update to handle the error appropriately.
        //        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
    }
    if (![[self foldersFetchedResultsController] performFetch:&error]) {
        // Update to handle the error appropriately.
        //        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
    }
    if (![[self feedsFetchedResultsController] performFetch:&error]) {
        // Update to handle the error appropriately.
        //        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
    }
    
    [self.tableView reloadData];
}

- (void)reachabilityChanged:(NSNotification *)n {
    NSNumber *s = n.userInfo[AFNetworkingReachabilityNotificationStatusItem];
    AFNetworkReachabilityStatus status = [s integerValue];
    
    if (status == AFNetworkReachabilityStatusNotReachable) {
        networkHasBeenUnreachable = YES;
        [Messenger showMessageWithTitle:@"Unable to Reach Server"
                                   body:@"Please check network connection and login."
                                  theme: MessageThemeWarning];
    }
    if (status > AFNetworkReachabilityStatusNotReachable) {
        if (networkHasBeenUnreachable) {
            [Messenger showMessageWithTitle:@"Server Reachable"
                                       body:@"The network connection is working properly."
                                      theme: MessageThemeWarning];
            networkHasBeenUnreachable = NO;
        }
    }
}

- (void) didBecomeActive:(NSNotification *)n {
    if (SettingsStore.server.length == 0) {
        [self doSettings:nil];
    } else {
        if (SettingsStore.syncOnStart) {
            [[OCNewsHelper sharedHelper] performSelector:@selector(sync:) withObject:nil afterDelay:1.0f];
        }
        UIPasteboard *board = [UIPasteboard generalPasteboard];
        if (board.URL) {
            if (![board.URL.absoluteString isEqualToString:SettingsStore.previousPasteboardURL]) {
                SettingsStore.previousPasteboardURL = board.URL.absoluteString;
                NSArray *feedURLStrings = [self.feedsFetchedResultsController.fetchedObjects valueForKey:@"url"];
                if ([feedURLStrings indexOfObject:[board.URL absoluteString]] == NSNotFound) {
                    NSString *message = [NSString stringWithFormat:@"Would you like to add the feed: '%@'?", [board.URL absoluteString]];
                    [Messenger showAddMessageWithMessage:message viewController:self.navigationController callback:^{
                        [[OCNewsHelper sharedHelper] addFeedOffline:[board.URL absoluteString]];
                    }];
                }
            }
        }
    }
}

- (void)drawerOpened {
    if ([self.navigationController.topViewController isEqual:self]) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(networkError:) name:@"NetworkError" object:nil];
    }
    self.tableView.scrollsToTop = YES;
}

- (void)drawerClosed {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"NetworkError" object:nil];
    self.tableView.scrollsToTop = NO;
}

#pragma mark - Feeds maintenance

- (void) networkCompleted:(NSNotification *)n {
    [self.refreshControl endRefreshing];
    [self.detailViewController.collectionView.refreshControl endRefreshing];
}

- (void)networkError:(NSNotification *)n {
    [Messenger showMessageWithTitle:[n.userInfo objectForKey:@"Title"]
                               body:[n.userInfo objectForKey:@"Message"]
                              theme:MessageThemeError];
}

#pragma mark - Controls

- (UIRefreshControl *)feedRefreshControl {
    if (!feedRefreshControl) {
        feedRefreshControl = [[UIRefreshControl alloc] init];
        [feedRefreshControl addTarget:self action:@selector(doRefresh:) forControlEvents:UIControlEventValueChanged];
    }
    return feedRefreshControl;
}

#pragma mark - NSFetchedResultsControllerDelegate

- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller {
    // The fetch controller is about to start sending change notifications, so prepare the table view for updates.
    [self.tableView beginUpdates];
}

- (void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject atIndexPath:(NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type newIndexPath:(NSIndexPath *)newIndexPath {
    
    UITableView *tableView = self.tableView;
    if (newIndexPath != nil && controller == self.foldersFetchedResultsController) {
        newIndexPath = [NSIndexPath indexPathForRow:[newIndexPath row] inSection:1];
    }
    if (newIndexPath != nil && controller == self.feedsFetchedResultsController) {
        newIndexPath = [NSIndexPath indexPathForRow:[newIndexPath row] inSection:2];
    }
    if (indexPath != nil && controller == self.foldersFetchedResultsController) {
        indexPath = [NSIndexPath indexPathForRow:[indexPath row] inSection:1];
    }
    if (indexPath != nil && controller == self.feedsFetchedResultsController) {
        indexPath = [NSIndexPath indexPathForRow:[indexPath row] inSection:2];
    }
    
    switch(type) {
            
        case NSFetchedResultsChangeInsert:
            [tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:newIndexPath] withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        case NSFetchedResultsChangeDelete:
            [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        case NSFetchedResultsChangeUpdate:
            [self configureCell:(FeedCell*)[tableView cellForRowAtIndexPath:indexPath] atIndexPath:indexPath];
            break;
            
        case NSFetchedResultsChangeMove:
            [tableView deleteRowsAtIndexPaths:[NSArray
                                               arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
            [tableView insertRowsAtIndexPaths:[NSArray
                                               arrayWithObject:newIndexPath] withRowAnimation:UITableViewRowAnimationFade];
            break;
    }
}


- (void)controller:(NSFetchedResultsController *)controller didChangeSection:(id )sectionInfo atIndex:(NSUInteger)sectionIndex forChangeType:(NSFetchedResultsChangeType)type {
    
    switch(type) {
            
        case NSFetchedResultsChangeInsert:
            [self.tableView insertSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        case NSFetchedResultsChangeDelete:
            [self.tableView deleteSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationFade];
            break;
        default:
            break;
    }
}

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller {
    // The fetch controller has sent all current change notifications, so tell the table view to process all updates.
    [self.tableView endUpdates];
}

- (void)folderSelectedWithFolder:(NSInteger)folder {
    //
}

#pragma MARK - UISplitViewControllerDelegate

- (UISplitViewControllerDisplayMode)targetDisplayModeForActionInSplitViewController:(UISplitViewController *)svc {

    if (svc.displayMode == UISplitViewControllerDisplayModePrimaryHidden) {
        if (svc.traitCollection.horizontalSizeClass == UIUserInterfaceSizeClassRegular) {
            if (svc.traitCollection.userInterfaceIdiom == UIUserInterfaceIdiomPad) {
                return UISplitViewControllerDisplayModeAllVisible;
            } else if ([UIDevice currentDevice].orientation == UIDeviceOrientationLandscapeLeft || [UIDevice currentDevice].orientation == UIDeviceOrientationLandscapeRight) {
                return UISplitViewControllerDisplayModeAllVisible;
            }
        }
        return UISplitViewControllerDisplayModePrimaryOverlay;
    }
    return UISplitViewControllerDisplayModePrimaryHidden;
}

- (UISplitViewControllerColumn)splitViewController:(UISplitViewController *)svc topColumnForCollapsingToProposedTopColumn:(UISplitViewControllerColumn)proposedTopColumn API_AVAILABLE(ios(14.0)){
    return  UISplitViewControllerColumnPrimary;
}

- (BOOL)splitViewController:(UISplitViewController *)splitViewController collapseSecondaryViewController:(UIViewController *)secondaryViewController ontoPrimaryViewController:(UIViewController *)primaryViewController {
    if (self.traitCollection.userInterfaceIdiom == UIUserInterfaceIdiomPhone) {
        if (self.traitCollection.horizontalSizeClass == UIUserInterfaceSizeClassCompact) {
            return YES;
        }
    }
    return NO;
}

- (void)splitViewController:(UISplitViewController *)svc willChangeToDisplayMode:(UISplitViewControllerDisplayMode)displayMode {
    if (@available(iOS 14.0, *)) {
        if (!SettingsStore.isBackgroundSyncing) {
            if (UIApplication.sharedApplication.applicationState == UIApplicationStateBackground) {
                NSArray<NSIndexPath *> *visibleItems = self.detailViewController.collectionView.indexPathsForVisibleItems;
                if (visibleItems && visibleItems.count > 0) {
                    [self.detailViewController.collectionView reloadItemsAtIndexPaths:visibleItems];
                }
            }
        }
    }
}

- (void)hideSidebar {
    if (@available(iOS 14.0, *)) {
        [self.splitViewController hideColumn:UISplitViewControllerColumnPrimary];
    }
}

- (void)showSidebar {
    if (@available(iOS 14.0, *)) {
        [self.splitViewController showColumn:UISplitViewControllerColumnPrimary];
    }
}

@end
