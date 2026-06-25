      //****************************************************************
      // PROGRAM NAME:   INVFIN                                        *
      // RELATED FILES:  INVMSTL1 (LF)                                 *
      // DESCRIPTION:    Inventory finalize API.                       *
      //                 Decrements QTYOH and QTYIP by the finalized   *
      //                 count. Neither quantity goes below zero.      *
      //                                                               *
      // Parameters:                                                   *
      //   PITMID  - Item ID (10A, input)                              *
      //   PQTYFIN - Quantity finalized (7P, input)                    *
      //   PFINFRC - Return code: '0'=OK '1'=item not found (output)  *
      //****************************************************************

     Finvmstl1  uf   e           k disk

     D PITMID          s             10
     D PQTYFIN         s              7  0
     D PFINFRC         s              1

     C     *ENTRY        PLIST
     C                   PARM                    PITMID
     C                   PARM                    PQTYFIN
     C                   PARM                    PFINFRC

     C     INVKEY        KLIST
     C                   KFLD                    INVID

      /free

       invid = pitmid;
       chain invkey imlrec1;

       if not %found(invmstl1);
          pfinfrc = '1';
       else;
          if qtyoh >= pqtyfin;
             qtyoh = qtyoh - pqtyfin;
          else;
             qtyoh = 0;
          endif;

          if qtyip >= pqtyfin;
             qtyip = qtyip - pqtyfin;
          else;
             qtyip = 0;
          endif;

          pfinfrc = '0';
          update imlrec1;
       endif;

       *inlr = *on;
      /end-free
