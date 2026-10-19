      //****************************************************************
      // PROGRAM NAME:   ORDCHG                                        *
      // RELATED FILES:  CUSMSTL1 (LF), ORDMSTL1 (LF), ORDDTL (PF),    *
      //                 ORDCHG (DSPF)                                 *
      // DESCRIPTION:    Order change. Only orders in the "in process"  *
      //                 (O) status can be changed. Existing lines can  *
      //                 have their quantity changed or be removed      *
      //                 (mark Del). Item and price cannot be changed.  *
      //                 A quantity cannot be reduced below what has    *
      //                 already shipped. If every line ends up         *
      //                 removed, F5 asks for a second press to confirm *
      //                 deleting the whole order; any other change     *
      //                 clears that pending confirmation.              *
      //****************************************************************

     Fcusmstl1  if   e           k disk
     Fordmstl1  uf   e           k disk
     Forddtl    uf   e           k disk
     Fordchg    cf   e             workstn sfile(ordlin2:rrn)
     F                                     indds(indicators)

     D indicators      ds
     D   exitKey                       n   overlay(indicators:3)
     D   saveKey                       n   overlay(indicators:5)
     D   cancelKey                     n   overlay(indicators:12)
     D   ordNotFound                   n   overlay(indicators:52)
     D   notInProcess                  n   overlay(indicators:53)
     D   sflClear                      n   overlay(indicators:20)

     D rrn             s              5p 0
     D newQty          s              7p 0
     D isDelete        s               n
     D errFound        s               n
     D orderDeleted    s               n
     D pendingDelete   s               n
     D remainingCount  s              5p 0

     C     ORDLKEY       KLIST
     C                   KFLD                    ORDID
     C                   KFLD                    LINE

      /free

       dow not exitKey;
          ordid = 0;
          exfmt hdrscn;
          ordNotFound  = *off;
          notInProcess = *off;
          if exitKey;
             leave;
          endif;
          if ordid <> 0;
             exsr LoadOrder;
          endif;
       enddo;

       *inlr = *on;
       return;

       //****************************************************************
       //    SUBROUTINE - LoadOrder                                     *
       //    PURPOSE    - Validate the order, then run the edit loop     *
       //****************************************************************
       begsr LoadOrder;
          chain ordid omlrec1;
          if not %found(ordmstl1);
             ordNotFound = *on;
             leavesr;
          endif;

          if ordstat <> 'O';
             notInProcess = *on;
             unlock ordmstl1;
             leavesr;
          endif;

          cusname = *blank;
          chain cust cmlrec1;
          if %found(cusmstl1);
             cusname = name;
          endif;

          errtxt = *blank;
          pendingDelete = *off;
          orderDeleted = *off;
          exsr LoadLines;

          dow not cancelKey and not orderDeleted;
             exfmt ordctlr;
             if cancelKey;
                unlock ordmstl1;
                leave;
             endif;

             if saveKey;
                exsr SaveChanges;
                if orderDeleted;
                   // show the "order deleted" confirmation once
                   // before returning to the order id prompt --
                   // the dow condition below would otherwise exit
                   // without ever displaying it
                   exfmt ordctlr;
                   leave;
                endif;
             else;
                errtxt = *blank;
                pendingDelete = *off;
             endif;
          enddo;
       endsr;

       //****************************************************************
       //    SUBROUTINE - LoadLines                                     *
       //    PURPOSE    - Clear the subfile and reload it from ORDDTL    *
       //****************************************************************
       begsr LoadLines;
          sflClear = *on;
          write ordctlr;
          sflClear = *off;

          rrn = 0;
          setll ordid orddtl;
          dow rrn < 8;
             reade ordid orddtl;
             if %eof(orddtl);
                leave;
             endif;
             rrn += 1;
             delflag = *blank;
             write ordlin2;
          enddo;
       endsr;

       //****************************************************************
       //    SUBROUTINE - SaveChanges                                   *
       //    PURPOSE    - Validate every changed/removed line, then      *
       //                 apply the changes. If nothing would be left   *
       //                 on the order, ask for a second F5 before       *
       //                 deleting the order entirely.                 *
       //****************************************************************
       begsr SaveChanges;
          errFound = *off;
          remainingCount = 0;

          for rrn = 1 to 8;
             chain rrn ordlin2;
             if %found(ordchg) and itemid <> *blank and not errFound;
                newQty = qtyord;
                isDelete = (delflag <> *blank);
                chain ordlkey orddrec;
                if %found(orddtl) and not isDelete;
                   if newQty <= 0;
                      errtxt = 'QUANTITY MUST BE GREATER THAN ZERO - '
                             + 'OR MARK D TO REMOVE';
                      errFound = *on;
                   elseif newQty < qtyshp;
                      errtxt = 'CANNOT REDUCE BELOW QUANTITY ALREADY SHIPPED';
                      errFound = *on;
                   else;
                      remainingCount += 1;
                   endif;
                endif;
             endif;
          endfor;

          if errFound;
             pendingDelete = *off;
             leavesr;
          endif;

          if remainingCount = 0 and not pendingDelete;
             errtxt = 'ALL LINES REMOVED - PRESS F5 TO DELETE ORDER, '
                    + 'F12 CANCEL';
             pendingDelete = *on;
             leavesr;
          endif;

          for rrn = 1 to 8;
             chain rrn ordlin2;
             if %found(ordchg) and itemid <> *blank;
                newQty = qtyord;
                isDelete = (delflag <> *blank);
                chain ordlkey orddrec;
                if %found(orddtl);
                   if isDelete;
                      delete orddrec;
                   else;
                      qtyord = newQty;
                      update orddrec;
                   endif;
                endif;
             endif;
          endfor;

          pendingDelete = *off;

          if remainingCount = 0;
             chain ordid omlrec1;
             if %found(ordmstl1);
                delete omlrec1;
             endif;
             errtxt = 'ORDER ' + %char(ordid) + ' DELETED - NO LINES REMAINED';
             orderDeleted = *on;
          else;
             errtxt = 'ORDER ' + %char(ordid) + ' UPDATED';
             exsr LoadLines;
          endif;
       endsr;

      /end-free
