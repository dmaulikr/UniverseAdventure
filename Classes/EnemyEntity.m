//
//  EnemyEntity.m
//  ShootEmUp
//
//  Created by Steffen Itterheim on 20.08.10.
//  Copyright 2010 Steffen Itterheim. All rights reserved.
//

#import "EnemyEntity.h"
#import "GameScene.h"
#import "StandardMoveComponent.h"
#import "StandardShootComponent.h"
#import "HealthbarComponent.h"

@interface EnemyEntity (PrivateMethods)
/** 私有方法 */
-(void) initSpawnFrequency;
@end

@implementation EnemyEntity

@synthesize initialHitPoints, hitPoints;

-(id) initWithType:(EnemyTypes)enemyType
{
	type = enemyType;
	
	NSString* enemyFrameName = nil;
	NSString* bulletFrameName;
	float shootFrequency = 6.0f;

    /** 初始化生命值 */
    initialHitPoints = 1;
	switch (type)
	{
		case EnemyTypeUFO:
			enemyFrameName = @"monster-a.png";
			bulletFrameName = @"shot-a.png";
			break;
		case EnemyTypeCruiser:
			enemyFrameName = @"monster-b.png";
			bulletFrameName = @"shot-b.png";
			shootFrequency = 1.0f;
			initialHitPoints = 3;
			break;
		case EnemyTypeBoss:
			enemyFrameName = @"monster-c.png";
			bulletFrameName = @"shot-c.png";
			shootFrequency = 2.0f;
			initialHitPoints = 15;
			break;
			
		default:
			[NSException exceptionWithName:@"EnemyEntity Exception" reason:@"unhandled enemy type" userInfo:nil];
	}

	if ((self = [super initWithSpriteFrameName:enemyFrameName]))
	{
		// Create the game logic components
		[self addChild:[StandardMoveComponent node]];
		
		StandardShootComponent* shootComponent = [StandardShootComponent node];
		shootComponent.shootFrequency = shootFrequency;
		shootComponent.bulletFrameName = bulletFrameName;
		[self addChild:shootComponent];

        /** 给 boss 增加血条 */
        if (type == EnemyTypeBoss)
		{
			HealthbarComponent* healthbar = [HealthbarComponent spriteWithSpriteFrameName:@"healthbar.png"];
			[self addChild:healthbar];
		}

		// enemies start invisible
		self.visible = NO;

		[self initSpawnFrequency];
	}
	
	return self;
}

+(id) enemyWithType:(EnemyTypes)enemyType
{
	return [[[self alloc] initWithType:enemyType] autorelease];
}


/** 全局容器 */
static CCArray* spawnFrequency;

+(int) getSpawnFrequencyForEnemyType:(EnemyTypes)enemyType
{
	NSAssert(enemyType < EnemyType_MAX, @"invalid enemy type");
	NSNumber* number = [spawnFrequency objectAtIndex:enemyType];
	return [number intValue];
}

-(void) initSpawnFrequency
{
	// initialize how frequent the enemies will spawn
	if (spawnFrequency == nil)
	{
		spawnFrequency = [[CCArray alloc] initWithCapacity:EnemyType_MAX];
		[spawnFrequency insertObject:[NSNumber numberWithInt:80] atIndex:EnemyTypeUFO];
		[spawnFrequency insertObject:[NSNumber numberWithInt:260] atIndex:EnemyTypeCruiser];
		[spawnFrequency insertObject:[NSNumber numberWithInt:1500] atIndex:EnemyTypeBoss];
		
		// spawn one enemy immediately
		[self spawn];
	}
}

-(void) spawn
{
	//CCLOG(@"spawn enemy");
	
	// Select a spawn location just outside the right side of the screen, with random y position
	CGRect screenRect = [GameScene screenRect];
	CGSize spriteSize = [self contentSize];
	float xPos = screenRect.size.width + spriteSize.width * 0.5f;
	float yPos = CCRANDOM_0_1() * (screenRect.size.height - spriteSize.height) + spriteSize.height * 0.5f;
	self.position = CGPointMake(xPos, yPos);
	
	// Finally set yourself to be visible, this also flag the enemy as "in use"
	self.visible = YES;
	
	// reset health
    CCLOG(@"initialHitPoints = %d", initialHitPoints);
	hitPoints = initialHitPoints;
	
	// reset certain components
	CCNode* node;
	CCARRAY_FOREACH([self children], node)
	{
		if ([node isKindOfClass:[HealthbarComponent class]])
		{
			HealthbarComponent* healthbar = (HealthbarComponent*)node;
			[healthbar reset];
		}
	}
}

-(void) gotHit
{
	hitPoints--;
	if (hitPoints <= 0)
	{
		self.visible = NO;
	}
}

-(void) dealloc
{
	[spawnFrequency release];
	spawnFrequency = nil;

	[super dealloc];
}

@end
