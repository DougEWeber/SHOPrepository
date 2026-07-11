      //****************************************************************
      // PROGRAM NAME:   INVMAIN                                       *
      // RELATED FILES:  INVMENU (DSPF)                               *
      // RELATED PGMS:   INVMNT  (ILE RPG MODULE)                     *
      //                 INVRCV  (ILE RPG MODULE)                     *
      // DESCRIPTION:    Inventory main menu. Dispatches to           *
      //                 maintenance (INVMNT) or receive (INVRCV).    *
      //****************************************************************

     Finvmenu   cf   e             workstn indds(indicators)

     D InvMaintain     pr                  extproc('INVMNT')
     D InvReceive      pr                  extproc('INVRCV')

     D indicators      ds
     D    exitKey                      n   overlay(indicators:3)
     D    maintainKey                  n   overlay(indicators:5)
     D    receiveKey                   n   overlay(indicators:6)

      /free
           dow  '1';
              exfmt hdrscn;

              if exitKey;
                 leave;
              elseif maintainKey;
                 InvMaintain();
              elseif receiveKey;
                 InvReceive();
              endif;
           enddo;

           *inlr = *on;
      /end-free
