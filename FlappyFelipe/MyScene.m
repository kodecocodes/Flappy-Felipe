//
//  MyScene.m
//  FlappyFelipe
//
//  Created by Main Account on 2/13/14.
//  Copyright (c) 2014 Razeware LLC. All rights reserved.
//

#import "MyScene.h"

typedef NS_OPTIONS(int, EntityCategory) {
  EntityCategoryPlayer = 1 << 0,
  EntityCategoryObstacle = 1 << 1,
  EntityCategoryGround = 1 << 2
};

typedef NS_ENUM(int, Layer) {
  LayerBackground,
  LayerObstacle,
  LayerForeground,
  LayerPlayer,
  LayerUI,
  LayerFlash
};

// Gameplay - spawn frequency
static const float kGroundSpeed = 150.0f;
static const float kFirstSpawnDelay = 1.75;
static const float kEverySpawnDelay = 1.5;

// Gameplay - bird movement
static const float kGravity = -1500.0;
static const float kImpulse = 400.0;
static const float kAngularVelocity = 1000;

// Gameplay - max tap frequency
static const float kTapDelay = 0.15;

// Gameplay - obstacles positioning
static const float kGapMutliplier = 3.5;
static const float kBottomObstacleMinFraction = 0.1;
static const float kBottomObstacleMaxFraction = 0.6;

// Looks
static const int kNumForegrounds = 2;
static const int kNumBirdFrames = 4;
static const float kMinDegrees = -90;
static const float kMaxDegrees = 25;
static const float kAnimDelay = 0.3;
static const float kMargin = 20;
static NSString *const kFontName = @"AmericanTypewriter-Bold";

// App ID
static const int APP_STORE_ID = 820464950;
static NSString *const iOS7AppStoreURLFormat = @"itms-apps://itunes.apple.com/app/id%d";
static NSString *const iOSAppStoreURLFormat = @"itms-apps://itunes.apple.com/WebObjects/MZStore.woa/wa/viewContentsUserReviews?type=Purple+Software&id=%d";

@interface MyScene() <SKPhysicsContactDelegate>
@end

@implementation MyScene {

  SKNode *_worldNode;

  CGPoint _desiredPosition;
  SKSpriteNode *_player;
  SKSpriteNode *_sombrero;
  
  GameState _gameState;
  
  float _playableStart;
  float _playableHeight;
  
  NSTimeInterval _lastUpdateTime;
  NSTimeInterval _dt;
  
  NSTimeInterval _lastTouchTime;
  float _lastTouchY;
  
  SKAction * _dingAction;
  SKAction * _flapAction;
  SKAction * _whackAction;
  SKAction * _fallingAction;
  SKAction * _hitGroundAction;
  SKAction * _popAction;
  SKAction * _coinAction;
  
  CGPoint _playerVelocity;
  float _playerAngularVelocity;
  
  BOOL _hitGround;
  BOOL _hitObstacle;
  
  SKLabelNode *_scoreLabel;
  SKSpriteNode *_okButton;
  SKSpriteNode *_shareButton;
  
  int _score;
}

-(id)initWithSize:(CGSize)size state:(GameState)state delegate:(id<MySceneDelegate>)delegate {
  if (self = [super initWithSize:size]) {
    
    _sceneDelegate = delegate;
    _gameState = state;
    
    _worldNode = [SKNode node];
    [self addChild:_worldNode];
    
    self.physicsWorld.contactDelegate = self;
    self.physicsWorld.gravity = CGVectorMake(0, 0);
    
    if (_gameState == GameStateMainMenu) {
      [self switchToMainMenu];
    } else if (_gameState == GameStateTutorial) {
      [self switchToTutorial];
    }
    
  }
  return self;
}

#pragma mark - Setup methods

- (void)setupBackground {
  SKSpriteNode *background = [SKSpriteNode spriteNodeWithImageNamed:@"Background"];
  background.anchorPoint = CGPointMake(0.5, 1);
  background.position = CGPointMake(self.size.width/2, self.size.height);
  background.zPosition = LayerBackground;
  [_worldNode addChild:background];
  
  _playableStart = self.size.height - background.size.height;
  _playableHeight = background.size.height;
  
  CGPoint lowerLeft = CGPointMake(0, _playableStart);
  CGPoint lowerRight = CGPointMake(self.size.width, _playableStart);
  //CGRect groundRect = CGRectMake(0, 0, self.size.width, _playableStart);

  self.physicsBody = [SKPhysicsBody bodyWithEdgeFromPoint:lowerLeft toPoint:lowerRight];
  [self skt_attachDebugLineFromPoint:lowerLeft toPoint:lowerRight color:[UIColor redColor]];
  
  self.physicsBody.categoryBitMask = EntityCategoryGround;
  self.physicsBody.collisionBitMask = 0;
  self.physicsBody.contactTestBitMask = EntityCategoryPlayer;

}

- (void)setupForeground {
  for (int i = 0; i < kNumForegrounds; ++i) {
    SKSpriteNode *foreground = [SKSpriteNode spriteNodeWithImageNamed:@"Ground"];
    foreground.anchorPoint = CGPointMake(0, 1);
    foreground.position = CGPointMake(i * self.size.width, _playableStart);
    foreground.name = @"Foreground";
    foreground.zPosition = LayerForeground;
    [_worldNode addChild:foreground];
  }
  
}

- (void)updatePlayerPosition {
  _player.position = CGPointMake((int)_desiredPosition.x, MIN((int)_desiredPosition.y, self.size.height));
}

- (void)setupPlayer {

  _player = [SKSpriteNode spriteNodeWithImageNamed:@"Bird0"];
  _desiredPosition = CGPointMake((int) (self.size.width * 0.2), (int) (_playableHeight * 0.4 + _playableStart));
  [self updatePlayerPosition];
  _player.zPosition = LayerPlayer;
  [_worldNode addChild:_player];
  
  CGFloat offsetX = _player.frame.size.width * _player.anchorPoint.x;
  CGFloat offsetY = _player.frame.size.height * _player.anchorPoint.y;
  CGMutablePathRef path = CGPathCreateMutable();
  CGPathMoveToPoint(path, NULL, 8 - offsetX, 4 - offsetY);
  CGPathAddLineToPoint(path, NULL, 8 - offsetX, 15 - offsetY);
  CGPathAddLineToPoint(path, NULL, 23 - offsetX, 29 - offsetY);
  CGPathAddLineToPoint(path, NULL, 39 - offsetX, 25 - offsetY);
  CGPathAddLineToPoint(path, NULL, 37 - offsetX, 7 - offsetY);
  CGPathAddLineToPoint(path, NULL, 24 - offsetX, 4 - offsetY);
  CGPathCloseSubpath(path);
  _player.physicsBody = [SKPhysicsBody bodyWithPolygonFromPath:path];

  [_player skt_attachDebugFrameFromPath:path color:[SKColor redColor]];

  _player.physicsBody.categoryBitMask = EntityCategoryPlayer;
  _player.physicsBody.collisionBitMask = 0;
  _player.physicsBody.contactTestBitMask = EntityCategoryObstacle | EntityCategoryGround;
  
  SKAction *moveUp = [SKAction moveByX:0 y:10 duration:0.4];
  moveUp.timingMode = SKActionTimingEaseInEaseOut;
  SKAction *moveDown = [moveUp reversedAction];
  SKAction *sequence = [SKAction sequence:@[moveUp, moveDown]];
  SKAction *repeat = [SKAction repeatActionForever:sequence];
  [_player runAction:repeat withKey:@"Wobble"];
  
}

- (void)setupSombrero {

  _sombrero = [SKSpriteNode spriteNodeWithImageNamed:@"Sombrero"];
  _sombrero.position = CGPointMake(31 - _sombrero.size.width/2, 29 - _sombrero.size.height/2);
  [_player addChild:_sombrero];
  

}

//- (void)bugWorkaround{
//  for (int i = 0; i < kNumBirdFrames; i++) {
//    NSString *textureName = [NSString stringWithFormat:@"Bird%d", i];
//    SKSpriteNode *sprite = [SKSpriteNode spriteNodeWithImageNamed:textureName];
//    sprite.zPosition = -1;
//    [self addChild:sprite];
//  }
//}


- (void)setupPlayerAnimation {
  NSMutableArray *textures = [NSMutableArray array];

  //[self bugWorkaround];
  for (int i = 0; i < kNumBirdFrames; i++) {
    NSString *textureName = [NSString stringWithFormat:@"Bird%d", i];
    [textures addObject:[SKTexture textureWithImageNamed:textureName]];
  }
  [SKTexture preloadTextures:textures withCompletionHandler:^{
    for (int i = kNumBirdFrames - 2; i > 0; i--) {
      [textures addObject:textures[i]];
    }
    
    SKAction *playerAnimation = [SKAction animateWithTextures:textures timePerFrame:0.07];
    [_player runAction:[SKAction repeatActionForever:playerAnimation]];
  }];
  
}

- (void)setupTutorial {
  SKSpriteNode *tutorial = [SKSpriteNode spriteNodeWithImageNamed:@"Tutorial"];
  tutorial.position = CGPointMake((int)self.size.width * 0.5, (int)_playableHeight * 0.4 + _playableStart);
  tutorial.name = @"Tutorial";
  tutorial.zPosition = LayerUI;
  [_worldNode addChild:tutorial];
  
  SKSpriteNode *ready = [SKSpriteNode spriteNodeWithImageNamed:@"Ready"];
  ready.position = CGPointMake(self.size.width * 0.5, _playableHeight * 0.7 + _playableStart);
  ready.name = @"Tutorial";
  ready.zPosition = LayerUI;
  [_worldNode addChild:ready];
  
  _scoreLabel = [[SKLabelNode alloc] initWithFontNamed:kFontName];
  _scoreLabel.fontColor = [SKColor colorWithRed:101.0/255 green:71.0/255 blue:73.0/255 alpha:1.0];
  _scoreLabel.position = CGPointMake(self.size.width/2, self.size.height - kMargin);
  _scoreLabel.text = @"0";
  _scoreLabel.verticalAlignmentMode = SKLabelVerticalAlignmentModeTop;
  _scoreLabel.zPosition = LayerUI;
  [_worldNode addChild:_scoreLabel];
  
}

- (void)setupSounds {
  _dingAction = [SKAction playSoundFileNamed:@"ding.wav" waitForCompletion:NO];
  _flapAction = [SKAction playSoundFileNamed:@"flapping.wav" waitForCompletion:NO];
  _whackAction = [SKAction playSoundFileNamed:@"whack.wav" waitForCompletion:NO];
  _fallingAction = [SKAction playSoundFileNamed:@"falling.wav" waitForCompletion:NO];
  _hitGroundAction = [SKAction playSoundFileNamed:@"hitGround.wav" waitForCompletion:NO];
  _popAction = [SKAction playSoundFileNamed:@"pop.wav" waitForCompletion:NO];
  _coinAction = [SKAction playSoundFileNamed:@"coin.wav" waitForCompletion:NO];
}

- (void)setupScorecard {

  if (_score > [self bestScore]) {
    [self setBestScore:_score];
  }

  SKSpriteNode *scorecard = [SKSpriteNode spriteNodeWithImageNamed:@"Scorecard"];
  scorecard.position = CGPointMake(self.size.width * 0.5, -scorecard.size.height/2);
  scorecard.name = @"Tutorial";
  scorecard.zPosition = LayerUI;
  [_worldNode addChild:scorecard];
  
  SKLabelNode *lastScore = [[SKLabelNode alloc] initWithFontNamed:kFontName];
  lastScore.fontColor = [SKColor colorWithRed:101.0/255 green:71.0/255 blue:73.0/255 alpha:1.0];
  lastScore.position = CGPointMake(-scorecard.size.width * 0.25, -scorecard.size.height * 0.2);
  lastScore.text = [NSString stringWithFormat:@"%d", _score];
  [scorecard addChild:lastScore];
  
  SKLabelNode *bestScore = [[SKLabelNode alloc] initWithFontNamed:kFontName];
  bestScore.fontColor = [SKColor colorWithRed:101.0/255 green:71.0/255 blue:73.0/255 alpha:1.0];
  bestScore.position = CGPointMake(scorecard.size.width * 0.25, -scorecard.size.height * 0.2);
  bestScore.text = [NSString stringWithFormat:@"%d", [self bestScore]];
  [scorecard addChild:bestScore];
  
  SKSpriteNode *gameOver = [SKSpriteNode spriteNodeWithImageNamed:@"GameOver"];
  gameOver.position = CGPointMake(self.size.width/2, self.size.height/2 + scorecard.size.height/2 + kMargin + gameOver.size.height/2);
  gameOver.scale = 0;
  gameOver.alpha = 0;
  gameOver.zPosition = LayerUI;
  [_worldNode addChild:gameOver];
  
  SKSpriteNode *okButton = [SKSpriteNode spriteNodeWithImageNamed:@"Button.png"];
  okButton.position = CGPointMake(self.size.width * 0.25, self.size.height/2 - scorecard.size.height/2 - kMargin - okButton.size.height/2);
  okButton.zPosition = LayerUI;
  okButton.alpha = 0;
  [_worldNode addChild:okButton];
  
  SKSpriteNode *ok = [SKSpriteNode spriteNodeWithImageNamed:@"OK"];
  ok.position = CGPointZero;
  ok.zPosition = LayerUI;
  [okButton addChild:ok];
  
  SKSpriteNode *shareButton = [SKSpriteNode spriteNodeWithImageNamed:@"Button.png"];
  shareButton.position = CGPointMake(self.size.width * 0.75, self.size.height/2 - scorecard.size.height/2 - kMargin - shareButton.size.height/2);
  shareButton.alpha = 0;
  shareButton.zPosition = LayerUI;
  [_worldNode addChild:shareButton];
  
  SKSpriteNode *share = [SKSpriteNode spriteNodeWithImageNamed:@"Share"];
  share.position = CGPointZero;
  share.zPosition = LayerUI;
  [shareButton addChild:share];
  
  SKAction *group = [SKAction group:@[
      [SKAction fadeInWithDuration:kAnimDelay],
      [SKAction scaleTo:1.0 duration:kAnimDelay]
    ]];
  group.timingMode = SKActionTimingEaseInEaseOut;
  [gameOver runAction:[SKAction sequence:@[
    [SKAction waitForDuration:kAnimDelay],
    group
    ]]];
  
  SKAction *moveTo = [SKAction moveTo:CGPointMake(self.size.width/2, self.size.height/2) duration:kAnimDelay];
  moveTo.timingMode = SKActionTimingEaseInEaseOut;
  [scorecard runAction:[SKAction sequence:@[
    [SKAction waitForDuration:kAnimDelay*2],
    moveTo
    ]]];
  
  SKAction *fadeIn = [SKAction sequence:@[
    [SKAction waitForDuration:kAnimDelay*3],
    [SKAction fadeInWithDuration:kAnimDelay]
  ]];
  [okButton runAction:fadeIn];
  [shareButton runAction:fadeIn];
  
  SKAction *pops = [SKAction sequence:@[
  [SKAction waitForDuration:kAnimDelay],
    _popAction,
    [SKAction waitForDuration:kAnimDelay],
    _popAction,
    [SKAction waitForDuration:kAnimDelay],
    _popAction,
    [SKAction runBlock:^{
      [self switchToGameOver];
    }]
  ]];
  [self runAction:pops];

}

- (void)setupMainMenu {
  
  SKSpriteNode *logo = [SKSpriteNode spriteNodeWithImageNamed:@"Logo"];
  logo.position = CGPointMake(self.size.width/2, self.size.height * 0.8);
  logo.zPosition = LayerUI;
  [_worldNode addChild:logo];
  
  // Play button
  
  SKSpriteNode *playButton = [SKSpriteNode spriteNodeWithImageNamed:@"Button.png"];
  playButton.position = CGPointMake(self.size.width * 0.25, self.size.height * 0.25);
  playButton.zPosition = LayerUI;
  [_worldNode addChild:playButton];
  
  SKSpriteNode *play = [SKSpriteNode spriteNodeWithImageNamed:@"Play"];
  play.position = CGPointMake(0, 0);
  [playButton addChild:play];
  
  // Rate button
  
  SKSpriteNode *rateButton = [SKSpriteNode spriteNodeWithImageNamed:@"Button.png"];
  rateButton.position = CGPointMake(self.size.width * 0.75, self.size.height * 0.25);
  rateButton.zPosition = LayerUI;
  [_worldNode addChild:rateButton];
  
  SKSpriteNode *rate = [SKSpriteNode spriteNodeWithImageNamed:@"Rate"];
  rate.position = CGPointMake(0, 0);
  [rateButton addChild:rate];
  
  // Learn button
  SKSpriteNode *learn = [SKSpriteNode spriteNodeWithImageNamed:@"button_learn"];
  learn.position = CGPointMake(self.size.width * 0.5, learn.size.height/2 + kMargin);
  learn.zPosition = LayerUI;
  [_worldNode addChild:learn];
  
  SKAction *scaleUp = [SKAction scaleTo:1.02 duration:0.75];
  scaleUp.timingMode = SKActionTimingEaseInEaseOut;
  SKAction *scaleDown = [SKAction scaleTo:0.98 duration:0.75];
  scaleDown.timingMode = SKActionTimingEaseInEaseOut;
  
  [learn runAction:[SKAction repeatActionForever:[SKAction sequence:@[scaleUp, scaleDown]]]];
  
  //[learn removeAllActions]; // DONLY
  
}

#pragma mark - Game State Switching

- (void)switchToMainMenu {

  _gameState = GameStateMainMenu;
  [self setupBackground];
  [self setupForeground];
  [self setupPlayer];
  [self setupPlayerAnimation];
  [self setupSombrero];
  [self setupMainMenu];
  [self setupSounds];
  
  //[_player removeAllActions]; // DONLY
  
}

- (void)switchToPlay {

  // Set state
  _gameState = GameStatePlay;
  
  // Remove tutorial
  [_worldNode enumerateChildNodesWithName:@"Tutorial" usingBlock:^(SKNode *node, BOOL *stop) {
    [node runAction:[SKAction sequence:@[
      [SKAction fadeOutWithDuration:0.5],
      [SKAction removeFromParent]
    ]]];
  }];
  
  // Remove wobble
  [_player removeActionForKey:@"Wobble"];
  
  // Start spawning
  [self startSpawning];
  
  // Move player
  [self flapPlayer];
  
}

- (void)switchToFalling {
  _gameState = GameStateFalling;
  
  SKAction *shake =
    [SKAction skt_screenShakeWithNode:_worldNode amount:CGPointMake(0, 7.0)
    oscillations:10 duration:1.0];
  [_worldNode runAction:shake];
  
  SKSpriteNode *whiteNode = [SKSpriteNode spriteNodeWithColor:[SKColor whiteColor] size:self.size];
  whiteNode.position = CGPointMake(self.size.width*0.5, self.size.height*0.5);
  whiteNode.zPosition = LayerFlash;
  [_worldNode addChild:whiteNode];
  [whiteNode runAction:[SKAction sequence:@[
    [SKAction waitForDuration:0.01],
    [SKAction removeFromParent]
  ]]];
  //[whiteNode runAction:[SKAction fadeOutWithDuration:0.1]];
  
  [self runAction:[SKAction sequence:@[
    _whackAction,
    [SKAction waitForDuration:0.1],
    _fallingAction]]];
  
  [_player removeAllActions];
  [self stopSpawning];
  
}

- (void)switchToShowScore {

  _gameState = GameStateShowingScore;
 
  [_player removeAllActions];
  [self stopSpawning];
 
  [self setupScorecard];
  
}

- (void)switchToGameOver {
  _gameState = GameStateGameOver;
}

- (void)switchToNewGame:(GameState)state {

  [self runAction:_popAction];

  SKScene *newScene = [[MyScene alloc] initWithSize:self.size state:state delegate:self.sceneDelegate];
  SKTransition *transition = [SKTransition fadeWithColor:[SKColor blackColor] duration:0.5];
  [self.view presentScene:newScene transition:transition];
}

- (void)switchToTutorial {

  _gameState = GameStateTutorial;
  [self setupBackground];
  [self setupForeground];
  [self setupPlayer];
  [self setupSombrero];
  [self setupPlayerAnimation];
  [self setupTutorial];
  [self setupSounds];
}

#pragma mark - Gameplay



- (void)startSpawning {

  SKAction *firstDelay = [SKAction waitForDuration:kFirstSpawnDelay];
  SKAction *spawn = [SKAction performSelector:@selector(spawnObstacle) onTarget:self];
  SKAction *everyDelay = [SKAction waitForDuration:kEverySpawnDelay];
  SKAction *spawnSequence = [SKAction sequence:@[spawn, everyDelay]];
  SKAction *foreverSpawn = [SKAction repeatActionForever:spawnSequence];
  SKAction *overallSequence = [SKAction sequence:@[firstDelay, foreverSpawn]];
  [self runAction:overallSequence withKey:@"Spawn"];

}

- (void)stopSpawning {
  [self removeActionForKey:@"Spawn"];
  [_worldNode enumerateChildNodesWithName:@"TopObstacle" usingBlock:^(SKNode *node, BOOL *stop) {
    [node removeAllActions];
  }];
  [_worldNode enumerateChildNodesWithName:@"BottomObstacle" usingBlock:^(SKNode *node, BOOL *stop) {
      [node removeAllActions];
    }];
}

- (SKSpriteNode *)createObstacle {
  
  SKSpriteNode *sprite = [SKSpriteNode spriteNodeWithImageNamed:@"Cactus"];
  sprite.userData = [NSMutableDictionary dictionary];
  sprite.zPosition = LayerObstacle;
  
  CGFloat offsetX = sprite.frame.size.width * sprite.anchorPoint.x;
  CGFloat offsetY = sprite.frame.size.height * sprite.anchorPoint.y;

  CGMutablePathRef path = CGPathCreateMutable();

  CGPathMoveToPoint(path, NULL, 16 - offsetX, 315 - offsetY);
  CGPathAddLineToPoint(path, NULL, 40 - offsetX, 314 - offsetY);
  CGPathAddLineToPoint(path, NULL, 51 - offsetX, 307 - offsetY);
  CGPathAddLineToPoint(path, NULL, 48 - offsetX, 0 - offsetY);
  CGPathAddLineToPoint(path, NULL, 3 - offsetX, 1 - offsetY);
  CGPathAddLineToPoint(path, NULL, 4 - offsetX, 128 - offsetY);
  CGPathAddLineToPoint(path, NULL, 3 - offsetX, 247 - offsetY);
  CGPathAddLineToPoint(path, NULL, 4 - offsetX, 308 - offsetY);

  CGPathCloseSubpath(path);

  sprite.physicsBody = [SKPhysicsBody bodyWithPolygonFromPath:path];
  
  [sprite skt_attachDebugFrameFromPath:path color:[SKColor redColor]];

  sprite.physicsBody.categoryBitMask = EntityCategoryObstacle;
  sprite.physicsBody.collisionBitMask = 0;
  sprite.physicsBody.contactTestBitMask = EntityCategoryPlayer;
  
  return sprite;
}

- (void)spawnObstacle {
 
  SKSpriteNode *bottomObstacle = [self createObstacle];
  bottomObstacle.name = @"BottomObstacle";
  float bottomObstacleMin = (_playableStart - bottomObstacle.size.height/2) + _playableHeight * kBottomObstacleMinFraction;
  float bottomObstacleMax = (_playableStart - bottomObstacle.size.height/2) + _playableHeight * kBottomObstacleMaxFraction;
  bottomObstacle.position = CGPointMake(self.size.width + bottomObstacle.size.width/2, RandomFloatRange(bottomObstacleMin, bottomObstacleMax));
  [_worldNode addChild:bottomObstacle];
  
  SKSpriteNode *topObstacle = [self createObstacle];
  topObstacle.name = @"TopObstacle";
  topObstacle.zRotation = DegreesToRadians(180);
  topObstacle.position = CGPointMake(self.size.width + topObstacle.size.width/2, bottomObstacle.position.y + bottomObstacle.size.height/2 + topObstacle.size.height/2 + _player.size.height * kGapMutliplier);
  [_worldNode addChild:topObstacle];
  
  float moveX = self.size.width + topObstacle.size.width;
  float moveDuration = moveX / kGroundSpeed;
  SKAction *sequence = [SKAction sequence:@[
    [SKAction moveByX:-moveX y:0 duration:moveDuration],
    [SKAction removeFromParent]
  ]];
  
  [topObstacle runAction:sequence];
  [bottomObstacle runAction:sequence];

}

- (void)flapPlayer {

  if (_lastUpdateTime - _lastTouchTime < kTapDelay) return;

  // Play sound
  [self runAction:_flapAction];

  // Apply impulse
  _playerVelocity = CGPointMake(0, kImpulse);
  _playerAngularVelocity = DegreesToRadians(kAngularVelocity);
  
  // Set last touch time and y
  _lastTouchTime = _lastUpdateTime;
  _lastTouchY = _player.position.y;
  
  // Move sombrero
  SKAction *moveUp = [SKAction moveByX:0 y:12 duration:0.15];
  moveUp.timingMode = SKActionTimingEaseInEaseOut;
  SKAction *moveDown = [moveUp reversedAction];
  [_sombrero runAction:[SKAction sequence:@[moveUp, moveDown]]];
  
}

-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {

  UITouch *touch = [touches anyObject];
  CGPoint touchLocation = [touch locationInNode:self];
  
  switch (_gameState) {
  case GameStateMainMenu:
    if (touchLocation.y < self.size.height * 0.15) {
      [self learn];
    } else if (touchLocation.x < self.size.width * 0.6) {
      [self switchToNewGame:GameStateTutorial];
    } else {
      [self rateApp];
    }
    break;
  case GameStateTutorial:
    [self switchToPlay];
    break;
  case GameStatePlay:
    [self flapPlayer];
    break;
  case GameStateFalling:
    break;
  case GameStateShowingScore:
    break;
  case GameStateGameOver:
    if (touchLocation.x < self.size.width * 0.6) {
      [self switchToNewGame:GameStateMainMenu];
    } else {
      [self shareScore];
    }
    break;
  }
  
}

#pragma mark - Updates

- (void)checkHitGround {
  if (_hitGround) {
    _hitGround = NO;
    _playerVelocity = CGPointZero;
    _player.zRotation = DegreesToRadians(kMinDegrees);
    _desiredPosition = CGPointMake(_player.position.x, _playableStart + _player.size.width/2);
    [self updatePlayerPosition];
    [self runAction:_hitGroundAction];
    [self switchToShowScore];
  }
}

- (void)checkHitObstacle {
  if (_hitObstacle) {
    _hitObstacle = NO;
    [self switchToFalling];
  }
}

- (void)updateForeground {
  
  [_worldNode enumerateChildNodesWithName:@"Foreground" usingBlock:^(SKNode *node, BOOL *stop) {
    SKSpriteNode *foreground = (SKSpriteNode *)node;
    CGPoint moveAmt = CGPointMake(-kGroundSpeed * _dt, 0);
    foreground.position = CGPointAdd(foreground.position, moveAmt);
    
    if (foreground.position.x < -foreground.size.width) {
      foreground.position = CGPointAdd(foreground.position, CGPointMake(foreground.size.width * kNumForegrounds, 0));
    }
  }];
  
}

- (void)updatePlayer {
  
  // Apply gravity
  CGPoint gravity = CGPointMake(0, kGravity);
  CGPoint gravityStep = CGPointMultiplyScalar(gravity, _dt);
  _playerVelocity = CGPointAdd(_playerVelocity, gravityStep);

  // Apply velocity
  CGPoint velocityStep = CGPointMultiplyScalar(_playerVelocity, _dt);
  _desiredPosition = CGPointAdd(_player.position, velocityStep);
  [self updatePlayerPosition];
  
  // Check if it's time to rate down
  if (_player.position.y < _lastTouchY) {
    _playerAngularVelocity = -DegreesToRadians(kAngularVelocity);
  }
  
  // Rotate player
  float angularStep = _playerAngularVelocity * _dt;
  _player.zRotation += angularStep;
  _player.zRotation = MIN(MAX(_player.zRotation, DegreesToRadians(kMinDegrees)), DegreesToRadians(kMaxDegrees));
  
}

-(void)updateScore {

  [_worldNode enumerateChildNodesWithName:@"BottomObstacle" usingBlock:^(SKNode *node, BOOL *stop) {
      SKSpriteNode *obstacle = (SKSpriteNode *)node;
    
      NSNumber *passed = obstacle.userData[@"Passed"];
      if (passed && passed.boolValue) return;
    
      if (_player.position.x > obstacle.position.x + obstacle.size.width/2) {
        _score++;
        _scoreLabel.text = [NSString stringWithFormat:@"%d", _score];
        [self runAction:_coinAction];
        obstacle.userData[@"Passed"] = @YES;
      }
    
  }];

}

-(void)update:(CFTimeInterval)currentTime {
  //return; // DONLY
  if (_lastUpdateTime) {
    _dt = currentTime - _lastUpdateTime;
  } else {
    _dt = 0;
  }
  _lastUpdateTime = currentTime;
  
  switch (_gameState) {
  case GameStateMainMenu:
    [self updateForeground];
    break;
  case GameStateTutorial:
    break;
  case GameStatePlay:
    [self checkHitGround];
    [self checkHitObstacle];
    [self updateForeground];
    [self updatePlayer];
    [self updateScore];
    break;
  case GameStateFalling:
    [self checkHitGround];
    [self updatePlayer];
    break;
  case GameStateShowingScore:
    break;
  case GameStateGameOver:
    break;
  }
  
}

#pragma mark - Special

- (void)rateApp {
  
  NSString *rateString;
  if ([[UIDevice currentDevice].systemVersion floatValue] >= 7.0f) {
    rateString = [NSString stringWithFormat:iOS7AppStoreURLFormat, APP_STORE_ID];
  } else {
    rateString = [NSString stringWithFormat:iOSAppStoreURLFormat, APP_STORE_ID];
  }

  [[UIApplication sharedApplication] openURL:[NSURL URLWithString:rateString]];
  
}

- (void)shareScore {

  NSString *initialTextString = [NSString stringWithFormat:@"OMG! I scored %d points in Flappy Felipe! -> http://itunes.apple.com/app/id%d", _score, APP_STORE_ID];
  [self.sceneDelegate shareString:initialTextString];
}

- (void)learn {
  
  [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"http://www.raywenderlich.com/flappy-felipe"]];

}

#pragma mark - Score

- (int)bestScore {
  return [[NSUserDefaults standardUserDefaults] integerForKey:@"BestScore"];
}

- (void)setBestScore:(int)bestScore {
  [[NSUserDefaults standardUserDefaults] setInteger:bestScore forKey:@"BestScore"];
  [[NSUserDefaults standardUserDefaults] synchronize];
}

#pragma mark - Collision Detection

- (void)didBeginContact:(SKPhysicsContact *)contact {
  SKPhysicsBody *other = (contact.bodyA.categoryBitMask == EntityCategoryPlayer ? contact.bodyB : contact.bodyA);
  if (other.categoryBitMask == EntityCategoryGround) {
    _hitGround = YES;
    return;
  }
  if (other.categoryBitMask == EntityCategoryObstacle) {
    _hitObstacle = YES;
    return;
  }
}

@end
