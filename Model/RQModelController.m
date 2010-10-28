#import <CoreData/CoreData.h>
#import "RQModelController.h"
#import "M3CoreDataManager.h"
#import "M3SimpleCoreData.h"

// models
#import "RQHero.h"
#import "RQEnemy.h"
#import "RQWeightLogEntry.h"

static RQModelController *defaultModelController = nil;

@implementation RQModelController

+ (RQModelController *)defaultModelController {
	if (!defaultModelController) {
		defaultModelController = [[RQModelController alloc] initWithInitialType:NSSQLiteStoreType 
																 appSupportName:@"RunQuest" 
																	  modelName:@"RunQuest.momd/RunQuest.mom"
																  dataStoreName:@"RunQuest.sqlite"];
	}
	return defaultModelController;
}

- (id)initWithInitialType:(NSString *)type appSupportName:(NSString *)supName modelName:(NSString *)mName dataStoreName:(NSString *)storeName
{
	if (self = [super init]) {
		
		NSString *initialType = nil;
		
		if (!type) {
			initialType = NSSQLiteStoreType;
		} else {
			initialType = type;
		}
		coreDataManager = [[M3CoreDataManager alloc] initWithInitialType:initialType 
														  appSupportName:supName 
															   modelName:mName 
														   dataStoreName:storeName];
		simpleCoreData = [[M3SimpleCoreData alloc] init];
		[simpleCoreData setManagedObjectModel:[coreDataManager managedObjectModel]];
		[simpleCoreData setManagedObjectContext:[coreDataManager managedObjectContext]];
		if ([self shouldInsertInitialContents]) {
			[self insertInitialContent];
		}
	}
	return self;
}

- (id)init {
	return [self initWithInitialType:NSInMemoryStoreType 
					  appSupportName:@"RunQuest" 
						   modelName:@"RunQuest.momd/RunQuest.mom" 
					   dataStoreName:@"RunQuest.sqlite"];
}



@synthesize coreDataManager;
@synthesize simpleCoreData;

- (NSUndoManager *)undoManager
{
	return [[[self coreDataManager] managedObjectContext] undoManager];
}

- (RQHero *)hero
{
	NSArray *heros = [simpleCoreData objectsInEntityWithName:@"Hero" predicate:nil sortedWithDescriptors:nil];
	if (heros.count == 1) {
		RQHero *foundHero = [heros lastObject];
		return foundHero;
	} else if (heros.count == 0) {
		// make the hero
		RQHero *hero = (RQHero *)[simpleCoreData newObjectInEntityWithName:@"Hero" values:nil];
		return hero;
	} else {
		NSLog(@"There is more than 1 hero in the db. Uh oh.");
		// TODO: Something smart
	}
	return nil;
}

- (RQEnemy *)randomEnemyBasedOnHero:(RQHero *)hero
{
	// Given the hero generate a random enemy for the hero 
	NSArray *monsterTemplates = [self monsterTemplates];
	NSDictionary *monsterTemplate = [monsterTemplates objectAtIndex:(random() % [monsterTemplates count])];
	
	RQEnemy *newEnemy = (RQEnemy *)[simpleCoreData newObjectInEntityWithName:@"Enemy" values:nil];
	[newEnemy setName:[monsterTemplate objectForKey:@"name"]];
	[newEnemy setTypeAsNumber:[monsterTemplate objectForKey:@"type"]];
	[newEnemy setSpriteImageName:[monsterTemplate objectForKey:@"image"]];
	[newEnemy setLevel:hero.level];
	[newEnemy setCurrentHP:[newEnemy maxHP]];
	[newEnemy setStamina:0];
	[newEnemy setStaminaRegenRate:8.0];
	return newEnemy;
}

- (BOOL)heroExists
{
	NSArray *heros = [simpleCoreData objectsInEntityWithName:@"Hero" predicate:nil sortedWithDescriptors:nil];
	if (heros.count > 0) {
		return YES;
	} else {
		return NO;
	}
}

- (NSArray *)weightLogEntries
{
	return [simpleCoreData objectsInEntityWithName:@"WeightLogEntry" predicate:nil sortedWithDescriptors:nil];
}

- (RQWeightLogEntry *)newWeightLogEntry
{
	[self willChangeValueForKey:@"weightLogEntries"];
	RQWeightLogEntry *entry = (RQWeightLogEntry *)[simpleCoreData newObjectInEntityWithName:@"WeightLogEntry" values:nil];
	[self didChangeValueForKey:@"weightLogEntries"];
	return entry;
}

- (void)deleteWeightLogEntry:(RQWeightLogEntry *)entry
{
	[self willChangeValueForKey:@"weightLogEntries"];
	[[simpleCoreData managedObjectContext] deleteObject:entry];
	[self didChangeValueForKey:@"weightLogEntries"];
}

- (BOOL)shouldInsertInitialContents
{
	return ![self heroExists];
}

- (NSArray *)monsterTemplates
{
	return [NSArray arrayWithObjects:
			[NSDictionary dictionaryWithObjectsAndKeys:@"Globby", @"name", @"boob1.png", @"image", [NSNumber numberWithInteger: RQElementalTypeFire], @"type", [UIColor redColor], @"color", nil],
			[NSDictionary dictionaryWithObjectsAndKeys:@"Super Globby", @"name", @"boob2.png", @"image", [NSNumber numberWithInteger: RQElementalTypeWater], @"type", [UIColor blueColor], @"color", nil],
			[NSDictionary dictionaryWithObjectsAndKeys:@"Ultra Globby", @"name", @"boob3.png", @"image", [NSNumber numberWithInteger: RQElementalTypeEarth], @"type", [UIColor brownColor], @"color", nil],
			[NSDictionary dictionaryWithObjectsAndKeys:@"Master Globby", @"name", @"boob4.png", @"image", [NSNumber numberWithInteger: RQElementalTypeAir], @"type", [UIColor lightGrayColor], @"color", nil],
			
			[NSDictionary dictionaryWithObjectsAndKeys:@"ManTuss", @"name", @"man-tuss.png", @"image", [NSNumber numberWithInteger: RQElementalTypeFire], @"type", [UIColor redColor], @"color", nil],
			[NSDictionary dictionaryWithObjectsAndKeys:@"Super ManTuss", @"name", @"man-tuss_blue.png", @"image", [NSNumber numberWithInteger: RQElementalTypeWater], @"type", [UIColor blueColor], @"color", nil],
			[NSDictionary dictionaryWithObjectsAndKeys:@"Ultra ManTuss", @"name", @"man-tuss_purple.png", @"image", [NSNumber numberWithInteger: RQElementalTypeEarth], @"type", [UIColor brownColor], @"color", nil],
			[NSDictionary dictionaryWithObjectsAndKeys:@"Master ManTuss", @"name", @"man-tuss_red.png", @"image", [NSNumber numberWithInteger: RQElementalTypeAir], @"type", [UIColor lightGrayColor], @"color", nil],
			
			[NSDictionary dictionaryWithObjectsAndKeys:@"Meanie", @"name", @"meanie_1.png", @"image", [NSNumber numberWithInteger: RQElementalTypeFire], @"type",  [UIColor redColor], @"color", nil],
			[NSDictionary dictionaryWithObjectsAndKeys:@"Super Meanie", @"name", @"meanie_2.png", @"image", [NSNumber numberWithInteger: RQElementalTypeWater], @"type", [UIColor blueColor], @"color", nil],
			[NSDictionary dictionaryWithObjectsAndKeys:@"Ultra Meanie", @"name", @"meanie_3.png", @"image", [NSNumber numberWithInteger: RQElementalTypeEarth], @"type", [UIColor brownColor], @"color", nil],
			[NSDictionary dictionaryWithObjectsAndKeys:@"Master Meanie", @"name", @"meanie_4.png", @"image", [NSNumber numberWithInteger: RQElementalTypeAir], @"type", [UIColor lightGrayColor], @"color", nil],
			
			nil];
}

- (void)insertInitialContent
{
	// SAMPLE DATE FOR WEIGHT LOG VIEWS 
	// create two months worth of random weight-in data, assuming they enter in a weight ~3 days and the delta +0.5 -2.5 pounds.
//	int totalDays = 0;
//	float currentWeight = 200.0;
//	while (totalDays <= 60) {
//		
//		int numberOfDays = (random() % 3) + 1; // 1, 2 or 3
//		int entryDate = 60 - totalDays - numberOfDays;
//		
//		NSDate *weightinDate = [NSDate dateWithTimeIntervalSinceNow:60*60*24* -1 * entryDate];
//		currentWeight = currentWeight + ((random() % 4) - 3); // -2 .. +1 
//		
//		RQWeightLogEntry *newEntry = [self newWeightLogEntry];
//		[newEntry setDateTaken:weightinDate];
//		[newEntry setWeightTaken:[NSDecimalNumber decimalNumberWithString:[NSString stringWithFormat:@"%f", currentWeight]]];
//		//NSLog(@"newEntry: %@", newEntry);
//		
//		totalDays = totalDays + numberOfDays;
//	} 
}



@end
