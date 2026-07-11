      //****************************************************************
      // PROGRAM NAME:   POMAIN                                        *
      // RELATED FILES:  POMENU (DSPF)                                *
      // RELATED PGMS:   POMNT  (ILE RPG MODULE)                      *
      // DESCRIPTION:    Purchase order main menu. Dispatches to      *
      //                 maintenance (POMNT).                         *
      //****************************************************************

     Fpomenu    cf   e             workstn indds(indicators)

     D PoMaintain      pr                  extproc('POMNT')

     D indicators      ds
     D    exitKey                      n   overlay(indicators:3)
     D    maintainKey                  n   overlay(indicators:5)

      /free
           dow  '1';
              exfmt hdrscn;

              if exitKey;
                 leave;
              elseif maintainKey;
                 PoMaintain();
              endif;
           enddo;

           *inlr = *on;
      /end-free
