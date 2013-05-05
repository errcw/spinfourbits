#import "S4Board.h"
#import <stdlib.h>

/* Mapping between lines and board positions. */
static NSArray *positionsToLines[S4BOARD_ROWS][S4BOARD_COLS];
static NSArray *linesToPositions[S4BOARD_LINES];

@interface S4Board (Initialization)
+ (void) initialize;
+ (void) mapLine:(int)line toRow:(int)row andColumn:(int)col;
+ (void) mapRow:(int)row andColumn:(int)col toLine:(int)line;
@end


@implementation S4Board

- (S4Board *) init {
    self = [super init];
    if (self) {
        [self clear];
    }
    return self;
}

- (BOOL) canDropPieceInColumn:(int)col {
    if (col < 0 || col >= S4BOARD_COLS) {
        return NO;
    }
    return [self pieceAtRow: S4BOARD_ROWS - 1 andColumn: col] == PlayerNone;
}

- (int) dropPiece:(S4PlayerId)piece inColumn:(int)col {
    if ([self canDropPieceInColumn: col] == NO) {
        return -1;
    }

    // move up the column
    int row = 0;
    for (; row < S4BOARD_ROWS; row++) {
        if (board[row][col] == PlayerNone) {
            break;
        }
    }

    [self setPiece: piece atRow: row andColumn: col];

    return row;
}

- (S4Board *) spin:(S4Spin)spinType {
    int row, col;

    // determine the number of spins
    int spins;
    switch (spinType) {
        case SpinRight: spins = 1; break;
        case SpinBottom: spins = 2; break;
        case SpinLeft: spins = 3; break;
        default: return nil;
    }

    // spin the board
    S4PlayerId boardTemp[S4BOARD_ROWS][S4BOARD_COLS];
    for (; spins > 0; spins--) {
        memset(boardTemp, PlayerNone, S4BOARD_ROWS * S4BOARD_COLS * sizeof(S4PlayerId));
        for (row = 0; row < S4BOARD_ROWS; row++) {
            for (col = 0; col < S4BOARD_COLS; col++) {
                boardTemp[row][col] = board[col][S4BOARD_ROWS - row - 1];
            }
        }
        memcpy(board, boardTemp, S4BOARD_ROWS * S4BOARD_COLS * sizeof(S4PlayerId));
    }

    S4Board *predrop = [[self copy] autorelease];
    [self clear];

    // manage the new gravity
    for (col = 0; col < S4BOARD_COLS; col++) {
        int top = 0;
        for (row = 0; row < S4BOARD_ROWS; row++) {
            S4PlayerId piece = boardTemp[row][col];
            if (piece != PlayerNone) {
                [self setPiece: piece atRow: top andColumn: col];
                top += 1;
            }
        }
    }

    return predrop;
}

- (S4PlayerId) pieceAtRow:(int)row andColumn:(int)col {
    if (row < 0 || row >= S4BOARD_ROWS || col < 0 || col >= S4BOARD_COLS) {
        return PlayerNone;
    }
    return board[row][col];
}

- (void) setPiece:(S4PlayerId)piece atRow:(int)row andColumn:(int)col {
    // update the board
    board[row][col] = piece;
    if (piece == PlayerNone) {
        return;
    }
    pieces += 1;

    // update the line stats
    int pidx = S4GAME_PLAYER_INDEX(piece);
    int oidx = S4GAME_PLAYER_INDEX(S4GAME_OPPOSING_PLAYER(piece));

    int i;
    for (i = 0; i < [positionsToLines[row][col] count]; i++) {
        int line = [[positionsToLines[row][col] objectAtIndex: i] intValue];

        scores[pidx] += lineStats[pidx][line];
        scores[oidx] -= lineStats[oidx][line];

        lineStats[pidx][line] *= 2;
        lineStats[oidx][line] = 0;

        // check if we have completed a line
        if (lineStats[pidx][line] >= (1 << S4GAME_INAROW)) {
            if (gameOver == NO) {
                winner = piece;
            } else if (piece != winner) {
                winner = PlayerNone; // capture the possibility of a tie
            }
            gameOver = YES;
        }
    }

    // check for a tie
    if (pieces == S4BOARD_ROWS * S4BOARD_COLS) {
        gameOver = YES;
    }
}

- (BOOL) isGameOver {
    return gameOver;
}

- (S4PlayerId) winner {
    return winner;
}

- (NSArray *) fullLines {
    NSMutableArray *lines = [NSMutableArray array];

    int line;
    for (line = 0; line < S4BOARD_LINES; line++) {
        if (lineStats[S4GAME_PLAYER_INDEX(PlayerOne)][line] >= (1 << S4GAME_INAROW) ||
            lineStats[S4GAME_PLAYER_INDEX(PlayerTwo)][line] >= (1 << S4GAME_INAROW)) {
            [lines addObject: linesToPositions[line]];
        }
    }

    return lines;
}

- (int) relativeScoreForPlayer:(S4PlayerId)player {
    return scores[S4GAME_PLAYER_INDEX(player)] -
        scores[S4GAME_PLAYER_INDEX(S4GAME_OPPOSING_PLAYER(player))];
}

- (void)clear {
    memset(board, PlayerNone, S4BOARD_ROWS * S4BOARD_COLS * sizeof(S4PlayerId));

    int k;
    for (k = 0; k < S4BOARD_LINES; k++) {
        lineStats[S4GAME_PLAYER_INDEX(PlayerOne)][k] = 1;
        lineStats[S4GAME_PLAYER_INDEX(PlayerTwo)][k] = 1;
    }

    scores[S4GAME_PLAYER_INDEX(PlayerOne)] = S4BOARD_LINES;
    scores[S4GAME_PLAYER_INDEX(PlayerTwo)] = S4BOARD_LINES;

    pieces = 0;
    winner = PlayerNone;
    gameOver = NO;
}

- (S4Board *) copy {
    S4Board *bnew = [[S4Board alloc] init];
    bnew->pieces = pieces;
    bnew->winner = winner;
    bnew->gameOver = gameOver;
    memcpy(bnew->board, board, S4BOARD_ROWS * S4BOARD_COLS * sizeof(S4PlayerId));
    memcpy(bnew->lineStats, lineStats, S4GAME_PLAYERS * S4BOARD_LINES * sizeof(int));
    memcpy(bnew->scores, scores, S4GAME_PLAYERS * sizeof(int));
    return bnew;
}

@end

@implementation S4Board (Initialization)

+ (void) initialize {
    static BOOL initialized = NO;
    if (!initialized) {
        // initialize arrays
        int row, col, k;
        for (row = 0; row < S4BOARD_ROWS; row++) {
            for (col = 0; col < S4BOARD_COLS; col++) {
                positionsToLines[row][col] = [[NSArray array] retain];
            }
        }
        int line;
        for (line = 0; line < S4BOARD_LINES; line++) {
            linesToPositions[line] = [[NSArray array] retain];
        }

        line = 0;

        // horizontal lines
        for (row = 0; row < S4BOARD_ROWS; row++) {
            for (col = 0; col <= S4BOARD_COLS - S4GAME_INAROW; col++) {
                for (k = 0; k < S4GAME_INAROW; k++) {
                    [S4Board mapLine: line toRow: row andColumn: col + k];
                    [S4Board mapRow: row andColumn: col + k toLine: line];
                }
                line += 1;
            }
        }

        // vertical lines
        for (row = 0; row <= S4BOARD_ROWS - S4GAME_INAROW; row++) {
            for (col = 0; col < S4BOARD_COLS; col++) {
                for (k = 0; k < S4GAME_INAROW; k++) {
                    [S4Board mapLine: line toRow: row + k andColumn: col];
                    [S4Board mapRow: row + k andColumn: col toLine: line];
                }
                line += 1;
            }
        }

			// forward diagonal lines (/)
			for (row = 0; row <= S4BOARD_ROWS - S4GAME_INAROW; row++) {
				for (col = 0; col <= S4BOARD_COLS - S4GAME_INAROW; col++) {
					for (k = 0; k < S4GAME_INAROW; k++) {
						[S4Board mapLine: line toRow: row + k andColumn: col + k];
						[S4Board mapRow: row + k andColumn: col + k toLine: line];
					}
					line += 1;
				}
			}
			
			// backward diagonal lines (\)
			for (row = S4BOARD_ROWS - S4GAME_INAROW; row < S4BOARD_ROWS; row++) {
				for (col = 0; col <= S4BOARD_COLS - S4GAME_INAROW; col++) {
					for (k = 0; k < S4GAME_INAROW; k++) {
						[S4Board mapLine: line toRow: row - k andColumn: col + k];
						[S4Board mapRow: row - k andColumn: col + k toLine: line];
					}
					line += 1;
				}
			}

        initialized = YES;
    }
}

+ (void) mapLine:(int)line toRow:(int)row andColumn:(int)col {
    NSArray *prevLines = positionsToLines[row][col];
    NSNumber *lineNum = [NSNumber numberWithInt: line];
    positionsToLines[row][col] = [[prevLines arrayByAddingObject: lineNum] retain];
    [prevLines release];
}

+ (void) mapRow:(int)row andColumn:(int)col toLine:(int)line {
    S4BoardPosition pos = { row, col };
    NSArray *prevPos = linesToPositions[line];
    NSValue *posVal = [NSValue valueWithBytes: &pos objCType: @encode(S4BoardPosition)];
    linesToPositions[line] = [[prevPos arrayByAddingObject: posVal] retain];
    [prevPos release];
}

@end

@implementation S4Board (NSCodingSupport)

- (id)initWithCoder:(NSCoder *)decoder {
	
	self = [super init];
	if (self != nil) {
		NSUInteger bufferLength = 0;
		
		S4PlayerId** tempBoard = (S4PlayerId**)[decoder decodeBytesForKey:@"board" returnedLength:&bufferLength];
		memcpy(board, tempBoard, bufferLength);
			
		pieces = [decoder decodeIntForKey:@"pieces"];
		
		gameOver = [decoder decodeBoolForKey:@"gameOver"];
		
		winner = (S4PlayerId)[decoder decodeBytesForKey:@"winner" returnedLength:&bufferLength];
		
		int** tempLineStats = (int**)[decoder decodeBytesForKey:@"lineStats" returnedLength:&bufferLength];
		memcpy(lineStats, tempLineStats, bufferLength);
		
		int* tempScores = (int*)[decoder decodeBytesForKey:@"scores" returnedLength:&bufferLength];
		memcpy(scores, tempScores, bufferLength);
	}
	return self;	

};

- (void)encodeWithCoder:(NSCoder *)encoder {

	[encoder encodeBytes:(void*)&board length:sizeof(S4PlayerId)*S4BOARD_ROWS*S4BOARD_COLS forKey:@"board"];
	
	[encoder encodeInt:pieces forKey:@"pieces"];	
	
	[encoder encodeBool:gameOver forKey:@"gameOver"];
	
	[encoder encodeBytes:(void*)&winner length:sizeof(S4PlayerId) forKey:@"winner"];
	
	[encoder encodeBytes:(void*)lineStats length:sizeof(int)*S4GAME_PLAYERS*S4BOARD_LINES forKey:@"lineStats"];
	
	[encoder encodeBytes:(void*)scores length:sizeof(int)*S4GAME_PLAYERS forKey:@"scores"];
};

@end