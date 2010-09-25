//
//  AppDelegate_iPhone.h
//  RunQuest
//
//  Created by Joe Walsh on 9/11/10.
//  Copyright __MyCompanyName__ 2010. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AppDelegate_Shared.h"

@class MainMenuViewController;
@class MapViewController;

@interface AppDelegate_iPhone : AppDelegate_Shared {
	
}

@property (nonatomic, retain) MainMenuViewController *mainMenuViewController;
@property (nonatomic, retain) MapViewController *mapViewController;

@end

