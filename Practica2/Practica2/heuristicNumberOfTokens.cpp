#include "heuristicNumberOfTokens.hpp"

unsigned getNumberTokens(Player, Board);

/**
 *
 * Heuristic: counts the number of token of the player and opponent on the board
 *
 * @param[in] pl    Player to get the points
 * @param[in] b     Board of the game
 *
 * @retval 1    if the pl have more tokens on the board than opponent of pl
 * @retval -1   if opponent of pl have more tokens on the board than pl
 * @retval 0    if pl and opponent of pl have the same amount of tokens on the board.
 *
 */
float hNumberOfTokens(Player pl,Board b)
{
    float result = 0;

    unsigned pl_points = getNumberTokens(pl, b);
    unsigned oponent_points = getNumberTokens(Opponent(pl), b);
    
    if (pl_points > oponent_points)
    {
        result = 1;
    }
    
    if (pl_points < oponent_points)
    {
        result = -1;
    }
    
    return result;
}


/**
 *
 * This function get the numbers of tokens of a player of a given board
 *
 * @param[in] pl    Player to get the points
 * @param[in] b     Board of the game
 *
 * return points of p1 in the board b
 *
 */
unsigned getNumberTokens(Player pl, Board b)
{
    Token t=Tk(pl);
    
    unsigned points=0;
    
    for (char row = '1'; row <= '8'; row++)
        for (char column ='A'; column < 'I'; column++)
        {
            Square sq = make_pair(row, column);
            if (b.Content(sq) == t)
                points++;
        }
    
    return points;
}
