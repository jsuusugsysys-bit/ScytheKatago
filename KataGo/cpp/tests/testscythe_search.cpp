// Test file for scythe search functionality
// Tests the integration between search tree and scythe trigger logic

#include "../core/global.h"
#include "../core/config_parser.h"
#include "../core/timer.h"
#include "../game/rules.h"
#include "../game/board.h"
#include "../game/boardhistory.h"
#include "../search/asyncbot.h"
#include "../program/setup.h"
#include "../tests/tests.h"
#include "../main.h"

using namespace std;
using namespace TestCommon;

//========================================================================================
// TEST 1: applyScytheTrigger sets scytheCombo correctly
//========================================================================================
void Tests::runScytheSearchTriggerStateTest() {
  cout << "===================================" << endl;
  cout << "TEST 1: applyScytheTrigger State" << endl;
  cout << "===================================" << endl;

  const char* name = "Scythe search - applyScytheTrigger sets scytheCombo";

  try {
    // Setup board
    Board board(11, 11);
    Player pla = P_BLACK;
    Rules rules = Rules::getTrompTaylorish();
    BoardHistory hist(board, pla, rules);

    // Initialize scythe state
    hist.blackScythes = 3;
    hist.whiteScythes = 3;
    hist.scytheCombo = 0;
    hist.presumedNextMovePla = P_BLACK;

    cout << "Initial state:" << endl;
    cout << "  blackScythes: " << hist.blackScythes << endl;
    cout << "  whiteScythes: " << hist.whiteScythes << endl;
    cout << "  scytheCombo: " << hist.scytheCombo << endl;
    cout << "  presumedNextMovePla: " << PlayerIO::playerToString(hist.presumedNextMovePla) << endl;

    // Simulate search setup
    string modelFile = "models/kata1-b6c96.bin.gz";
    NNEvaluator* nnEval = Setup::initializeNNEvaluator(
      modelFile, modelFile, string(), Config(), Logger::getGlobalLogger(),
      Rand(), 1, false, Setup::SETUP_FOR_GTP
    );

    SearchParams params;
    params.maxVisits = 100;
    Search search(params, nnEval, nullptr, Logger::getGlobalLogger());
    search.setPosition(pla, board, hist);

    // Create a search thread
    SearchThread thread(0, search);
    thread.pla = P_BLACK;
    thread.board = board;
    thread.history = hist;

    cout << "\nApplying scythe trigger..." << endl;

    // Apply scythe trigger (this is the function we're testing)
    search.applyScytheTrigger(thread);

    cout << "\nState after applyScytheTrigger:" << endl;
    cout << "  blackScythes: " << thread.history.blackScythes << endl;
    cout << "  whiteScythes: " << thread.history.whiteScythes << endl;
    cout << "  scytheCombo: " << thread.history.scytheCombo << endl;
    cout << "  presumedNextMovePla: " << PlayerIO::playerToString(thread.history.presumedNextMovePla) << endl;
    cout << "  manualScytheTrigger: " << (thread.history.manualScytheTrigger ? "true" : "false") << endl;

    // Verify expectations
    bool passed = true;
    string errors = "";

    // BUG: Current implementation doesn't set scytheCombo
    // Expected: scytheCombo should be 3 (for 3 consecutive moves)
    if(thread.history.scytheCombo != 3) {
      passed = false;
      errors += "  ERROR: scytheCombo should be 3, got " + to_string(thread.history.scytheCombo) + "\n";
    }

    // Scythes should be decremented
    if(thread.history.blackScythes != 2) {
      passed = false;
      errors += "  ERROR: blackScythes should be 2, got " + to_string(thread.history.blackScythes) + "\n";
    }

    // White scythes should be unchanged
    if(thread.history.whiteScythes != 3) {
      passed = false;
      errors += "  ERROR: whiteScythes should be 3, got " + to_string(thread.history.whiteScythes) + "\n";
    }

    // presumedNextMovePla should not switch (stay BLACK)
    if(thread.history.presumedNextMovePla != P_BLACK) {
      passed = false;
      errors += "  ERROR: presumedNextMovePla should be BLACK, got " + PlayerIO::playerToString(thread.history.presumedNextMovePla) + "\n";
    }

    // Cleanup
    delete nnEval;

    if(passed) {
      cout << "\n" << name << " - PASSED" << endl;
    } else {
      cout << "\n" << name << " - FAILED" << endl;
      cout << errors;
      throw StringError("Test failed");
    }

  } catch(const exception& e) {
    cout << "EXCEPTION: " << e.what() << endl;
    throw;
  }
}

//========================================================================================
// TEST 2: Scythe trigger in search tree selects 3 consecutive moves
//========================================================================================
void Tests::runScytheSearchConsecutiveMovesTest() {
  cout << "\n===================================" << endl;
  cout << "TEST 2: Scythe Consecutive Moves in Search" << endl;
  cout << "===================================" << endl;

  const char* name = "Scythe search - 3 consecutive moves without player switch";

  try {
    // Setup board with some stones (to make search interesting)
    Board board(11, 11);
    Player pla = P_WHITE;
    Rules rules = Rules::getTrompTaylorish();
    BoardHistory hist(board, pla, rules);

    // Play some moves to reach move 11
    hist.makeBoardMoveAssumeLegal(board, Location::getLoc(3, 3, 11), P_BLACK, nullptr);
    hist.makeBoardMoveAssumeLegal(board, Location::getLoc(3, 9, 11), P_WHITE, nullptr);
    hist.makeBoardMoveAssumeLegal(board, Location::getLoc(4, 4, 11), P_BLACK, nullptr);
    hist.makeBoardMoveAssumeLegal(board, Location::getLoc(5, 9, 11), P_WHITE, nullptr);
    hist.makeBoardMoveAssumeLegal(board, Location::getLoc(5, 4, 11), P_BLACK, nullptr);
    hist.makeBoardMoveAssumeLegal(board, Location::getLoc(6, 9, 11), P_WHITE, nullptr);
    hist.makeBoardMoveAssumeLegal(board, Location::getLoc(6, 4, 11), P_BLACK, nullptr);
    hist.makeBoardMoveAssumeLegal(board, Location::getLoc(7, 9, 11), P_WHITE, nullptr);
    hist.makeBoardMoveAssumeLegal(board, Location::getLoc(7, 4, 11), P_BLACK, nullptr);
    hist.makeBoardMoveAssumeLegal(board, Location::getLoc(4, 9, 11), P_WHITE, nullptr);
    hist.makeBoardMoveAssumeLegal(board, Location::getLoc(4, 5, 11), P_BLACK, nullptr);

    cout << "Move number: " << hist.getCurrentTurnNumber() << endl;
    cout << "Next player: " << PlayerIO::playerToString(hist.presumedNextMovePla) << endl;
    cout << "White scythes: " << hist.whiteScythes << endl;
    cout << "Can use scythe: " << (hist.canUseScythe(P_WHITE) ? "true" : "false") << endl;

    // Initialize search
    string modelFile = "models/kata1-b6c96.bin.gz";
    NNEvaluator* nnEval = Setup::initializeNNEvaluator(
      modelFile, modelFile, string(), Config(), Logger::getGlobalLogger(),
      Rand(), 1, false, Setup::SETUP_FOR_GTP
    );

    SearchParams params;
    params.maxVisits = 500; // More visits to explore scythe option
    Search search(params, nnEval, nullptr, Logger::getGlobalLogger());
    search.setPosition(P_WHITE, board, hist);

    cout << "\nRunning search..." << endl;
    search.runWholeSearch(P_WHITE);

    // Check if SCYTHE_TRIGGER_LOC was explored
    SearchNode* root = search.getRootNode();
    bool foundScytheChild = false;
    int scytheChildVisits = 0;

    cout << "\nExamining root children:" << endl;
    ConstSearchNodeChildrenReference children = root->getChildren();
    int childrenCapacity = children.getCapacity();
    for(int i = 0; i < childrenCapacity; i++) {
      const SearchChildPointer& childPointer = children[i];
      const SearchNode* child = childPointer.getIfAllocated();
      if(child == NULL)
        break;

      Loc moveLoc = childPointer.getMoveLocRelaxed();
      int64_t visits = child->stats.visits.load();

      if(moveLoc == Board::SCYTHE_TRIGGER_LOC) {
        foundScytheChild = true;
        scytheChildVisits = visits;
        cout << "  SCYTHE_TRIGGER_LOC found! Visits: " << visits << endl;

        // Examine scythe child's children (should be white's moves)
        ConstSearchNodeChildrenReference scytheChildren = child->getChildren();
        int scytheChildrenCapacity = scytheChildren.getCapacity();
        cout << "  Scythe child has " << scytheChildrenCapacity << " children:" << endl;

        for(int j = 0; j < min(5, scytheChildrenCapacity); j++) {
          const SearchChildPointer& scytheChildPointer = scytheChildren[j];
          const SearchNode* scytheGrandchild = scytheChildPointer.getIfAllocated();
          if(scytheGrandchild == NULL)
            break;

          Loc scytheMoveLoc = scytheChildPointer.getMoveLocRelaxed();
          int64_t scytheVisits = scytheGrandchild->stats.visits.load();
          cout << "    " << Location::toString(scytheMoveLoc, board)
               << " (visits: " << scytheVisits << ")" << endl;
        }
      } else {
        cout << "  " << Location::toString(moveLoc, board)
             << " (visits: " << visits << ")" << endl;
      }
    }

    // Cleanup
    delete nnEval;

    bool passed = true;
    string errors = "";

    if(!foundScytheChild) {
      passed = false;
      errors += "  ERROR: SCYTHE_TRIGGER_LOC was not explored in search tree\n";
    } else if(scytheChildVisits < 10) {
      // Should have at least some visits if it's a viable option
      passed = false;
      errors += "  WARNING: SCYTHE_TRIGGER_LOC has very few visits (" + to_string(scytheChildVisits) + ")\n";
    }

    if(passed) {
      cout << "\n" << name << " - PASSED" << endl;
    } else {
      cout << "\n" << name << " - FAILED" << endl;
      cout << errors;
      throw StringError("Test failed");
    }

  } catch(const exception& e) {
    cout << "EXCEPTION: " << e.what() << endl;
    throw;
  }
}

//========================================================================================
// TEST 3: Verify player doesn't switch during scythe combo
//========================================================================================
void Tests::runScytheSearchPlayerSwitchTest() {
  cout << "\n===================================" << endl;
  cout << "TEST 3: Player Switch During Scythe Combo" << endl;
  cout << "===================================" << endl;

  const char* name = "Scythe search - player does not switch during combo";

  try {
    // Setup board
    Board board(11, 11);
    Player pla = P_BLACK;
    Rules rules = Rules::getTrompTaylorish();
    BoardHistory hist(board, pla, rules);

    // Manually trigger scythe (simulate what applyScytheTrigger should do)
    hist.blackScythes = 3;
    hist.scytheCombo = 3;  // Manually set to test countdown logic
    hist.presumedNextMovePla = P_BLACK;

    cout << "Initial state (scythe already triggered):" << endl;
    cout << "  scytheCombo: " << hist.scytheCombo << endl;
    cout << "  presumedNextMovePla: " << PlayerIO::playerToString(hist.presumedNextMovePla) << endl;

    // Simulate 3 consecutive moves
    for(int i = 0; i < 3; i++) {
      cout << "\nMove " << (i+1) << ":" << endl;
      Loc moveLoc = Location::getLoc(i, 0, 11);

      hist.makeBoardMoveAssumeLegal(board, moveLoc, P_BLACK, nullptr);

      cout << "  After move:" << endl;
      cout << "    scytheCombo: " << hist.scytheCombo << endl;
      cout << "    presumedNextMovePla: " << PlayerIO::playerToString(hist.presumedNextMovePla) << endl;

      if(i < 2) {
        // First 2 moves should not switch player
        testAssert(hist.presumedNextMovePla == P_BLACK);
        testAssert(hist.scytheCombo == 2 - i);
      } else {
        // After 3rd move, player switches and combo ends
        testAssert(hist.presumedNextMovePla == P_WHITE);
        testAssert(hist.scytheCombo == 0);
      }
    }

    cout << "\n" << name << " - PASSED" << endl;

  } catch(const exception& e) {
    cout << "EXCEPTION: " << e.what() << endl;
    throw;
  }
}

//========================================================================================
// Run all scythe search tests
//========================================================================================
void Tests::runScytheSearchTests() {
  cout << "\n" << endl;
  cout << "========================================" << endl;
  cout << "SCYTHE SEARCH TESTS" << endl;
  cout << "========================================" << endl;

  try {
    // Test 1: applyScytheTrigger state
    runScytheSearchTriggerStateTest();

    // Test 2: Search tree exploration
    runScytheSearchConsecutiveMovesTest();

    // Test 3: Player switch logic
    runScytheSearchPlayerSwitchTest();

    cout << "\n========================================" << endl;
    cout << "ALL SCYTHE SEARCH TESTS PASSED" << endl;
    cout << "========================================" << endl;

  } catch(const exception& e) {
    cout << "\n========================================" << endl;
    cout << "SCYTHE SEARCH TESTS FAILED" << endl;
    cout << "========================================" << endl;
    throw;
  }
}
