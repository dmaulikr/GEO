#import "WeightLogListViewController.h"

// frameworks
#import <CoreData/CoreData.h>

// models
#import "RQConstants.h"
#import "RQModelController.h"
#import "M3SimpleCoreData.h"
#import "RQWeightLogEntry.h"

// controllers
#import "WeightLogEventEditViewController.h"

// views
#import "WeightLogListCell.h"

@implementation WeightLogListViewController

#pragma mark -
#pragma mark Initialization

- (id)init
{
	if (self = [super initWithNibName:@"WeightLogListView" bundle:nil]) {
		[[self navigationItem] setTitle:@"Previous Weight-ins"];
		
		NSFetchRequest *request = [[NSFetchRequest alloc] init];
		NSManagedObjectContext *moc = [[[RQModelController defaultModelController] simpleCoreData] managedObjectContext];
		[request setEntity:[NSEntityDescription entityForName:@"WeightLogEntry" inManagedObjectContext:moc]];
		[request setSortDescriptors:[NSArray arrayWithObjects:[NSSortDescriptor sortDescriptorWithKey:@"dateTaken" ascending:NO], nil]];
		NSFetchedResultsController *resultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:request managedObjectContext:moc sectionNameKeyPath:nil cacheName:@"WeightLogEntries"];
		[request release];
		self.fetchedResultsController = resultsController;
		[self.fetchedResultsController setDelegate:self];
		[resultsController release];
	}
	return self;
}

- (void)dealloc
{
	// outlets
	[tableView release]; tableView = nil;
	[cellTemplate release]; cellTemplate = nil;
	
	[_formatter release]; _formatter = nil;
	[fetchedResultsController release];
	[super dealloc];
}

@synthesize fetchedResultsController;

@synthesize tableView;
@synthesize cellTemplate;

#pragma mark -
#pragma mark View lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
	_formatter = [[NSDateFormatter alloc] init];
	[_formatter setDateStyle:NSDateFormatterShortStyle];
	NSError *error = nil;
	[self.fetchedResultsController performFetch:&error];
	if ( error )
		CCLOG(@"%@", error);  // TODO: care
	
	[self.tableView setBackgroundColor:[UIColor colorWithRed:0.060 green:0.069 blue:0.079 alpha:1.000]];
	[self.tableView setSeparatorColor:[UIColor colorWithRed:0.204 green:0.212 blue:0.222 alpha:1.000]]; 
}

- (void)viewWillDisappear:(BOOL)animated
{
	[[RQModelController defaultModelController] save];
	[super viewWillDisappear:animated];
}

#pragma mark -
#pragma mark Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
	return @"Weight              Date                    Total Lost";
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [[self.fetchedResultsController.sections objectAtIndex:section] numberOfObjects];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    WeightLogListCell *cell = (WeightLogListCell *)[self.tableView dequeueReusableCellWithIdentifier:@"WeightLogListCell"];
    if (cell == nil) {
        UIViewController *temporaryController = [[UIViewController alloc] initWithNibName:@"WeightLogListCell" bundle:nil];
        cell = (WeightLogListCell *)temporaryController.view;
        [temporaryController release];
    }
    
	[self configureCell:cell atIndexPath:indexPath];
    return cell;
}

- (void)configureCell:(WeightLogListCell*)cell atIndexPath:(NSIndexPath*)indexPath
{
	cell.backgroundColor = [UIColor colorWithRed:0.060 green:0.069 blue:0.079 alpha:1.000];
	@try {
		id object = [fetchedResultsController objectAtIndexPath:indexPath];
		
		NSString *weightString = nil;
		NSDecimalNumber *weightAsPounds = [object valueForKey:@"weightTaken"];
		if ([[[NSUserDefaults standardUserDefaults] objectForKey:@"RQDisplayWeightAsGrams"] boolValue]) {
			NSDecimalNumber *weightAsGrams = [weightAsPounds decimalNumberByDividingBy:[NSDecimalNumber decimalNumberWithString:@"2.2"]];
			weightString = [[[RQModelController defaultModelController] calorieFormatter] stringFromNumber:weightAsGrams];
		} else {
			weightString = [[[RQModelController defaultModelController] calorieFormatter] stringFromNumber:weightAsPounds];
		}
		
		[cell.weightLabel setText:weightString];
		
		
		NSString *weightLostString = nil;
		NSDecimalNumber *weightLostAsOfSelfAsPounds = [(RQWeightLogEntry *)object weightLostAsOfSelf];
		if ([[[NSUserDefaults standardUserDefaults] objectForKey:@"RQDisplayWeightAsGrams"] boolValue]) {
			NSDecimalNumber *weightLostAsOfSelfAsGrams = [weightLostAsOfSelfAsPounds decimalNumberByDividingBy:[NSDecimalNumber decimalNumberWithString:@"2.2"]];
			weightLostString = [[[RQModelController defaultModelController] calorieFormatter] stringFromNumber:weightLostAsOfSelfAsGrams];
		} else {
			weightLostString = [[[RQModelController defaultModelController] calorieFormatter] stringFromNumber:weightLostAsOfSelfAsPounds];
		}
		[cell.weightLostLabel setText:weightLostString];
		
		[cell.dateLabel setText:[_formatter stringForObjectValue:[object valueForKey:@"dateTaken"]]];
		
	}
	@catch (NSException * e) {
		CCLOG(@"%@",e);
		[cell.weightLabel setText:@""];
		[cell.weightLostLabel setText:@""];
		[cell.dateLabel setText:@""];	
	}
	@finally {
		
	}
	
}

- (NSInteger)tableView:(UITableView *)tableView sectionForSectionIndexTitle:(NSString *)title atIndex:(NSInteger)index {
	return 0;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
	if (editingStyle == UITableViewCellEditingStyleDelete) {
		RQWeightLogEntry *entryToDelete = [fetchedResultsController objectAtIndexPath:indexPath];
		[[RQModelController defaultModelController] deleteWeightLogEntry:entryToDelete];
	}
}

#pragma mark -
#pragma mark Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	WeightLogEventEditViewController *controller = [[WeightLogEventEditViewController alloc] init];
	id object = [fetchedResultsController objectAtIndexPath:indexPath];
	[controller setWeightLogEntry:object];
	[controller setDelegate:self];
	[self presentModalViewController:controller animated:YES];
	[controller release];
}

- (UIView *)tableView:(UITableView *)aTableView viewForHeaderInSection:(NSInteger)section
{
	UIView *containerView =	[[[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 25)] autorelease];
    containerView.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.8];
	UILabel *headerLabel = [[[UILabel alloc] initWithFrame:CGRectMake(10, 0, 310, 25)] autorelease];
    headerLabel.text = [self tableView:aTableView titleForHeaderInSection:section];
    headerLabel.textColor = [UIColor whiteColor];
    headerLabel.shadowColor = [UIColor blackColor];
    headerLabel.shadowOffset = CGSizeMake(0, 1);
    headerLabel.font = [UIFont boldSystemFontOfSize:15];
    headerLabel.backgroundColor = [UIColor clearColor];
    [containerView addSubview:headerLabel];
	return containerView;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
	return 25;
}

#pragma mark -
#pragma mark WeightLogEventEditViewControllerDelegate methods

- (void)weightLogEventEditViewControllerDidEnd:(WeightLogEventEditViewController *)controller
{
	[self dismissModalViewControllerAnimated:YES];
	[self.tableView deselectRowAtIndexPath:self.tableView.indexPathForSelectedRow animated:YES];
}

#pragma mark -
#pragma mark NSFetchedResultsControllerDelegate methods

- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller {
    CCLOG(@"controllerWillChangeContent");
	[self.tableView beginUpdates];
}

- (void)controller:(NSFetchedResultsController *)controller didChangeSection:(id <NSFetchedResultsSectionInfo>)sectionInfo
		   atIndex:(NSUInteger)sectionIndex forChangeType:(NSFetchedResultsChangeType)type {
	
    switch(type) {
        case NSFetchedResultsChangeInsert:
            [self.tableView insertSections:[NSIndexSet indexSetWithIndex:sectionIndex]
						  withRowAnimation:UITableViewRowAnimationFade];
            break;
			
        case NSFetchedResultsChangeDelete:
            [self.tableView deleteSections:[NSIndexSet indexSetWithIndex:sectionIndex]
						  withRowAnimation:UITableViewRowAnimationFade];
            break;
    }
}


- (void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject
	   atIndexPath:(NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type
	  newIndexPath:(NSIndexPath *)newIndexPath {
	
    UITableView *theTableView = self.tableView;
	
    switch(type) {
			
        case NSFetchedResultsChangeInsert:
            [theTableView insertRowsAtIndexPaths:[NSArray arrayWithObject:newIndexPath]
							 withRowAnimation:UITableViewRowAnimationFade];
            break;
			
        case NSFetchedResultsChangeDelete:
            [theTableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath]
							 withRowAnimation:UITableViewRowAnimationFade];
            break;
			
        case NSFetchedResultsChangeUpdate:
            [self configureCell:(WeightLogListCell *)[theTableView cellForRowAtIndexPath:indexPath] atIndexPath:indexPath];
            break;
			
        case NSFetchedResultsChangeMove:
            [theTableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath]
							 withRowAnimation:UITableViewRowAnimationFade];
            [theTableView insertRowsAtIndexPaths:[NSArray arrayWithObject:newIndexPath]
							 withRowAnimation:UITableViewRowAnimationFade];
            break;
    }
}


- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller {
    CCLOG(@"controllerDidChangeContent");
    [self.tableView endUpdates];
}


@end
