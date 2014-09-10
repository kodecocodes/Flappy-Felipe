//
//  MyScene.h
//  FlappyFelipe
//

//  Copyright (c) 2014 Razeware LLC. All rights reserved.
//

#import <SpriteKit/SpriteKit.h>

typedef NS_ENUM(int, GameState) {
  GameStateMainMenu,
  GameStateTutorial,
  GameStatePlay,
  GameStateFalling,
  GameStateShowingScore,
  GameStateGameOver
};

@protocol MySceneDelegate
- (void)shareString:(NSString *)string;
@end

@interface MyScene : SKScene

-(id)initWithSize:(CGSize)size state:(GameState)state delegate:(id<MySceneDelegate>)delegate;

@property (strong, nonatomic) id<MySceneDelegate> sceneDelegate;

@end
