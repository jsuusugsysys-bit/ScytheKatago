//-------------------------------------------------------------------------------------
// searchscythe.cpp - Scythe (镰刀) functionality for search tree
//
// This file implements the scythe virtual move handling for KataGo's search tree.
// When a player can use scythe, the search tree automatically considers the
// "scythe trigger" as a possible move option, allowing the AI to evaluate
// sequences where the opponent plays 3 consecutive moves.
//-------------------------------------------------------------------------------------

#include "../search/search.h"
#include "../game/boardhistory.h"

using namespace std;

//-------------------------------------------------------------------------------------
// shouldAddScytheOption
//
// Determines whether a scythe trigger option should be added as a virtual child node
// for the specified player. This allows the search to explore paths where the player
// uses their scythe ability to make 3 consecutive moves.
//
// Returns true if:
// - The board is 11x11
// - The move number is between SCYTHE_MIN_MOVE and SCYTHE_MAX_MOVE
// - The player is not currently in a scythe combo
// - The player has scythes remaining
//-------------------------------------------------------------------------------------
bool Search::shouldAddScytheOption(const SearchThread& thread, Player pla) const {
  // Delegate to BoardHistory's canUseScythe method
  return thread.history.canUseScythe(pla);
}

//-------------------------------------------------------------------------------------
// getScythePolicyProb
//
// Returns a DYNAMIC policy probability for the scythe trigger move.
// The probability increases as the game progresses and fewer moves remain in the
// scythe window, making the AI more likely to use/consider scythe in late game.
//
// Formula: scytheProb = scythesLeft / movesLeft
// - scythesLeft: Number of scythes the player has remaining (0-3)
// - movesLeft: Number of moves remaining in the scythe window (scytheMaxMove - currentMove + 1)
//
// This creates urgency: if you have 3 scythes but only 5 moves left, probability = 60%!
// The AI will aggressively explore scythe paths in late game to avoid wasting them.
//-------------------------------------------------------------------------------------
float Search::getScythePolicyProb(const SearchThread& thread, Player pla) const {
  // Only return non-zero if scythe is available
  if(!shouldAddScytheOption(thread, pla))
    return 0.0f;

  // Get current move number
  int currentMoveNum = (int)thread.history.moveHistory.size();

  // Calculate moves remaining in scythe window
  int movesLeft = BoardHistory::scytheMaxMove - currentMoveNum + 1;
  if(movesLeft <= 0)
    return 0.0f;  // Should not happen if shouldAddScytheOption passed

  // Get scythes remaining for this player
  int myScythesLeft = (pla == P_BLACK) ? thread.history.blackScythes : thread.history.whiteScythes;
  if(myScythesLeft <= 0)
    return 0.0f;  // Should not happen if shouldAddScytheOption passed

  // Dynamic probability: scythesLeft / movesLeft
  // More scythes + fewer moves = higher urgency to use scythe
  float dynamicProb = (float)myScythesLeft / (float)movesLeft;

  // Clamp to reasonable range [0.065, 0.65]
  // - Minimum 6.5%: always explore scythe option somewhat (boosted 30% from 0.05)
  // - Maximum 65%: allow scythe to dominate when urgent (boosted 30% from 0.50)
  // NOTE: 2026-01-28 boosted by ~30% to encourage AI to explore scythe paths more aggressively
  float minProb = 0.065f;
  float maxProb = 0.65f;
  dynamicProb = std::max(minProb, std::min(maxProb, dynamicProb));

  return dynamicProb;
}

//-------------------------------------------------------------------------------------
// detectJustFinishedScytheCombo
//
// Detects if the specified player just finished a scythe combo (3 consecutive moves).
// This is determined by checking if the last 3 moves in history were all made by
// the same player (pla).
//
// Returns true if:
// - There are at least 3 moves in history
// - The last 3 moves were all made by player pla
// - The current scytheCombo is 0 (combo just ended)
//-------------------------------------------------------------------------------------
static bool detectJustFinishedScytheCombo(const BoardHistory& history, Player pla) {
  const std::vector<Move>& moves = history.moveHistory;
  size_t numMoves = moves.size();

  // Need at least 3 moves to have completed a combo
  if(numMoves < 3)
    return false;

  // If scytheCombo > 0, combo is still in progress, not finished
  if(history.scytheCombo > 0)
    return false;

  // Check if last 3 moves were all by the same player (pla)
  bool lastThreeSamePlayer = true;
  for(size_t i = 0; i < 3; i++) {
    if(moves[numMoves - 1 - i].pla != pla) {
      lastThreeSamePlayer = false;
      break;
    }
  }

  return lastThreeSamePlayer;
}

//-------------------------------------------------------------------------------------
// getOpponentScytheThreatProb
//
// Returns the probability that the opponent will trigger scythe on their next turn.
// This is used to evaluate defensive positions - the AI should consider paths where
// the opponent uses scythe and prepare accordingly.
//
// Formula: oppThreatProb = oppScythesLeft / movesLeft
//
// RETALIATION BOOST: If we (pla) just finished a scythe combo, the opponent is
// extremely likely to retaliate with their own scythe. This prevents the AI from
// being too greedy - it must consider the opponent's counter-attack.
//-------------------------------------------------------------------------------------
float Search::getOpponentScytheThreatProb(const SearchThread& thread, Player pla) const {
  Player opp = getOpp(pla);

  // Check if opponent can use scythe
  if(!thread.history.canUseScythe(opp))
    return 0.0f;

  // Get current move number
  int currentMoveNum = (int)thread.history.moveHistory.size();

  // Calculate moves remaining in scythe window
  int movesLeft = BoardHistory::scytheMaxMove - currentMoveNum + 1;
  if(movesLeft <= 0)
    return 0.0f;

  // Get opponent's scythes remaining
  int oppScythesLeft = (opp == P_BLACK) ? thread.history.blackScythes : thread.history.whiteScythes;
  if(oppScythesLeft <= 0)
    return 0.0f;

  // Base dynamic threat probability
  float threatProb = (float)oppScythesLeft / (float)movesLeft;

  //-------------------------------------------------------------------------------------
  // RETALIATION BOOST (报复性加成)
  //
  // If we (pla) just finished a scythe combo, the opponent will almost certainly
  // retaliate with their own scythe to "get back in the game".
  //
  // This forces the MCTS to consider: "If I use my scythe, can I survive the
  // opponent's counter-scythe?" This prevents greedy scythe usage that backfires.
  //-------------------------------------------------------------------------------------
  bool justFinishedMyCombo = detectJustFinishedScytheCombo(thread.history, pla);
  if(justFinishedMyCombo) {
    // Force threat probability to at least 90%
    // The opponent WILL retaliate if they can
    threatProb = std::max(threatProb, 0.90f);
  }

  // Clamp to [0, 1]
  threatProb = std::max(0.0f, std::min(1.0f, threatProb));

  return threatProb;
}

//-------------------------------------------------------------------------------------
// applyScytheTrigger
//
// Applies the scythe trigger to the thread's board history. This sets the
// manualScytheTrigger flag, which will cause the next 3 moves to be played
// by the same player (scythe combo).
//-------------------------------------------------------------------------------------
void Search::applyScytheTrigger(SearchThread& thread) const {
  // Set the manual trigger flag
  thread.history.manualScytheTrigger = true;

  // Decrement scythe count for the current player
  if(thread.pla == P_BLACK && thread.history.blackScythes > 0) {
    thread.history.blackScythes--;
  } else if(thread.pla == P_WHITE && thread.history.whiteScythes > 0) {
    thread.history.whiteScythes--;
  }
}

//-------------------------------------------------------------------------------------
// maybeApplyScytheLocalityBias
//
// During scythe combo (when scytheCombo > 0), applies MINIMAL filtering:
//
// 1. Pass is PROHIBITED (returns -1 = illegal) - This is a RULE, not a strategy filter
//
// NO HARD PRUNING of low-policy moves anymore!
// User's key insight: "1 + 1 + 1 > 3" - A "bad" first move might enable a devastating combo.
// Let MCTS naturally explore ALL legal moves. If a move is truly bad, it will get
// few visits naturally via PUCT. If it's a brilliant sacrifice setup, MCTS will discover it.
//
// REMOVED: Policy < 1% threshold (was blocking tactical sacrifices)
// REMOVED: Locality bias (was biasing away from distant tactical moves)
//-------------------------------------------------------------------------------------
void Search::maybeApplyScytheLocalityBias(
  float& nnPolicyProb,
  const Loc moveLoc,
  const SearchThread& thread
) const {
  // Only apply during active scythe combo
  if(thread.history.scytheCombo <= 0)
    return;

  // Skip if policy is already illegal
  if(nnPolicyProb < 0)
    return;

  //-------------------------------------------------------------------------------------
  // RULE: Pass is PROHIBITED during scythe combo
  // This is a GAME RULE, not a strategic filter. In scythe mode, you MUST play a stone.
  //-------------------------------------------------------------------------------------
  if(moveLoc == Board::PASS_LOC) {
    nnPolicyProb = -1.0f;  // Mark as illegal
    return;
  }

  // ALL other legal moves are allowed - let MCTS decide their value through search
  // No policy threshold filtering
  // No locality bias
  // "计算量低一点，但是考虑的穷举多一点" - More breadth, less filtering
}
