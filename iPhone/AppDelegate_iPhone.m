//
//  AppDelegate_iPhone.m
//  RunQuest
//
//  Created by Joe Walsh on 9/11/10.
//  Copyright __MyCompanyName__ 2010. All rights reserved.
//

#import "AppDelegate_iPhone.h"
#import "MapViewController.h"
#import "MainMenuViewController.h"
#import "TrekListViewController.h"

@implementation AppDelegate_iPhone
@synthesize mapViewController, trekViewController;

#pragma mark -
#pragma mark Application lifecycle

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {    
	
    // Override point for customization after application launch.
	[self.window addSubview:self.mainMenuViewController.view];	
    [self.window makeKeyAndVisible];
	
	return YES;
}


- (void)applicationWillResignActive:(UIApplication *)application {
    /*
     Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
     Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
     */
	
}


- (void)applicationDidEnterBackground:(UIApplication *)application {
    /*
     Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
     If your application supports background execution, called instead of applicationWillTerminate: when the user quits.
     */
	if ( !self.mapViewController.trek )
		[self.mapViewController stopUpdatingLocation];
}


- (void)applicationWillEnterForeground:(UIApplication *)application {
    /*
     Called as part of  transition from the background to the inactive state: here you can undo many of the changes made on entering the background.
     */
	
	if ( !self.mapViewController.trek )
		[self.mapViewController startUpdatingLocation];
}


- (void)applicationDidBecomeActive:(UIApplication *)application {
    /*
     Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
     */
}


/**
 Superclass implementation saves changes in the application's managed object context before the application terminates.
 */
- (void)applicationWillTerminate:(UIApplication *)application {
	[super applicationWillTerminate:application];
}


#pragma mark -
#pragma mark Memory management

- (void)applicationDidReceiveMemoryWarning:(UIApplication *)application {
    [mainMenuViewController release];
    [super applicationDidReceiveMemoryWarning:application];
}


- (void)dealloc {
	[mainMenuViewController release];
	[mapViewController release];
	[super dealloc];
}

- (MainMenuViewController *)mainMenuViewController
{
	if (!mainMenuViewController) {
		mainMenuViewController = [[MainMenuViewController alloc] init]; 
		[mainMenuViewController setDelegate:self];
	}
	return mainMenuViewController;
}

#pragma mark -
#pragma mark MainMenuViewControllerDelegate methods

- (void)mainMenuViewControllerPlayButtonPressed:(MainMenuViewController *)controller
{
	[mainMenuViewController.view removeFromSuperview];
	self.mapViewController = [[MapViewController alloc] initWithNibName:@"MapViewController" bundle:nil];
	self.mapViewController.view.frame = self.window.bounds;
	[self.window addSubview:self.mapViewController.view];
}

- (void)mainMenuViewControllerTreksButtonPressed:(MainMenuViewController *)controller {
	TrekListViewController *trekListVC = [[TrekListViewController alloc] initWithNibName:@"TrekListView" bundle:nil];
	
	NSFetchRequest *request = [[NSFetchRequest alloc] init];
	[request setEntity:[NSEntityDescription entityForName:@"Trek" inManagedObjectContext:self.managedObjectContext]];
	[request setSortDescriptors:[NSArray arrayWithObjects:[NSSortDescriptor sortDescriptorWithKey:@"date" ascending:NO], nil]];
	
	NSFetchedResultsController *resultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:request managedObjectContext:self.managedObjectContext sectionNameKeyPath:@"date" cacheName:@"uhh"];
	[request release];
	
	trekListVC.fetchedResultsController= resultsController;
	[resultsController release];
	
	UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:trekListVC];
	[trekListVC release];
	
	self.trekViewController = navController;
	[navController release];
	
	[mainMenuViewController.view removeFromSuperview];
	self.trekViewController.view.frame = self.window.bounds;
	[self.window addSubview:self.trekViewController.view];
}


@end

