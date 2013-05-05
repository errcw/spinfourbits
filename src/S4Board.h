/**
 * The (mutable) board state.
 */

#import <Foundation/NSObject.h>
#import <Foundation/NSArray.h>
#import <Foundation/NSValue.h>
#import <Foundation/NSCoder.h>
#import "S4GameStructures.h"

/* The size of the board. */
#define S4BOARD_ROWS (7)
#define S4BOARD_COLS (7)

/* The number of winning lines on the board. */
#define S4BOARD_LINES (88)

@interface S4Board : NSObject {
    /* The game board, in row-major order, where row zero is the bottom. */
    S4PlayerId board[S4BOARD_ROWS][S4BOARD_COLS];

    /* Number of pieces on the board. Used for triggering ties. */
    int pieces;

    /* Whether the game is over. */ 
    BOOL gameOver;

    /* The winner for the current state. Possibly PlayerNone. */
    S4PlayerId winner;

    /* Line counts. Contains 2 ^ (number of pieces in the line) or 0 if the 
     * line is no longer a possible winning capability. */
    int lineStats[S4GAME_PLAYERS][S4BOARD_LINES];

    /* Player scores. A player's score is the weighted sum of her stats array.
     * Used by the AI to evaluate the goodness of a board state. */
    int scores[S4GAME_PLAYERS];
}

/**
 * Returns YES if a player may drop a piece in the specified column.
 */
- (BOOL) canDropPieceInColumn:(int)col;

/**
 * Drops a piece of the specified type into the given column. Returns the row
 * at which the piece stopped falling, or -1 if the move was invalid.
 */
- (int) dropPiece:(S4PlayerId)piece inColumn:(int)col;

/**
 * Spins the board with the new bottom. Returns the board after the spin but
 * before the pieces have fallen.
 */
- (S4Board *) spin:(S4Spin)spinType;

/**
 * Returns the piece at the specified row and column.
 */
- (S4PlayerId) pieceAtRow:(int)row andColumn:(int)col;

/**
 * Sets the piece at the specified row and column.
 */
- (void) setPiece:(S4PlayerId)piece atRow:(int)row andColumn:(int)col;

/**
 * Returns whether the game is over.
 */
- (BOOL) isGameOver;

/**
 * Returns the winner, or PlayerNone if the outcome was a tie. The result
 * returned by this method is valid only when "isGameOver" returns YES.
 */
- (S4PlayerId) winner;

/**
 * Returns the lines containing a full set of pieces. Each element of the
 * returned array is itself an array of NSValues holding S4BoardPosition
 * structs.
 */
- (NSArray *) fullLines;

/**
 * Returns the score of the given player relative to that of her opponent.
 */
- (int) relativeScoreForPlayer:(S4PlayerId)player;

/**
 * Clears all the pieces off the board.
 */
- (void)clear;

/**
 * Creates and returns an identical copy of the board.
 */
- (S4Board *) copy;

@end

@interface S4Board (NSCodingSupport) <NSCoding>

- (id)initWithCoder:(NSCoder *)decoder;
- (void)encodeWithCoder:(NSCoder *)encoder;

@end
