      //****************************************************************
      // PROGRAM NAME:   INVAVL                                        *
      // RELATED FILES:  INVMSTL1 (LF)                                 *
      // DESCRIPTION:    Inventory availability API.                   *
      //                 Checks whether requested quantity is          *
      //                 available (QTYOH - QTYIP >= requested).      *
      //                 If available, reserves qty by adding to QTYIP.*
      //                                                               *
      // Parameters:                                                   *
      //   PITMID  - Item ID (10A, input)                              *
      //   PQTYREQ - Quantity requested (7P, input)                    *
      //   PAVLFLG - Available: '1'=yes '0'=no (1A, output)           *
      //   PAVLQTY - Available quantity (7P, output)                   *
      //****************************************************************

     Finvmstl1  uf   e           k disk

     D PITMID          s             10
     D PQTYREQ         s              7  0
     D PAVLFLG         s              1
     D PAVLQTY         s              7  0

     C     *ENTRY        PLIST
     C                   PARM                    PITMID
     C                   PARM                    PQTYREQ
     C                   PARM                    PAVLFLG
     C                   PARM                    PAVLQTY

     C     INVKEY        KLIST
     C                   KFLD                    INVID

      /free

       invid = pitmid;
       chain invkey imlrec1;

       if not %found(invmstl1);
          pavlflg = '0';
          pavlqty = 0;
       else;
          pavlqty = qtyoh - qtyip;

          if pavlqty >= pqtyreq and pqtyreq > 0;
             qtyip   = qtyip + pqtyreq;
             pavlflg = '1';
             update imlrec1;
          else;
             pavlflg = '0';
             unlock invmstl1;
          endif;
       endif;

       *inlr = *on;
      /end-free
