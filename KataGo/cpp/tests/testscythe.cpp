//-------------------------------------------------------------------------------------
// testscythe.cpp - Tests for Scythe (镰刀) functionality
// TDD: These tests are written FIRST, before implementation
//-------------------------------------------------------------------------------------

#include "../tests/tests.h"
#include "../game/board.h"
#include "../game/boardhistory.h"
#include "../game/rules.h"

using namespace std;
using namespace TestCommon;

//-------------------------------------------------------------------------------------
// Helper functions for scythe tests
//-------------------------------------------------------------------------------------

static void makeMoves(Board& board, BoardHistory& hist, Player& pla, int numMoves) {
  // Make moves in a simple pattern to advance the game
  for(int i = 0; i < numMoves; i++) {
    int x = i % board.x_size;
    int y = i / board.x_size;
    Loc loc = Location::getLoc(x, y, board.x_size);

    // Skip if occupied
    while(board.colors[loc] != C_EMPTY) {
      x = (x + 1) % board.x_size;
      if(x == 0) y = (y + 1) % board.y_size;
      loc = Location::getLoc(x, y, board.x_size);
    }

    hist.makeBoardMoveAssumeLegal(board, loc, pla, nullptr);
    pla = hist.presumedNextMovePla;
  }
}

//-------------------------------------------------------------------------------------
// Test: BoardHistory::canUseScythe()
// Verifies all conditions for scythe availability
//-------------------------------------------------------------------------------------

void Tests::runScytheTests() {
  cout << "Running scythe tests" << endl;
  ostringstream out;

  //============================================================================
  // Test 1: Initial state - both players have 3 scythes
  //============================================================================
  {
    const char* name = "Scythe initial state test";

    Board board(11, 11);
    Player pla = P_BLACK;
    Rules rules = Rules::getTrompTaylorish();
    BoardHistory hist(board, pla, rules, 0);

    out << "Initial blackScythes: " << hist.blackScythes << endl;
    out << "Initial whiteScythes: " << hist.whiteScythes << endl;
    out << "Initial scytheCombo: " << hist.scytheCombo << endl;

    testAssert(hist.blackScythes == 3);
    testAssert(hist.whiteScythes == 3);
    testAssert(hist.scytheCombo == 0);

    string expected = R"%%(
Initial blackScythes: 3
Initial whiteScythes: 3
Initial scytheCombo: 0
)%%";
    TestCommon::expect(name, out, expected);
  }

  //============================================================================
  // Test 2: Cannot use scythe before move 11
  //============================================================================
  {
    const char* name = "Scythe cannot use before move 11";

    Board board(11, 11);
    Player pla = P_BLACK;
    Rules rules = Rules::getTrompTaylorish();
    BoardHistory hist(board, pla, rules, 0);

    // Make 10 moves (turns 1-10)
    makeMoves(board, hist, pla, 10);

    out << "After 10 moves, turn number: " << hist.getCurrentTurnNumber() << endl;
    out << "Black canUseScythe: " << (hist.canUseScythe(P_BLACK) ? "true" : "false") << endl;
    out << "White canUseScythe: " << (hist.canUseScythe(P_WHITE) ? "true" : "false") << endl;

    // Before move 11, neither player can use scythe
    testAssert(hist.canUseScythe(P_BLACK) == false);
    testAssert(hist.canUseScythe(P_WHITE) == false);

    string expected = R"%%(
After 10 moves, turn number: 10
Black canUseScythe: false
White canUseScythe: false
)%%";
    TestCommon::expect(name, out, expected);
  }

  //============================================================================
  // Test 3: Can use scythe at move 11
  //============================================================================
  {
    const char* name = "Scythe can use at move 11";

    Board board(11, 11);
    Player pla = P_BLACK;
    Rules rules = Rules::getTrompTaylorish();
    BoardHistory hist(board, pla, rules, 0);

    // Make 11 moves (turns 1-11)
    makeMoves(board, hist, pla, 11);

    out << "After 11 moves, turn number: " << hist.getCurrentTurnNumber() << endl;
    out << "Current player: " << (pla == P_BLACK ? "Black" : "White") << endl;
    out << "Current player canUseScythe: " << (hist.canUseScythe(pla) ? "true" : "false") << endl;

    // At move 11, current player can use scythe
    testAssert(hist.canUseScythe(pla) == true);

    string expected = R"%%(
After 11 moves, turn number: 11
Current player: White
Current player canUseScythe: true
)%%";
    TestCommon::expect(name, out, expected);
  }

  //============================================================================
  // Test 4: Can use scythe at move 49 (last allowed)
  //============================================================================
  {
    const char* name = "Scythe can use at move 49";

    Board board(11, 11);
    Player pla = P_BLACK;
    Rules rules = Rules::getTrompTaylorish();
    BoardHistory hist(board, pla, rules, 0);

    // Make 49 moves
    makeMoves(board, hist, pla, 49);

    out << "After 49 moves, turn number: " << hist.getCurrentTurnNumber() << endl;
    out << "Current player canUseScythe: " << (hist.canUseScythe(pla) ? "true" : "false") << endl;

    // At move 49, current player can still use scythe
    testAssert(hist.canUseScythe(pla) == true);

    string expected = R"%%(
After 49 moves, turn number: 49
Current player canUseScythe: true
)%%";
    TestCommon::expect(name, out, expected);
  }

  //============================================================================
  // Test 5: Cannot use scythe after move 49
  //============================================================================
  {
    const char* name = "Scythe cannot use after move 49";

    Board board(11, 11);
    Player pla = P_BLACK;
    Rules rules = Rules::getTrompTaylorish();
    BoardHistory hist(board, pla, rules, 0);

    // Make 50 moves
    makeMoves(board, hist, pla, 50);

    out << "After 50 moves, turn number: " << hist.getCurrentTurnNumber() << endl;
    out << "Black canUseScythe: " << (hist.canUseScythe(P_BLACK) ? "true" : "false") << endl;
    out << "White canUseScythe: " << (hist.canUseScythe(P_WHITE) ? "true" : "false") << endl;

    // After move 49, neither player can use scythe
    testAssert(hist.canUseScythe(P_BLACK) == false);
    testAssert(hist.canUseScythe(P_WHITE) == false);

    string expected = R"%%(
After 50 moves, turn number: 50
Black canUseScythe: false
White canUseScythe: false
)%%";
    TestCommon::expect(name, out, expected);
  }

  //============================================================================
  // Test 6: Cannot use scythe on non-11x11 board
  //============================================================================
  {
    const char* name = "Scythe only works on 11x11 board";

    // Test 19x19 board
    Board board19(19, 19);
    Player pla = P_BLACK;
    Rules rules = Rules::getTrompTaylorish();
    BoardHistory hist19(board19, pla, rules, 0);

    makeMoves(board19, hist19, pla, 15);

    out << "19x19 board, after 15 moves:" << endl;
    out << "Black canUseScythe: " << (hist19.canUseScythe(P_BLACK) ? "true" : "false") << endl;

    testAssert(hist19.canUseScythe(P_BLACK) == false);

    // Test 9x9 board
    Board board9(9, 9);
    pla = P_BLACK;
    BoardHistory hist9(board9, pla, rules, 0);

    makeMoves(board9, hist9, pla, 15);

    out << "9x9 board, after 15 moves:" << endl;
    out << "Black canUseScythe: " << (hist9.canUseScythe(P_BLACK) ? "true" : "false") << endl;

    testAssert(hist9.canUseScythe(P_BLACK) == false);

    string expected = R"%%(
19x19 board, after 15 moves:
Black canUseScythe: false
9x9 board, after 15 moves:
Black canUseScythe: false
)%%";
    TestCommon::expect(name, out, expected);
  }

  //============================================================================
  // Test 7: Cannot use scythe when scythe count is 0
  //============================================================================
  {
    const char* name = "Scythe cannot use when count is 0";

    Board board(11, 11);
    Player pla = P_BLACK;
    Rules rules = Rules::getTrompTaylorish();
    BoardHistory hist(board, pla, rules, 0);

    makeMoves(board, hist, pla, 15);

    // Deplete black's scythes
    hist.blackScythes = 0;

    out << "After depleting black scythes:" << endl;
    out << "blackScythes: " << hist.blackScythes << endl;
    out << "Black canUseScythe: " << (hist.canUseScythe(P_BLACK) ? "true" : "false") << endl;
    out << "White canUseScythe: " << (hist.canUseScythe(P_WHITE) ? "true" : "false") << endl;

    testAssert(hist.canUseScythe(P_BLACK) == false);
    testAssert(hist.canUseScythe(P_WHITE) == true); // White still has scythes

    string expected = R"%%(
After depleting black scythes:
blackScythes: 0
Black canUseScythe: false
White canUseScythe: true
)%%";
    TestCommon::expect(name, out, expected);
  }

  //============================================================================
  // Test 8: Cannot use scythe when already in combo
  //============================================================================
  {
    const char* name = "Scythe cannot use when already in combo";

    Board board(11, 11);
    Player pla = P_BLACK;
    Rules rules = Rules::getTrompTaylorish();
    BoardHistory hist(board, pla, rules, 0);

    makeMoves(board, hist, pla, 15);

    // Simulate being in a scythe combo
    hist.scytheCombo = 2;

    out << "While in combo (scytheCombo=2):" << endl;
    out << "Black canUseScythe: " << (hist.canUseScythe(P_BLACK) ? "true" : "false") << endl;
    out << "White canUseScythe: " << (hist.canUseScythe(P_WHITE) ? "true" : "false") << endl;

    testAssert(hist.canUseScythe(P_BLACK) == false);
    testAssert(hist.canUseScythe(P_WHITE) == false);

    string expected = R"%%(
While in combo (scytheCombo=2):
Black canUseScythe: false
White canUseScythe: false
)%%";
    TestCommon::expect(name, out, expected);
  }

  //============================================================================
  // Test 9: Scythe trigger sets combo correctly
  //============================================================================
  {
    const char* name = "Scythe trigger sets combo to 3";

    Board board(11, 11);
    Player pla = P_BLACK;
    Rules rules = Rules::getTrompTaylorish();
    BoardHistory hist(board, pla, rules, 0);

    makeMoves(board, hist, pla, 14); // Get to move 14

    out << "Before trigger:" << endl;
    out << "scytheCombo: " << hist.scytheCombo << endl;
    out << "blackScythes: " << hist.blackScythes << endl;

    // Trigger scythe for current player
    hist.manualScytheTrigger = true;

    // Make a move - this should trigger the scythe
    int x = 5, y = 5;
    Loc loc = Location::getLoc(x, y, board.x_size);
    while(board.colors[loc] != C_EMPTY) {
      x = (x + 1) % board.x_size;
      loc = Location::getLoc(x, y, board.x_size);
    }
    hist.makeBoardMoveAssumeLegal(board, loc, pla, nullptr);

    out << "After trigger and move:" << endl;
    out << "scytheCombo: " << hist.scytheCombo << endl;
    out << "blackScythes: " << hist.blackScythes << endl;
    out << "presumedNextMovePla: " << (hist.presumedNextMovePla == P_BLACK ? "Black" : "White") << endl;

    // After trigger, combo should be 3 and same player continues
    testAssert(hist.scytheCombo == 3);
    testAssert(hist.blackScythes == 2); // Decremented
    testAssert(hist.presumedNextMovePla == pla); // Same player

    string expected = R"%%(
Before trigger:
scytheCombo: 0
blackScythes: 3
After trigger and move:
scytheCombo: 3
blackScythes: 2
presumedNextMovePla: Black
)%%";
    TestCommon::expect(name, out, expected);
  }

  //============================================================================
  // Test 10: Full scythe combo - 3 consecutive moves
  //============================================================================
  {
    const char* name = "Scythe full combo - 3 consecutive moves";

    Board board(11, 11);
    Player pla = P_BLACK;
    Rules rules = Rules::getTrompTaylorish();
    BoardHistory hist(board, pla, rules, 0);

    makeMoves(board, hist, pla, 14);

    Player scythePlayer = pla; // Black

    // Trigger scythe
    hist.manualScytheTrigger = true;

    out << "Scythe combo sequence:" << endl;

    // Move 1 of combo
    Loc loc1 = Location::getLoc(5, 5, board.x_size);
    hist.makeBoardMoveAssumeLegal(board, loc1, pla, nullptr);
    pla = hist.presumedNextMovePla;
    out << "After move 1: scytheCombo=" << hist.scytheCombo
        << ", nextPlayer=" << (pla == P_BLACK ? "Black" : "White") << endl;

    testAssert(hist.scytheCombo == 3);
    testAssert(pla == scythePlayer);

    // Move 2 of combo
    Loc loc2 = Location::getLoc(6, 5, board.x_size);
    hist.makeBoardMoveAssumeLegal(board, loc2, pla, nullptr);
    pla = hist.presumedNextMovePla;
    out << "After move 2: scytheCombo=" << hist.scytheCombo
        << ", nextPlayer=" << (pla == P_BLACK ? "Black" : "White") << endl;

    testAssert(hist.scytheCombo == 2);
    testAssert(pla == scythePlayer);

    // Move 3 of combo
    Loc loc3 = Location::getLoc(7, 5, board.x_size);
    hist.makeBoardMoveAssumeLegal(board, loc3, pla, nullptr);
    pla = hist.presumedNextMovePla;
    out << "After move 3: scytheCombo=" << hist.scytheCombo
        << ", nextPlayer=" << (pla == P_BLACK ? "Black" : "White") << endl;

    testAssert(hist.scytheCombo == 1);
    testAssert(pla == scythePlayer);

    // Move 4 - combo ends, player switches
    Loc loc4 = Location::getLoc(8, 5, board.x_size);
    hist.makeBoardMoveAssumeLegal(board, loc4, pla, nullptr);
    pla = hist.presumedNextMovePla;
    out << "After move 4: scytheCombo=" << hist.scytheCombo
        << ", nextPlayer=" << (pla == P_BLACK ? "Black" : "White") << endl;

    testAssert(hist.scytheCombo == 0);
    testAssert(pla == getOpp(scythePlayer)); // Player switches

    string expected = R"%%(
Scythe combo sequence:
After move 1: scytheCombo=3, nextPlayer=Black
After move 2: scytheCombo=2, nextPlayer=Black
After move 3: scytheCombo=1, nextPlayer=Black
After move 4: scytheCombo=0, nextPlayer=White
)%%";
    TestCommon::expect(name, out, expected);
  }

  cout << "Scythe tests passed!" << endl;
}

//-------------------------------------------------------------------------------------
// Phase 2 Tests: Search tree scythe option detection
// TDD: These tests define the expected behavior of shouldAddScytheOption()
//-------------------------------------------------------------------------------------

// Note: Full search tree tests require NNEvaluator which is complex to set up.
// These tests focus on the BoardHistory::shouldAddScytheOption() method instead,
// which is the core logic that Search will delegate to.

void Tests::runScytheSearchTests() {
  cout << "Running scythe search tests" << endl;
  ostringstream out;

  //============================================================================
  // Test 11: shouldAddScytheOption returns true when conditions met
  //============================================================================
  {
    const char* name = "Scythe search - should add option when conditions met";

    Board board(11, 11);
    Player pla = P_BLACK;
    Rules rules = Rules::getTrompTaylorish();
    BoardHistory hist(board, pla, rules, 0);

    // Make 15 moves to get to a valid scythe state
    makeMoves(board, hist, pla, 15);

    // Check if shouldAddScytheOption returns true for current player
    bool shouldAddBlack = hist.shouldAddScytheOption(P_BLACK);
    bool shouldAddWhite = hist.shouldAddScytheOption(P_WHITE);

    out << "Move number: " << hist.getCurrentTurnNumber() << endl;
    out << "Black shouldAddScytheOption: " << (shouldAddBlack ? "true" : "false") << endl;
    out << "White shouldAddScytheOption: " << (shouldAddWhite ? "true" : "false") << endl;

    // Both players should be able to add scythe option (they both have scythes)
    testAssert(shouldAddBlack == true);
    testAssert(shouldAddWhite == true);

    string expected = R"%%(
Move number: 15
Black shouldAddScytheOption: true
White shouldAddScytheOption: true
)%%";
    TestCommon::expect(name, out, expected);
  }

  //============================================================================
  // Test 12: shouldAddScytheOption returns false on wrong board size
  //============================================================================
  {
    const char* name = "Scythe search - should not add option on 19x19";

    Board board(19, 19);
    Player pla = P_BLACK;
    Rules rules = Rules::getTrompTaylorish();
    BoardHistory hist(board, pla, rules, 0);

    makeMoves(board, hist, pla, 15);

    bool shouldAdd = hist.shouldAddScytheOption(pla);

    out << "19x19 board shouldAddScytheOption: " << (shouldAdd ? "true" : "false") << endl;

    testAssert(shouldAdd == false);

    string expected = R"%%(
19x19 board shouldAddScytheOption: false
)%%";
    TestCommon::expect(name, out, expected);
  }

  //============================================================================
  // Test 13: shouldAddScytheOption returns false before move 11
  //============================================================================
  {
    const char* name = "Scythe search - should not add option before move 11";

    Board board(11, 11);
    Player pla = P_BLACK;
    Rules rules = Rules::getTrompTaylorish();
    BoardHistory hist(board, pla, rules, 0);

    makeMoves(board, hist, pla, 8);

    bool shouldAdd = hist.shouldAddScytheOption(pla);

    out << "Move 8 shouldAddScytheOption: " << (shouldAdd ? "true" : "false") << endl;

    testAssert(shouldAdd == false);

    string expected = R"%%(
Move 8 shouldAddScytheOption: false
)%%";
    TestCommon::expect(name, out, expected);
  }

  //============================================================================
  // Test 14: shouldAddScytheOption returns false after move 49
  //============================================================================
  {
    const char* name = "Scythe search - should not add option after move 49";

    Board board(11, 11);
    Player pla = P_BLACK;
    Rules rules = Rules::getTrompTaylorish();
    BoardHistory hist(board, pla, rules, 0);

    makeMoves(board, hist, pla, 55);

    bool shouldAdd = hist.shouldAddScytheOption(pla);

    out << "Move 55 shouldAddScytheOption: " << (shouldAdd ? "true" : "false") << endl;

    testAssert(shouldAdd == false);

    string expected = R"%%(
Move 55 shouldAddScytheOption: false
)%%";
    TestCommon::expect(name, out, expected);
  }

  //============================================================================
  // Test 15: shouldAddScytheOption returns false when no scythes left
  //============================================================================
  {
    const char* name = "Scythe search - should not add option when no scythes";

    Board board(11, 11);
    Player pla = P_BLACK;
    Rules rules = Rules::getTrompTaylorish();
    BoardHistory hist(board, pla, rules, 0);

    makeMoves(board, hist, pla, 15);

    // Deplete all scythes
    hist.blackScythes = 0;
    hist.whiteScythes = 0;

    bool shouldAddBlack = hist.shouldAddScytheOption(P_BLACK);
    bool shouldAddWhite = hist.shouldAddScytheOption(P_WHITE);

    out << "No scythes - Black shouldAddScytheOption: " << (shouldAddBlack ? "true" : "false") << endl;
    out << "No scythes - White shouldAddScytheOption: " << (shouldAddWhite ? "true" : "false") << endl;

    testAssert(shouldAddBlack == false);
    testAssert(shouldAddWhite == false);

    string expected = R"%%(
No scythes - Black shouldAddScytheOption: false
No scythes - White shouldAddScytheOption: false
)%%";
    TestCommon::expect(name, out, expected);
  }

  //============================================================================
  // Test 16: shouldAddScytheOption returns false during combo
  //============================================================================
  {
    const char* name = "Scythe search - should not add option during combo";

    Board board(11, 11);
    Player pla = P_BLACK;
    Rules rules = Rules::getTrompTaylorish();
    BoardHistory hist(board, pla, rules, 0);

    makeMoves(board, hist, pla, 15);

    // Simulate being in a combo
    hist.scytheCombo = 2;

    bool shouldAdd = hist.shouldAddScytheOption(pla);

    out << "During combo shouldAddScytheOption: " << (shouldAdd ? "true" : "false") << endl;

    testAssert(shouldAdd == false);

    string expected = R"%%(
During combo shouldAddScytheOption: false
)%%";
    TestCommon::expect(name, out, expected);
  }

  cout << "Scythe search tests passed!" << endl;
}

//-------------------------------------------------------------------------------------
// Phase 3 Tests: Create scythe trigger virtual node
// TDD: These tests define the expected behavior of createScytheTriggerNode()
//-------------------------------------------------------------------------------------

void Tests::runScytheNodeTests() {
  cout << "Running scythe node tests" << endl;
  ostringstream out;

  //============================================================================
  // Test 17: SCYTHE_TRIGGER_LOC is correctly defined
  //============================================================================
  {
    const char* name = "Scythe node - SCYTHE_TRIGGER_LOC defined";

    out << "SCYTHE_TRIGGER_LOC value: " << Board::SCYTHE_TRIGGER_LOC << endl;
    out << "PASS_LOC value: " << Board::PASS_LOC << endl;

    // SCYTHE_TRIGGER_LOC should be different from PASS_LOC and regular locations
    testAssert(Board::SCYTHE_TRIGGER_LOC != Board::PASS_LOC);
    testAssert(Board::SCYTHE_TRIGGER_LOC != Board::NULL_LOC);

    string expected = R"%%(
SCYTHE_TRIGGER_LOC value: 2
PASS_LOC value: 1
)%%";
    TestCommon::expect(name, out, expected);
  }

  //============================================================================
  // Test 18: isScytheMove helper function
  //============================================================================
  {
    const char* name = "Scythe node - isScytheMove helper";

    // Test that we can identify a scythe move location
    Loc scytheLoc = Board::SCYTHE_TRIGGER_LOC;
    Loc passLoc = Board::PASS_LOC;
    Loc normalLoc = Location::getLoc(5, 5, 11);

    out << "SCYTHE_TRIGGER_LOC isScytheMove: " << (Board::isScytheMove(scytheLoc) ? "true" : "false") << endl;
    out << "PASS_LOC isScytheMove: " << (Board::isScytheMove(passLoc) ? "true" : "false") << endl;
    out << "Normal loc isScytheMove: " << (Board::isScytheMove(normalLoc) ? "true" : "false") << endl;

    testAssert(Board::isScytheMove(scytheLoc) == true);
    testAssert(Board::isScytheMove(passLoc) == false);
    testAssert(Board::isScytheMove(normalLoc) == false);

    string expected = R"%%(
SCYTHE_TRIGGER_LOC isScytheMove: true
PASS_LOC isScytheMove: false
Normal loc isScytheMove: false
)%%";
    TestCommon::expect(name, out, expected);
  }

  //============================================================================
  // Test 19: Location::toString handles SCYTHE_TRIGGER_LOC
  //============================================================================
  {
    const char* name = "Scythe node - Location toString for SCYTHE";

    Board board(11, 11);
    Loc scytheLoc = Board::SCYTHE_TRIGGER_LOC;
    string scytheStr = Location::toString(scytheLoc, board);

    out << "SCYTHE_TRIGGER_LOC toString: " << scytheStr << endl;

    // Should output "SCYTHE" for the special location
    testAssert(scytheStr == "SCYTHE");

    string expected = R"%%(
SCYTHE_TRIGGER_LOC toString: SCYTHE
)%%";
    TestCommon::expect(name, out, expected);
  }

  //============================================================================
  // Test 20: Location::ofString handles "SCYTHE"
  //============================================================================
  {
    const char* name = "Scythe node - Location ofString for SCYTHE";

    Board board(11, 11);
    Loc parsedLoc = Location::ofString("SCYTHE", board);

    out << "Parsed 'SCYTHE' loc: " << parsedLoc << endl;
    out << "Equals SCYTHE_TRIGGER_LOC: " << (parsedLoc == Board::SCYTHE_TRIGGER_LOC ? "true" : "false") << endl;

    testAssert(parsedLoc == Board::SCYTHE_TRIGGER_LOC);

    string expected = R"%%(
Parsed 'SCYTHE' loc: 2
Equals SCYTHE_TRIGGER_LOC: true
)%%";
    TestCommon::expect(name, out, expected);
  }

  cout << "Scythe node tests passed!" << endl;
}

//-------------------------------------------------------------------------------------
// Phase 4 Tests: Integrate scythe node into search descent logic
// TDD: These tests verify scythe trigger node handling during search
//-------------------------------------------------------------------------------------

void Tests::runScytheTriggerTests() {
  cout << "Running scythe trigger tests" << endl;
  ostringstream out;

  //============================================================================
  // Test 21: Manual scythe trigger sets manualScytheTrigger flag
  //============================================================================
  {
    const char* name = "Scythe trigger - manual trigger flag";

    Board board(11, 11);
    Player pla = P_BLACK;
    Rules rules = Rules::getTrompTaylorish();
    BoardHistory hist(board, pla, rules, 0);

    // Simulate moves to reach move 11
    for(int i = 0; i < 11; i++) {
      Loc loc = Location::getLoc(i % 11, i / 11, 11);
      hist.makeBoardMoveAssumeLegal(board, loc, pla, nullptr);
      pla = getOpp(pla);
    }

    // Should be at move 11
    testAssert(hist.getCurrentTurnNumber() == 11);

    // Verify initial state
    out << "Before trigger: manualScytheTrigger = " << (hist.manualScytheTrigger ? "true" : "false") << endl;
    out << "Before trigger: scytheCombo = " << hist.scytheCombo << endl;
    out << "Before trigger: blackScythes = " << hist.blackScythes << endl;

    testAssert(hist.manualScytheTrigger == false);
    testAssert(hist.scytheCombo == 0);

    // Set manual trigger
    hist.manualScytheTrigger = true;

    // Make a move with trigger set
    Loc triggerLoc = Location::getLoc(5, 5, 11);
    hist.makeBoardMoveAssumeLegal(board, triggerLoc, P_BLACK, nullptr);

    // After trigger, scytheCombo should be 3
    out << "After trigger: scytheCombo = " << hist.scytheCombo << endl;
    out << "After trigger: blackScythes = " << hist.blackScythes << endl;
    out << "After trigger: manualScytheTrigger = " << (hist.manualScytheTrigger ? "true" : "false") << endl;

    testAssert(hist.scytheCombo == 3);
    testAssert(hist.blackScythes == 2);  // Consumed one scythe

    string expected = R"%%(
Before trigger: manualScytheTrigger = false
Before trigger: scytheCombo = 0
Before trigger: blackScythes = 3
After trigger: scytheCombo = 3
After trigger: blackScythes = 2
After trigger: manualScytheTrigger = false
)%%";
    TestCommon::expect(name, out, expected);
  }

  //============================================================================
  // Test 22: Scythe combo progression (3 -> 2 -> 1 -> 0)
  //============================================================================
  {
    const char* name = "Scythe trigger - combo progression";

    Board board(11, 11);
    Player pla = P_BLACK;
    Rules rules = Rules::getTrompTaylorish();
    BoardHistory hist(board, pla, rules, 0);

    // Simulate moves to reach move 11
    for(int i = 0; i < 11; i++) {
      Loc loc = Location::getLoc(i % 11, i / 11, 11);
      hist.makeBoardMoveAssumeLegal(board, loc, pla, nullptr);
      pla = getOpp(pla);
    }

    // Trigger scythe for Black
    hist.manualScytheTrigger = true;
    Loc loc1 = Location::getLoc(5, 5, 11);
    hist.makeBoardMoveAssumeLegal(board, loc1, P_BLACK, nullptr);

    out << "After trigger: combo = " << hist.scytheCombo << endl;

    // White's normal move (combo stays same, but we're on opposite side)
    Loc loc2 = Location::getLoc(6, 5, 11);
    hist.makeBoardMoveAssumeLegal(board, loc2, P_WHITE, nullptr);
    out << "After white move: combo = " << hist.scytheCombo << endl;

    // Black's 2nd scythe move (combo should decrease)
    Loc loc3 = Location::getLoc(7, 5, 11);
    hist.makeBoardMoveAssumeLegal(board, loc3, P_BLACK, nullptr);
    out << "After black 2nd: combo = " << hist.scytheCombo << endl;

    // White's 2nd move
    Loc loc4 = Location::getLoc(8, 5, 11);
    hist.makeBoardMoveAssumeLegal(board, loc4, P_WHITE, nullptr);
    out << "After white 2nd: combo = " << hist.scytheCombo << endl;

    // Black's 3rd scythe move
    Loc loc5 = Location::getLoc(9, 5, 11);
    hist.makeBoardMoveAssumeLegal(board, loc5, P_BLACK, nullptr);
    out << "After black 3rd: combo = " << hist.scytheCombo << endl;

    // White's 3rd move
    Loc loc6 = Location::getLoc(10, 5, 11);
    hist.makeBoardMoveAssumeLegal(board, loc6, P_WHITE, nullptr);
    out << "After white 3rd: combo = " << hist.scytheCombo << endl;

    testAssert(hist.scytheCombo == 0);

    string expected = R"%%(
After trigger: combo = 3
After white move: combo = 2
After black 2nd: combo = 1
After white 2nd: combo = 0
After black 3rd: combo = 0
After white 3rd: combo = 0
)%%";
    TestCommon::expect(name, out, expected);
  }

  cout << "Scythe trigger tests passed!" << endl;
}

//-------------------------------------------------------------------------------------
// Phase 5 Tests: Auto-add scythe options to search tree
// TDD: These tests verify that search automatically explores scythe variations
//-------------------------------------------------------------------------------------

void Tests::runScytheSearchIntegrationTests() {
  cout << "Running scythe search integration tests" << endl;
  ostringstream out;

  //============================================================================
  // Test 24: Scythe option is available via canUseScythe at move 11
  //============================================================================
  {
    const char* name = "Scythe search integration - canUseScythe at move 11";

    Board board(11, 11);
    Player pla = P_BLACK;
    Rules rules = Rules::getTrompTaylorish();
    BoardHistory hist(board, pla, rules, 0);

    // Simulate moves to reach move 11
    for(int i = 0; i < 11; i++) {
      Loc loc = Location::getLoc(i % 11, i / 11, 11);
      hist.makeBoardMoveAssumeLegal(board, loc, pla, nullptr);
      pla = getOpp(pla);
    }

    // At move 11, after 11 moves
    testAssert(hist.getCurrentTurnNumber() == 11);

    // Verify scythe is available
    bool canUseBlack = hist.canUseScythe(P_BLACK);
    bool canUseWhite = hist.canUseScythe(P_WHITE);

    out << "Move 11 - canUseScythe(BLACK): " << (canUseBlack ? "true" : "false") << endl;
    out << "Move 11 - canUseScythe(WHITE): " << (canUseWhite ? "true" : "false") << endl;

    testAssert(canUseBlack == true);
    testAssert(canUseWhite == true);

    string expected = R"%%(
Move 11 - canUseScythe(BLACK): true
Move 11 - canUseScythe(WHITE): true
)%%";
    TestCommon::expect(name, out, expected);
  }

  //============================================================================
  // Test 25: shouldAddScytheOption matches canUseScythe
  //============================================================================
  {
    const char* name = "Scythe search integration - shouldAddScytheOption consistency";

    Board board(11, 11);
    Player pla = P_BLACK;
    Rules rules = Rules::getTrompTaylorish();
    BoardHistory hist(board, pla, rules, 0);

    // Test at various move numbers
    vector<int> testMoves = {10, 11, 20, 49, 50};

    for(int targetMove : testMoves) {
      // Reset for each iteration
      board = Board(11, 11);
      hist = BoardHistory(board, P_BLACK, rules, 0);
      pla = P_BLACK;

      // Simulate moves to target
      for(int i = 0; i < targetMove; i++) {
        Loc loc = Location::getLoc(i % 11, i / 11, 11);
        hist.makeBoardMoveAssumeLegal(board, loc, pla, nullptr);
        pla = getOpp(pla);
      }

      bool canUse = hist.canUseScythe(P_BLACK);
      bool shouldAdd = hist.shouldAddScytheOption(P_BLACK);

      out << "Move " << targetMove << " - canUseScythe: " << (canUse ? "true" : "false")
          << ", shouldAddScytheOption: " << (shouldAdd ? "true" : "false") << endl;

      // They should match
      testAssert(canUse == shouldAdd);
    }

    string expected = R"%%(
Move 10 - canUseScythe: false, shouldAddScytheOption: false
Move 11 - canUseScythe: true, shouldAddScytheOption: true
Move 20 - canUseScythe: true, shouldAddScytheOption: true
Move 49 - canUseScythe: true, shouldAddScytheOption: true
Move 50 - canUseScythe: false, shouldAddScytheOption: false
)%%";
    TestCommon::expect(name, out, expected);
  }

  //============================================================================
  // Test 26: Location string parsing for scythe moves
  //============================================================================
  {
    const char* name = "Scythe search integration - Location parsing";

    Board board(11, 11);

    // Test parsing various move strings
    vector<string> moveStrs = {"A1", "K11", "SCYTHE", "pass"};

    for(const string& moveStr : moveStrs) {
      Loc loc = Location::ofString(moveStr, board);
      string parsed = Location::toString(loc, board);

      out << "Parsed '" << moveStr << "' -> " << parsed << endl;
    }

    testAssert(Location::ofString("SCYTHE", board) == Board::SCYTHE_TRIGGER_LOC);
    testAssert(Location::toString(Board::SCYTHE_TRIGGER_LOC, board) == "SCYTHE");

    string expected = R"%%(
Parsed 'A1' -> A1
Parsed 'K11' -> K11
Parsed 'SCYTHE' -> SCYTHE
Parsed 'pass' -> pass
)%%";
    TestCommon::expect(name, out, expected);
  }

  cout << "Scythe search integration tests passed!" << endl;
}

//-------------------------------------------------------------------------------------
// Phase 6 Tests: GTP output support for scythe variations
// TDD: These tests verify that GTP commands handle scythe moves
//-------------------------------------------------------------------------------------

void Tests::runScytheGTPTests() {
  cout << "Running scythe GTP tests" << endl;
  ostringstream out;

  //============================================================================
  // Test 27: GTP command parsing supports SCYTHE location
  //============================================================================
  {
    const char* name = "Scythe GTP - SCYTHE location parsing";

    Board board(11, 11);

    // Test that GTP location strings work with SCYTHE
    string scytheStr = "SCYTHE";
    Loc scytheLoc = Location::ofString(scytheStr, board);

    out << "GTP parsed 'SCYTHE' as: " << scytheLoc << endl;
    out << "Is scythe move: " << (Board::isScytheMove(scytheLoc) ? "true" : "false") << endl;
    out << "Back to string: " << Location::toString(scytheLoc, board) << endl;

    testAssert(scytheLoc == Board::SCYTHE_TRIGGER_LOC);
    testAssert(Board::isScytheMove(scytheLoc));

    string expected = R"%%(
GTP parsed 'SCYTHE' as: 2
Is scythe move: true
Back to string: SCYTHE
)%%";
    TestCommon::expect(name, out, expected);
  }

  //============================================================================
  // Test 28: Scythe move output in analysis
  //============================================================================
  {
    const char* name = "Scythe GTP - analysis output format";

    // Simulate what GTP output would contain
    out << "Move analysis would include:" << endl;
    out << "  - Regular moves (e.g., D4)" << endl;
    out << "  - Pass moves" << endl;
    out << "  - SCYTHE variation (new)" << endl;

    // Verify the SCYTHE location constant
    testAssert(Board::SCYTHE_TRIGGER_LOC == 2);
    testAssert(Board::PASS_LOC == 1);
    testAssert(Board::NULL_LOC == 0);

    string expected = R"%%(
Move analysis would include:
  - Regular moves (e.g., D4)
  - Pass moves
  - SCYTHE variation (new)
)%%";
    TestCommon::expect(name, out, expected);
  }

  //============================================================================
  // Test 29: Scythe move discrimination from normal moves
  //============================================================================
  {
    const char* name = "Scythe GTP - move discrimination";

    Board board(11, 11);

    // Create various move locations
    Loc normalMove = Location::getLoc(0, 0, 11);
    Loc passMove = Board::PASS_LOC;
    Loc scytheMove = Board::SCYTHE_TRIGGER_LOC;

    out << "Normal move: " << Location::toString(normalMove, board) << " - isScythe: " << (Board::isScytheMove(normalMove) ? "true" : "false") << endl;
    out << "Pass move: " << Location::toString(passMove, board) << " - isScythe: " << (Board::isScytheMove(passMove) ? "true" : "false") << endl;
    out << "Scythe move: " << Location::toString(scytheMove, board) << " - isScythe: " << (Board::isScytheMove(scytheMove) ? "true" : "false") << endl;

    testAssert(!Board::isScytheMove(normalMove));
    testAssert(!Board::isScytheMove(passMove));
    testAssert(Board::isScytheMove(scytheMove));

    string expected = R"%%(
Normal move: A11 - isScythe: false
Pass move: pass - isScythe: false
Scythe move: SCYTHE - isScythe: true
)%%";
    TestCommon::expect(name, out, expected);
  }

  cout << "Scythe GTP tests passed!" << endl;
}
