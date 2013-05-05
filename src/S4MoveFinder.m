#import "S4MoveFinder.h"
#import <stdlib.h>

#define S4HUGE (1000000)
#define HUGEST (2000000)
#define MOVES_NUM (S4BOARD_COLS + 3)
#define IS_RAND_THRESHOLD(r) ((r)/(float)RAND_MAX<0.5)

/* Returns the maximum of two integers. */
static int max(int a, int b) { return (a > b) ? a : b; }

/* The current game state. */
typedef struct {
    S4Board *board;
    S4PlayerId player;
} S4GameState;


/* Private methods. */
@interface S4MoveFinder (Private)
- (void) getMove:(S4Move *)move forId:(int)moveId;
- (BOOL) executeMove:(S4Move *)move withState:(S4GameState *)state newState:(S4GameState *)nstate;
- (int) minimaxWithState:(S4GameState *)state atDepth:(int)depth alpha:(int)a beta:(int)b;
- (int) evaluateState:(S4GameState *)state atDepth:(int)depth;
@end


@implementation S4MoveFinder

- (S4MoveFinder *) init {
    S4MoveParameters p = { 4, YES, YES };
    return [self initWithParameters: &p];
}

- (S4MoveFinder *) initWithParameters:(S4MoveParameters *)parameters {
    self = [super init];
    if (self) {
        params = *parameters;
    }
    return self;
}

- (void) getMove:(S4Move *)move forPlayer:(S4PlayerId)player inBoard:(S4Board *)board {
    if (!move) {
        return;
    }

    S4GameState initState = { board, player };

    S4Move curMove;
    S4GameState moveState;

    S4Move bestMove; 
    int bestScore = -HUGEST;
	
    int m;
    for (m = 0; m < MOVES_NUM; m++) {
        [self getMove: &curMove forId: m];
        if ([self executeMove: &curMove withState: &initState newState: &moveState]) {
            int curScore = -[self minimaxWithState: &moveState atDepth: params.maxDepth alpha: -S4HUGE beta: S4HUGE];
			
            if ((curScore > bestScore) ||
                    (curScore == bestScore && params.randomize && IS_RAND_THRESHOLD(rand()))) {
                bestScore = curScore;
                bestMove = curMove;
            }
        }
    }

    *move = bestMove;
}

@end


@implementation S4MoveFinder (Private)

- (void) getMove:(S4Move *)move forId:(int)moveId {
    if (moveId >= 0 && moveId < S4BOARD_COLS) {
        move->type = MoveDrop;
        move->move.column = moveId;
    } else {
        move->type = MoveSpin;
        move->move.spin = (S4Spin)(moveId - S4BOARD_COLS);
    }
}

- (BOOL) executeMove:(S4Move *)move withState:(S4GameState *)state newState:(S4GameState *)nstate {
	
    
	if (move->type == MoveDrop) {
        if ([state->board canDropPieceInColumn: move->move.column] == NO) {
            return NO;
        }
        nstate->board = [[state->board copy] autorelease];
        [nstate->board dropPiece: state->player inColumn: move->move.column];
    } else if (move->type == MoveSpin && params.considerSpins) {
        nstate->board = [[state->board copy] autorelease];
        [nstate->board spin: move->move.spin];
    } else {
        return NO;
    }
    nstate->player = S4GAME_OPPOSING_PLAYER(state->player);
    return YES;
}

- (int) minimaxWithState:(S4GameState *)state atDepth:(int)depth alpha:(int)a beta:(int)b {
	if (depth == 0 || [state->board isGameOver]) {
        return [self evaluateState: state atDepth: depth];
    } else {
        S4Move move;
        S4GameState moveState;
		
        int m;
        for (m = 0; m < MOVES_NUM; m++) {
			
            [self getMove: &move forId: m];
            if ([self executeMove: &move withState: state newState: &moveState]) {
                a = max(a, -[self minimaxWithState: &moveState atDepth: depth - 1 alpha: -b beta: -a]);
                if (a >= b) {
                    break; // beta cut-off
                }
            }
        }
		

        return a;
    }
}

- (int) evaluateState:(S4GameState *)state atDepth:(int)depth {
    if ([state->board isGameOver]) {
        S4PlayerId winner = [state->board winner];
        if (winner == state->player) {
            return S4HUGE + depth; // win, sooner is better
        } else if (winner == S4GAME_OPPOSING_PLAYER(state->player)) {
            return -S4HUGE - depth; // loss, later is better
        } else {
            return 0;
        }
    } else {
        return [state->board relativeScoreForPlayer: state->player];
    }
}

@end
