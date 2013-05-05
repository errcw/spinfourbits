/*
 * Common game structures.
 */

/* Number of players in the game. */
#define S4GAME_PLAYERS (2)

/* Number of pieces in a row necessary to win. */
#define S4GAME_INAROW (4)

/* A player identifier. */
typedef enum {
    PlayerOne = 1,
    PlayerTwo = 2,
    PlayerNone = 0
} S4PlayerId;

/* Game Difficulties */
typedef enum {
	S4DifficultyEasy = 0,
	S4DifficultyNormal = 1,
	S4DifficultyHard = 3,
	S4DifficultyChallenge = 5
} S4Difficulty;

/* Returns a zero-based index for the given player. */
#define S4GAME_PLAYER_INDEX(p) ((p) - 1)

/* Returns the opponent of the given player. */
#define S4GAME_OPPOSING_PLAYER(p) (3 - (p))

/* A position on the board. */
typedef struct {
    int row;
    int col;
} S4BoardPosition;

/* A spin. */
typedef enum {
    SpinRight,
    SpinBottom,
    SpinLeft
} S4Spin;

/* A move in the game. */
typedef struct {
    enum {
        MoveDrop,
        MoveSpin
    } type;
    union {
        int column;
        S4Spin spin;
    } move;
} S4Move;
