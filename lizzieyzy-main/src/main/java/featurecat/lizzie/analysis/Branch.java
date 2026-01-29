package featurecat.lizzie.analysis;

import featurecat.lizzie.Lizzie;
import featurecat.lizzie.rules.Board;
import featurecat.lizzie.rules.BoardData;
import featurecat.lizzie.rules.Stone;
import java.util.List;
import java.util.Optional;

public class Branch {
  public BoardData data;
  //  public int branchLength;
  // 待完成
  //  public int pvVisits = -1;
  public boolean[] isNewStone;
  public int[] pvVisitsList;
  public int length;
  // SCYTHE FIX: 每一步的玩家信息
  private List<String> pvPlayers;

  public Branch(
      Board board,
      List<String> variation,
      // 待完成
      List<String> pvVisits,
      int length,
      boolean fromSubboard,
      boolean blackToPlay,
      Stone[] stonesTemp,
      boolean forMouseOnStone,
      BoardData forMouseOnStoneData) {
    this(
        board,
        variation,
        pvVisits,
        null,
        length,
        fromSubboard,
        blackToPlay,
        stonesTemp,
        forMouseOnStone,
        forMouseOnStoneData);
  }

  // SCYTHE FIX: 带 pvPlayers 参数的构造函数
  public Branch(
      Board board,
      List<String> variation,
      List<String> pvVisits,
      List<String> pvPlayers,
      int length,
      boolean fromSubboard,
      boolean blackToPlay,
      Stone[] stonesTemp,
      boolean forMouseOnStone,
      BoardData forMouseOnStoneData) {
    this.pvPlayers = pvPlayers;
    int[] moveNumberList = new int[Board.boardWidth * Board.boardHeight];
    isNewStone = new boolean[Board.boardWidth * Board.boardHeight];
    pvVisitsList = new int[Board.boardWidth * Board.boardHeight];
    this.length = Math.min(variation.size(), length);
    int moveNumber = 0;
    double winrate = 0.0;
    int playouts = 0;
    //  branchLength = variation.size();
    if (forMouseOnStone) {
      this.data =
          new BoardData(
              forMouseOnStoneData.stones.clone(),
              forMouseOnStoneData.lastMove,
              forMouseOnStoneData.lastMoveColor,
              forMouseOnStoneData.blackToPlay,
              forMouseOnStoneData.zobrist.clone(),
              moveNumber,
              moveNumberList,
              forMouseOnStoneData.blackCaptures,
              forMouseOnStoneData.whiteCaptures,
              winrate,
              playouts);
    } else {
      if (fromSubboard) {
        this.data =
            new BoardData(
                stonesTemp.clone(), // stonesTemp
                board.getLastMove(),
                board.getData().lastMoveColor,
                blackToPlay,
                board.getData().zobrist.clone(),
                moveNumber,
                moveNumberList,
                board.getData().blackCaptures,
                board.getData().whiteCaptures,
                winrate,
                playouts);
      } else {
        if (stonesTemp != null)
          this.data =
              new BoardData(
                  stonesTemp.clone(),
                  board.getHistory().getCurrentHistoryNode().previous().get().getData().lastMove,
                  board
                      .getHistory()
                      .getCurrentHistoryNode()
                      .previous()
                      .get()
                      .getData()
                      .lastMoveColor,
                  board.getHistory().getCurrentHistoryNode().previous().get().getData().blackToPlay,
                  board
                      .getHistory()
                      .getCurrentHistoryNode()
                      .previous()
                      .get()
                      .getData()
                      .zobrist
                      .clone(),
                  moveNumber,
                  moveNumberList,
                  board
                      .getHistory()
                      .getCurrentHistoryNode()
                      .previous()
                      .get()
                      .getData()
                      .blackCaptures,
                  board
                      .getHistory()
                      .getCurrentHistoryNode()
                      .previous()
                      .get()
                      .getData()
                      .whiteCaptures,
                  winrate,
                  playouts);
        else
          this.data =
              new BoardData(
                  board.getStones().clone(),
                  board.getLastMove(),
                  board.getData().lastMoveColor,
                  board.getData().blackToPlay,
                  board.getData().zobrist.clone(),
                  moveNumber,
                  moveNumberList,
                  board.getData().blackCaptures,
                  board.getData().whiteCaptures,
                  winrate,
                  playouts);
      }
    }
    // SCYTHE FORCE RENDER: 检查镰刀状态
    boolean scytheActive = false;
    int scytheRemaining = 0;
    Stone scytheColor = Stone.BLACK;
    if (featurecat.lizzie.gui.LizzieFrame.scythePanel != null) {
      if (featurecat.lizzie.gui.LizzieFrame.scythePanel.isGuiComboActive()) {
        // 镰刀已激活，使用剩余连击数
        scytheActive = true;
        scytheRemaining = featurecat.lizzie.gui.LizzieFrame.scythePanel.getGuiComboRemaining();
        scytheColor = featurecat.lizzie.gui.LizzieFrame.scythePanel.getScythePlayerStone();
      } else if (featurecat.lizzie.gui.LizzieFrame.scythePanel.isScythePending()) {
        // 镰刀待触发（用户已点击但还没落子），显示完整 3 步连击效果
        scytheActive = true;
        scytheRemaining = 3;
        scytheColor =
            featurecat.lizzie.gui.LizzieFrame.scythePanel.getScythePendingPlayer()
                ? Stone.BLACK
                : Stone.WHITE;
      }
    }

    for (int i = 0; i < variation.size() && i < length; i++) {
      Optional<int[]> coordOpt = Board.asCoordinates(variation.get(i));
      if (!coordOpt.isPresent() || !Board.isValid(coordOpt.get()[0], coordOpt.get()[1])) {
        break;
      }
      int[] coord = coordOpt.get();

      int x = coord[0];
      int y = coord[1];
      data.lastMove = coordOpt;

      // SCYTHE FORCE RENDER: 前 N 手强制使用镰刀玩家的颜色
      Stone stoneColor;
      if (scytheActive && i < scytheRemaining) {
        // 强制渲染为镰刀玩家的颜色
        stoneColor = scytheColor;
      } else {
        // 正常逻辑
        stoneColor = data.blackToPlay ? Stone.BLACK : Stone.WHITE;
      }
      data.stones[Board.getIndex(coord[0], coord[1])] = stoneColor;

      isNewStone[Board.getIndex(coord[0], coord[1])] = true;
      // if (Lizzie.frame.floatBoard == null || !Lizzie.frame.floatBoard.isVisible()) {
      if (Lizzie.config.removeDeadChainInVariation && !Lizzie.config.noCapture) {
        Stone oppColor = (stoneColor == Stone.BLACK) ? Stone.WHITE : Stone.BLACK;
        Board.removeDeadChainForBranch(x + 1, y, oppColor, data.stones);
        Board.removeDeadChainForBranch(x, y + 1, oppColor, data.stones);
        Board.removeDeadChainForBranch(x - 1, y, oppColor, data.stones);
        Board.removeDeadChainForBranch(x, y - 1, oppColor, data.stones);
      }
      // }
      data.moveNumberList[Board.getIndex(coord[0], coord[1])] =
          i + 1; // 待完成,pvVisits也类似保存,选项可选 pvVisits显示全部/最后一手/不显示

      data.lastMoveColor = (stoneColor == Stone.BLACK) ? Stone.WHITE : Stone.BLACK;

      // SCYTHE FORCE RENDER: 镰刀期间不切换玩家，保持同色
      if (scytheActive && i < scytheRemaining - 1) {
        // 前 N-1 手保持同一玩家
        data.blackToPlay = (scytheColor == Stone.BLACK);
      } else if (pvPlayers != null && i + 1 < pvPlayers.size()) {
        // 使用 pvPlayers 决定下一步玩家
        String nextPlayer = pvPlayers.get(i + 1);
        data.blackToPlay = "B".equals(nextPlayer);
      } else {
        // 正常交替逻辑
        data.blackToPlay = !data.blackToPlay;
      }
      // 待完成,增加是否显示pvvisits的判断
      //  if (i == variation.size() - 1 || i == length - 1) {
      if (Lizzie.config.showPvVisitsAllMove || Lizzie.config.showPvVisitsLastMove) {
        if (pvVisits != null && pvVisits.size() == variation.size())
          try {
            //  this.pvVisits = Integer.parseInt(pvVisits.get(i));
            pvVisitsList[Board.getIndex(coord[0], coord[1])] = Integer.parseInt(pvVisits.get(i));
          } catch (NumberFormatException e) {
            e.printStackTrace();
          }
      }
    }
    //  }
  }
}
