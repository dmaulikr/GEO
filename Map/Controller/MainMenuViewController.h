//
//  MainMenuViewController.h
//  RunQuest
//
//  Created by Michael Zornek on 9/24/10.
//  Copyright 2010 Clickable Bliss. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SettingsViewController.h"
#import "DeveloperToolboxViewController.h"
#import "StoryViewController.h"
#import "RQBattleViewController.h"

@protocol MainMenuViewControllerDelegate;

@interface MainMenuViewController : UIViewController <StoryViewControllerDelegate, SettingsViewControllerDelegate, DeveloperToolboxViewControllerDelegate>
{
	
}

@property (readwrite, assign) id <MainMenuViewControllerDelegate> delegate;

@property (nonatomic, retain) IBOutlet UIButton *visitDrGordonButton;

- (IBAction)playButtonPressed:(id)sender;
- (IBAction)optionsButtonPressed:(id)sender;
- (IBAction)visitDrGordon:(id)sender;
- (IBAction)logButtonPressed:(id)sender;
- (IBAction)developerToolboxButtonPressed:(id)sender;
- (IBAction)storyButtonPressed:(id)sender;
- (IBAction)doneBrowsingLogBook:(id)sender;
- (IBAction)doneBrowsingDevToolbox:(id)sender;

@end


@protocol MainMenuViewControllerDelegate 
- (void)presentStory:(MainMenuViewController *)controller;
- (void)mainMenuViewControllerPlayButtonPressed:(MainMenuViewController *)controller;
- (void)mainMenuViewControllerStoryButtonPressed:(MainMenuViewController *)controller;
@end