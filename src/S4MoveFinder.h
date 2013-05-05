/**
 * Finds optimal moves on a board.
 */

#import <Foundation/NSObject.h>
#import "S4GameStructures.h"
#import "S4Board.h"

/* Parameters on moves. */
typedef struct {
    /* Maximum depth in to the game tree to search. */
    int maxDepth;
    /* If spin moves should be considered in the game tree. */
    BOOL considerSpins;
    /* If the move finder should randomize its move choices. */
    BOOL randomize;
} S4MoveParameters;


@interface S4MoveFinder : NSObject {
    /* Our parameters. */
    S4MoveParameters params;
}

/**
 * Creates a move finder with default parameters.
 */
- (S4MoveFinder *) init;

/**
 * Initialises a move finder with the given parameters.
 */
- (S4MoveFinder *) initWithParameters:(S4MoveParameters *)parameters;

/**
 * Finds, given a board state, the optimal move for a given player.
 */
- (void) getMove:(S4Move *)move forPlayer:(S4PlayerId)player inBoard:(S4Board *)board;

@end
