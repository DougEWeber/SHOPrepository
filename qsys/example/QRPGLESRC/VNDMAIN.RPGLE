      //****************************************************************
      // PROGRAM NAME:   VNDMAIN                                       *
      // RELATED PGMS:   VNDMNT  (ILE RPG MODULE)                     *
      // DESCRIPTION:    Vendor maintenance entry module.              *
      //                 Calls VNDMNT for all maintenance functions.   *
      //****************************************************************

     D VndMaintain     pr                  extproc('VNDMNT')

      /free
           VndMaintain();
           *inlr = *on;
      /end-free
