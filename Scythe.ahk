; 按 F1 键触发镰刀
  F1::
      SetTitleMatchMode, 2
      IfWinActive, Lizzie ; 确保只在 Lizzie 窗口生效
      {
          Send, g ; 打开控制台
          Sleep, 100 ; 等0.1秒
          Send, scythe{Enter} ; 发送命令
          Sleep, 100
          Send, {Esc} ; 关闭控制台
      }
  return

  ; 按 F2 键重置镰刀次数
  F2::
      SetTitleMatchMode, 2
      IfWinActive, Lizzie
      {
          Send, g
          Sleep, 100
          Send, scythe_reset{Enter}
          Sleep, 100
          Send, {Esc}
      }
  return