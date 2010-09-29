//
//  RQBattleTestViewController.m
//  FlickSample
//
//  Created by Nome on 9/16/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "RQBattleViewController.h"
#import <QuartzCore/QuartzCore.h>
#import "RQSprite.h"
#import "RQEnemySprite.h"
#import "RQBattle.h"
#import "RQMob.h"
#import "RQHero.h"
#import "RQEnemy.h"
#import "RQWeaponSprite.h"
#import "RQBattleVictoryViewController.h"
#import "SimpleAudioEngine.h"
#import <AudioToolbox/AudioToolbox.h>
#import <AVFoundation/AVFoundation.h>
#import "RQModelController.h"
#import "M3CoreDataManager.h"
#import "RQPassthroughView.h"

@implementation RQBattleViewController

- (id)init
{
	if (self = [super init]) {
		weaponSprites = [[NSMutableArray alloc] init];
		battle = [[RQBattle alloc] init];
	}
	return self;
}

- (void)dealloc
{
	NSLog(@"RQBattleViewController -dealloc called...");
	[self stopAnimation];
#if TARGET_OS_EMBEDDED 
	[_captureLayer removeFromSuperlayer];
	_captureLayer.session = nil;
	[_captureLayer release];
	
	[_captureSession stopRunning];
	[_captureSession release];
	_captureSession = nil;
#endif
	[frontFlashView release], frontFlashView = nil;
	[heroHeathLabel release]; heroHeathLabel = nil;
	[weaponSprites release]; weaponSprites = nil;
	[battleVictoryViewController release]; battleVictoryViewController = nil;
	[battle release]; battle = nil;
	[evilBoobsMonster release];
    [super dealloc];
}
@synthesize delegate;
@synthesize battleVictoryViewController;
@synthesize battle;
@synthesize activeWeapon;
@synthesize frontFlashView;

- (void)viewDidLoad {
    [super viewDidLoad];
#if TARGET_OS_EMBEDDED
	_captureSession = [[AVCaptureSession alloc] init];
	
	NSError *error = nil;
	
	AVCaptureDevice *defaultVideoDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
	
	if ( defaultVideoDevice )  {
		AVCaptureDeviceInput *defaultVideoDeviceInput = [AVCaptureDeviceInput deviceInputWithDevice:defaultVideoDevice error:&error];
	
		if (error)
		//TODO: CARE
			NSLog(@"%@", error);
	
		[_captureSession addInput: defaultVideoDeviceInput];
		_captureLayer = [[AVCaptureVideoPreviewLayer layerWithSession:_captureSession] retain];
		_captureLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
		_captureLayer.frame = self.view.layer.bounds;
		[self.view.layer addSublayer:_captureLayer];
		[_captureSession startRunning];
	}
#endif

	
	self.view.backgroundColor = [UIColor scrollViewTexturedBackgroundColor];
	
	// Setup the run button
	UIButton *runButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
	[runButton setTitle:@"Run" forState:UIControlStateNormal];
	[runButton addTarget:self action:@selector(runButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
	[self.view addSubview:runButton];
	[runButton setFrame:CGRectMake(self.view.frame.size.width-44.0, 0.0, 44.0, 44.0)];
	
	// Setup the textual hp meter
	NSString *typicalHPReading = @"9999/9999";
	UIFont *heroHeathLabelFont = [UIFont boldSystemFontOfSize:22];
	CGSize heroHeathLabelSize = [typicalHPReading sizeWithFont:heroHeathLabelFont];
	heroHeathLabel = [[UILabel alloc] initWithFrame:CGRectMake(self.view.frame.size.width/2, self.view.frame.size.height - 110, self.view.frame.size.width/2, heroHeathLabelSize.height)];
	[self.view addSubview:heroHeathLabel];
	heroHeathLabel.font = heroHeathLabelFont;
	heroHeathLabel.textAlignment = UITextAlignmentRight;
	heroHeathLabel.backgroundColor = [UIColor clearColor];
	heroHeathLabel.textColor = [UIColor whiteColor];
	heroHeathLabel.shadowColor= [UIColor blackColor];
	heroHeathLabel.shadowOffset = CGSizeMake(1.0, 1.0);
	heroHeathLabel.text = typicalHPReading;
	
	// Setup the flick threshold visual
	//UIView *flickThresholdLine = [[UIView alloc] initWithFrame:CGRectMake(0, RQBattleViewFlickThreshold, self.view.frame.size.width, 2.0)];
//	[self.view addSubview:flickThresholdLine];
//	flickThresholdLine.backgroundColor = [UIColor yellowColor];
	
	// setup weaponSprite Array
	RQWeaponSprite *weaponSprite;
	NSString *weaponImageName;
	RQElementalType weaponType;
	UIImageView *weaponImageView;
	int xloc = 40;
	for (NSDictionary *weapon in self.battle.hero.weapons) {
		
		weaponType = RQElementalTypeNone;
		
		switch ([[weapon objectForKey:@"type"] integerValue]) {
			case RQElementalTypeFire:
				weaponImageName = @"fire_button";
				weaponType = RQElementalTypeFire;
				break;
			case RQElementalTypeWater:
				weaponImageName = @"water_button";
				weaponType = RQElementalTypeWater;
				break;
			case RQElementalTypeEarth:
				weaponImageName = @"earth_button";
				weaponType = RQElementalTypeEarth;
				break;
			case RQElementalTypeAir:
				weaponImageName = @"air_button";
				weaponType = RQElementalTypeAir;
				break;
		}
		
		weaponImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:weaponImageName]];
		weaponSprite = [[RQWeaponSprite alloc] initWithView:weaponImageView];
		[weaponImageView release];
		[weaponSprite setWeaponDetails:weapon];
		[weaponSprite setType:weaponType];
		[weaponSprites addObject:weaponSprite];
		[self.view addSubview:weaponSprite.view];
		weaponSprite.position = CGPointMake(xloc, self.view.frame.size.height - 40);
		weaponSprite.orininalPosition = weaponSprite.position;
		xloc = xloc + 80;
		weaponSprite.velocity = CGPointZero;
		[weaponSprite release]; weaponSprite = nil;
	}
	
	UIImage *monsterImage = [UIImage imageNamed:self.battle.enemy.spriteImageName];
	
	UIImageView *monsterView = [[UIImageView alloc] initWithImage:monsterImage];
	//NSLog(@"w %f h %f s %f", monsterImage.size.width, monsterImage.size.height, monsterImage.scale);
    monsterView.frame = CGRectMake(1.350, 8.5, monsterImage.size.width, monsterImage.size.height);
	evilBoobsMonster = [[RQEnemySprite alloc] initWithView:monsterView];
	[monsterView release];

	[self.view addSubview:evilBoobsMonster.view];
	
	evilBoobsMonster.position = CGPointMake(160.0, 100.0);
	evilBoobsMonster.velocity = CGPointZero;
	
	monsterCounter = 0;
	lastCollisionTime = 0.0;
	
	// Setup the self hit visual
	// TODO: Taking this out for now as it bugs out flicking. Should be introduced with a new hit graphic/effect on the weapons via Matt. 
	self.frontFlashView = [[[RQPassthroughView alloc] initWithFrame:self.view.frame] autorelease];
	CGRect ffFrame = self.frontFlashView.frame;
	ffFrame.origin.x = 0.0;
	ffFrame.origin.y = 0.0;
	self.frontFlashView.frame = ffFrame;
	frontFlashView.alpha = 0.0;
	frontFlashView.backgroundColor = [UIColor redColor];
	[self.view addSubview:frontFlashView];
	
	[self setupGameLoop];
	[self startAnimation];
	
    [[SimpleAudioEngine sharedEngine] playBackgroundMusic:@"RQ_Battle_Song.m4a" loop:YES];
}

- (void)viewDidAppear:(BOOL)animated {
	[super viewDidAppear:animated];
}


- (void)tick
{	
	NSTimeInterval currentTime = CACurrentMediaTime();
	NSTimeInterval deltaTime = currentTime - previousTickTime;
	previousTickTime = currentTime;
	
	//NSLog(@"tick, battle status hero %@ and enemy %@", self.battle.hero, self.battle.enemy);

	
	// game sim stuff
	[self.battle updateCombatantStaminaBasedOnTimeDelta:deltaTime];
	
	// Move the monster around
	CGFloat newMonsterX = 160.0 + (80.0 * sin((float)monsterCounter / 30.0));
	CGFloat newMonsterY = 100.0 + (30.0 * sin((float)monsterCounter / 15.0));
	CGFloat newMonsterZ = 0.75 + (0.5 * sin((float)monsterCounter * 0.008));
	evilBoobsMonster.view.transform = CGAffineTransformMakeScale(newMonsterZ, newMonsterZ);
	evilBoobsMonster.position = CGPointMake(newMonsterX, newMonsterY);
	monsterCounter++;
	
	// Figure out if the monster has been hit
	BOOL monsterHit = [evilBoobsMonster isIntersectingRect:activeWeapon.view.frame];
	
	if (monsterHit) {
		lastCollisionTime = currentTime;
		NSDictionary *result = [self.battle issueAttackCommandFrom:self.battle.hero withWeaponOfType:activeWeapon.type];
		if ([[result objectForKey:@"status"] isEqualToString:@"hit"]) {
			[evilBoobsMonster hitWithText:[(NSNumber *)[result objectForKey:@"attackValue"] stringValue]];
			float hpPercent = self.battle.enemy.currentHP * 1.0f / self.battle.enemy.maxHP;
			[[evilBoobsMonster enemyHealthMeter] setProgress:hpPercent];
			
			NSInteger attackValue = [[result objectForKey:@"attackValue"] integerValue];
			if ( (1.0f* attackValue / self.battle.enemy.currentHP) < .10f )
				[[SimpleAudioEngine sharedEngine] playEffect:@"Hit_004.caf"];
			else
				[[SimpleAudioEngine sharedEngine] playEffect:@"Critical_Hit.caf"];
			
		}
	} else {
		// If they have let go of the weapon move it based on velocity.
		if (!self.activeWeapon.touch)
		{
			activeWeapon.position = CGPointMake(activeWeapon.position.x + (activeWeapon.averageVelocity.x * deltaTime),
												activeWeapon.position.y + (activeWeapon.averageVelocity.y * deltaTime));
			// While moving the weapon we want to simulate perspective
			// If the weapon is past the flick threshold start to scale the weapon sprite
			if (activeWeapon.position.y < RQBattleViewFlickThreshold) {
				float scaleBasedOnPosition = ((activeWeapon.position.y / RQBattleViewFlickThreshold) * 50 + 50) / 100;
				CGRect newFrame = CGRectMake(activeWeapon.view.frame.origin.x, activeWeapon.view.frame.origin.y, activeWeapon.fullSize.width * scaleBasedOnPosition, activeWeapon.fullSize.height * scaleBasedOnPosition);
				activeWeapon.view.frame = newFrame;
			}
		}
		
		// Run ememy AI if they have not been hit
		if (self.battle.enemy.stamina >= 1.0) {
			NSDictionary *enemyAttackResult = [self.battle issueAttackCommandFrom:self.battle.enemy  withWeaponOfType:RQElementalTypeNone];
			if ([[enemyAttackResult objectForKey:@"status"] isEqualToString:@"hit"]) {
				AudioServicesPlaySystemSound(kSystemSoundID_Vibrate);
				[[SimpleAudioEngine sharedEngine] playEffect:@"Critical_Hit.caf"];
				CABasicAnimation *flash = [CABasicAnimation animationWithKeyPath:@"opacity"];
				flash.fromValue = [NSNumber numberWithFloat:0.0f];
				flash.toValue = [NSNumber numberWithFloat:0.8f];
				flash.autoreverses = YES;
				flash.duration = 0.3;
				flash.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear];
				[self.frontFlashView.layer addAnimation:flash forKey:@"opacity"];
			}
		} // end ememy AI
	}
	
	if (currentTime > lastCollisionTime + 1.0) {
		
	}
	
	// Update the hero health meter
	heroHeathLabel.text = [NSString stringWithFormat:@"%d/%d", self.battle.hero.currentHP, self.battle.hero.maxHP];
	
	// Update the weapons to help visualize the hero stamina
	for (RQWeaponSprite *weaponSprite in weaponSprites) {
		float previousOpacity = weaponSprite.view.layer.opacity;
		weaponSprite.view.layer.opacity = self.battle.hero.stamina;
		// if we are at the last step of making the weapons enabled play a sound cue
		if (previousOpacity < weaponSprite.view.layer.opacity && weaponSprite.view.layer.opacity >= 1.0) {
			[[SimpleAudioEngine sharedEngine] playEffect:@"chimp_001.caf"];
		}
	}
	
	// If the weapon leaves the view frame or we hit the monster reset the position of the weapon
	if ((!CGRectContainsPoint(self.view.frame, activeWeapon.position)) || monsterHit){
		activeWeapon.view.frame = CGRectMake(activeWeapon.view.frame.origin.x, activeWeapon.view.frame.origin.y, activeWeapon.fullSize.width, activeWeapon.fullSize.height);
		// Make sure to edit the position after setting the frame (for scale) .. doing it before results in a slight error in position.
		activeWeapon.position = activeWeapon.orininalPosition;
		activeWeapon.velocity = CGPointZero;
		[self setActiveWeapon:nil];
	}
	
	// check for end of battle conditions and if done, present the victory screen
	if (self.battle.isBattleDone) {
		[self stopAnimation];
		if (self.battle.hero.currentHP > 0) {
			[UIView animateWithDuration:1.0 
								  delay:0.0 
								options:UIViewAnimationCurveLinear 
							 animations:^(void) {
								 [evilBoobsMonster runDeathAnimation];
								 evilBoobsMonster.view.transform = CGAffineTransformMakeScale(0.01, 0.01);
							 } 
							 completion:^(BOOL finished) {
								 [self presentVictoryScreen];
							 }];
		} else {
			[self presentVictoryScreen];
		}
		
	}
	
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
	// If the user tries to active a weapon while the hero stamina is not full, say no
	
	
	// When a touch begins we need to assign an active weapon (as long as there isn't a current active weapon)
	if (!activeWeapon) {
		UITouch *touch = [touches anyObject];
		CGPoint touchLocation = [touch locationInView:self.view];
		
		// find out which weapon they are touching
		for (RQWeaponSprite *weapon in weaponSprites) {
			if (CGRectContainsPoint(weapon.view.frame, touchLocation)) {
				weapon.touch = touch;
				[self setActiveWeapon:weapon];
				previousTouchTimestamp = touch.timestamp;
			}
		}
	}
}

- (void)releaseActiveWeapon {
	// when touch is nil the game loop will begin to update it's position based on velocity
	self.activeWeapon.touch = nil;
	//NSLog(@"self.activeWeapon.velocity x %f y %f", self.activeWeapon.velocity.x, self.activeWeapon.velocity.y);
	
	// if the velocity was too low do not "fire" the weapon but reset it
	float min_velocity = 1000.0;
	if ( sqrt(pow(self.activeWeapon.averageVelocity.x, 2) + pow(self.activeWeapon.averageVelocity.y, 2)) < min_velocity )
	{
		CGFloat deltaX = -.1f*(activeWeapon.position.x - activeWeapon.orininalPosition.x);
		CGFloat deltaY = -.1f*(activeWeapon.position.y - activeWeapon.orininalPosition.y);
		
		[UIView animateWithDuration:0.25f 
						 animations:
		 ^{activeWeapon.position = CGPointMake(activeWeapon.orininalPosition.x + deltaX, activeWeapon.orininalPosition.y + deltaY);} 
						 completion: 
		 ^(BOOL finished){[UIView animateWithDuration:0.1 animations:^{activeWeapon.position = activeWeapon.orininalPosition;
			[self setActiveWeapon:nil];}]; }];
		activeWeapon.velocity = CGPointZero;
		
	} else {
		// Only play the launch sounds when the weapon will be moving
		[[SimpleAudioEngine sharedEngine] playEffect:@"Laser.caf"];
	}
}


- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
	// if this touch relivent to our activeWeapon?
	for (UITouch *touch in touches) {
		if ([touch isEqual:self.activeWeapon.touch]) {
			
			// If the touch has moved the weapon past the flick threshold then end the touch so natural movement can start
			CGPoint touchLocation = [touch locationInView:self.view];
			if (touchLocation.y <= RQBattleViewFlickThreshold) {
				[self releaseActiveWeapon];
			} else {
				// If they are still under the threshold update weapon tracking
				// if so, update the sprite
				[self.activeWeapon setPosition:touchLocation atTime:touch.timestamp];
				//CGPoint previousTouchLocation = [touch previousLocationInView:self.view];
//				self.activeWeapon.position = touchLocation;
//				NSTimeInterval deltaTime = touch.timestamp - previousTouchTimestamp;
//				CGFloat deltaX = touchLocation.x - previousTouchLocation.x;
//				CGFloat deltaY = touchLocation.y - previousTouchLocation.y;
//				deltaX /= deltaTime;
//				deltaY /= deltaTime;
//				CGPoint newVelocity = CGPointMake(deltaX, deltaY);
//				self.activeWeapon.velocity = CGPointMake(newVelocity.x, newVelocity.y);
//				previousTouchTimestamp = touch.timestamp;
			}
		}
	}
}


- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
	// if this touch relivent to our activeWeapon?
	for (UITouch *touch in touches) {
		if ([touch isEqual:self.activeWeapon.touch]) {
			[self releaseActiveWeapon];
		}
	}
}

/************************************************************
 * Code below stolen from the built-in OpenGL project template to run the game loop
 ************************************************************/

- (void)setupGameLoop {
	
	
    animating = FALSE;
    displayLinkSupported = FALSE;
    animationFrameInterval = 1;
    displayLink = nil;
    animationTimer = nil;
    
    // Use of CADisplayLink requires iOS version 3.1 or greater.
	// The NSTimer object is used as fallback when it isn't available.
    NSString *reqSysVer = @"3.1";
    NSString *currSysVer = [[UIDevice currentDevice] systemVersion];
    if ([currSysVer compare:reqSysVer options:NSNumericSearch] != NSOrderedAscending)
        displayLinkSupported = TRUE;
}	

- (void)startAnimation {
    previousTickTime = CACurrentMediaTime();
	if (!animating) {
        if (displayLinkSupported) {
            /*
			 CADisplayLink is API new in iOS 3.1. Compiling against earlier versions will result in a warning, but can be dismissed if the system version runtime check for CADisplayLink exists in -awakeFromNib. The runtime check ensures this code will not be called in system versions earlier than 3.1.
			 */
            displayLink = [NSClassFromString(@"CADisplayLink") displayLinkWithTarget:self selector:@selector(tick)];
            [displayLink setFrameInterval:animationFrameInterval];
            
            // The run loop will retain the display link on add.
            [displayLink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
        }
        else
            animationTimer = [NSTimer scheduledTimerWithTimeInterval:(NSTimeInterval)((1.0 / 60.0) * animationFrameInterval) target:self selector:@selector(tick) userInfo:nil repeats:TRUE];
        
        animating = TRUE;
    }
}

- (void)stopAnimation {
    if (animating) {
        if (displayLinkSupported) {
            [displayLink invalidate];
            displayLink = nil;
        } else {
            [animationTimer invalidate];
            animationTimer = nil;
        }
        
        animating = FALSE;
    }
}

- (IBAction)runButtonPressed:(id)sender
{
	// Add logic that penelizes a player from running
	[self returnToMapView];
}
		 
- (void)presentVictoryScreen
{
	[[SimpleAudioEngine sharedEngine] stopBackgroundMusic];
	if (self.battle.hero.currentHP > 0) {
		[[SimpleAudioEngine sharedEngine] playBackgroundMusic:@"victory_song_002.m4a" loop:NO];
	} else {
		[[SimpleAudioEngine sharedEngine] playBackgroundMusic:@"You lose.m4a" loop:NO];
	}
	self.battleVictoryViewController = [[[RQBattleVictoryViewController alloc] init] autorelease];
	[self.battleVictoryViewController setDelegate:self];
	[self.battleVictoryViewController setBattle:self.battle];
	[self.view.window addSubview:self.battleVictoryViewController.view];
    self.battleVictoryViewController.view.frame = self.view.window.bounds;
	self.view.hidden = YES;
}

- (void)dismissVictoryScreen
{
	[self.battleVictoryViewController.view removeFromSuperview];
	[self returnToMapView];
}

- (void)returnToMapView
{
    [self stopAnimation];
	[[SimpleAudioEngine sharedEngine] stopBackgroundMusic];
	[delegate battleViewControllerDidEnd:self];
}

- (void)battleVictoryControllerDidEnd:(RQBattleVictoryViewController *)controller;
{
	[self.battleVictoryViewController.view removeFromSuperview];
	[self setBattleVictoryViewController:nil];
	[[[RQModelController defaultModelController] coreDataManager] save];
	[self returnToMapView];
}

@end
