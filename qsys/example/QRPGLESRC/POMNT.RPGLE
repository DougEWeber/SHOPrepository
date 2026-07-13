      //****************************************************************
      // PROGRAM NAME:   POMNT                                         *
      // RELATED FILES:  PORMSTL1 (LF)                                 *
      //                 VNDMSTL1 (LF)                                 *
      //                 POMNT    (DSPF)                                *
      // DESCRIPTION:    Purchase order maintenance. Supports five      *
      //                 modes:                                         *
      //                 ADD    - creates a new PO (auto-assigns PO     *
      //                          number), validates vendor             *
      //                 CLOSE  - marks PO closed                       *
      //                 REOPEN - reopens a closed PO                   *
      //                 VIEW   - displays PO info, no changes          *
      //                 LIST   - scrollable list of all POs, loaded    *
      //                          a page at a time                      *
      //****************************************************************

     Fpormstl1  uf a e           k disk
     Fvndmstl1  if   e           k disk
     Fpomnt     cf   e             workstn sfile(lstsfl:rrn)
     F                                     indds(indicators)

     D indicators      ds
     D   exitKey                       n   overlay(indicators:3)
     D   addKey                        n   overlay(indicators:5)
     D   closeKey                      n   overlay(indicators:6)
     D   reopenKey                     n   overlay(indicators:7)
     D   viewKey                       n   overlay(indicators:8)
     D   listKey                       n   overlay(indicators:11)
     D   prevKey                       n   overlay(indicators:12)
     D   poNotFound                    n   overlay(indicators:52)
     D   alrClosed                     n   overlay(indicators:53)
     D   alrOpen                       n   overlay(indicators:54)
     D   invalidVnd                    n   overlay(indicators:57)
     D   listEmpty                     n   overlay(indicators:58)
     D   sflClear                      n   overlay(indicators:20)
     D   rollupKey                     n   overlay(indicators:95)
     D   moreInd                       n   overlay(indicators:96)

     D nextNbr         s              7  0
     D pageSize        s              5p 0 inz(13)
     D fillCount       s              5p 0
     D rrn             s              5p 0

     C     PONBRKEY      KLIST
     C                   KFLD                    PONBR

     C     VNDKY         KLIST
     C                   KFLD                    VNDID

      /free

       mode = 'VIEW';
       exfmt hdrscn;

       dow not exitKey;
          if listKey;
             exsr ListSub;
          else;
             exsr SetMode;

             if mode = 'ADD';
                exsr AddSub;
             elseif ponbr > 0;
                if mode = 'CLOSE';
                   exsr CloseSub;
                elseif mode = 'REOPEN';
                   exsr ReopenSub;
                elseif mode = 'VIEW';
                   exsr ViewSub;
                endif;
             endif;
          endif;

          exfmt hdrscn;
          poNotFound = *off;
          alrClosed  = *off;
          alrOpen    = *off;
          listEmpty  = *off;
       enddo;

       *inlr = *on;

       //****************************************************************
       //    SUBROUTINE - AddSub                                        *
       //    PURPOSE    - Add new purchase order (auto-assign PO nbr)   *
       //****************************************************************
       begsr AddSub;
          setll *hival pmlrec1;
          readp(n) pmlrec1;
          if %found(pormstl1);
             nextNbr = ponbr + 1;
          else;
             nextNbr = 1;
          endif;

          ponbr      = nextNbr;
          vndid      = 0;
          invalidVnd = *off;

          dow '1';
             exfmt pocrt;
             if prevKey;
                leavesr;
             endif;

             invalidVnd = *off;
             chain(n) vndky vmlrec1;
             if not %found(vndmstl1);
                invalidVnd = *on;
             endif;

             if not invalidVnd;
                postat = 'O';
                write pmlrec1;
                leavesr;
             endif;
          enddo;
       endsr;

       //****************************************************************
       //    SUBROUTINE - CloseSub                                      *
       //    PURPOSE    - Close a purchase order                       *
       //****************************************************************
       begsr CloseSub;
          chain ponbrkey pmlrec1;
          if not %found(pormstl1);
             poNotFound = *on;
             leavesr;
          endif;

          if postat = 'C';
             alrClosed = *on;
             unlock pormstl1;
             leavesr;
          endif;

          exfmt poinq;
          if not prevKey;
             postat = 'C';
             update pmlrec1;
          else;
             unlock pormstl1;
          endif;
       endsr;

       //****************************************************************
       //    SUBROUTINE - ReopenSub                                     *
       //    PURPOSE    - Reopen a closed purchase order                *
       //****************************************************************
       begsr ReopenSub;
          chain ponbrkey pmlrec1;
          if not %found(pormstl1);
             poNotFound = *on;
             leavesr;
          endif;

          if postat = 'O';
             alrOpen = *on;
             unlock pormstl1;
             leavesr;
          endif;

          exfmt poinq;
          if not prevKey;
             postat = 'O';
             update pmlrec1;
          else;
             unlock pormstl1;
          endif;
       endsr;

       //****************************************************************
       //    SUBROUTINE - ViewSub                                       *
       //    PURPOSE    - Display PO info, no changes allowed           *
       //****************************************************************
       begsr ViewSub;
          chain(n) ponbrkey pmlrec1;
          if not %found(pormstl1);
             poNotFound = *on;
             leavesr;
          endif;

          exfmt poinq;
       endsr;

       //****************************************************************
       //    SUBROUTINE - ListSub                                       *
       //    PURPOSE    - Scrollable list of all purchase orders,       *
       //                 loaded a page at a time (see FillListPage)     *
       //****************************************************************
       begsr ListSub;
          rrn = 0;
          sflClear = *on;
          write lstctl;
          sflClear = *off;

          moreInd = *on;
          setll *loval pormstl1;
          exsr FillListPage;

          if rrn = 0;
             // No records were ever written, so the subfile was never
             // activated -- exfmt-ing it here would fail with "subfile
             // not active". Show a message on HDRSCN instead.
             listEmpty = *on;
             leavesr;
          endif;

          dow '1';
             exfmt lstctl;
             if prevKey;
                leave;
             endif;

             if rollupKey and moreInd;
                exsr FillListPage;
             endif;
          enddo;
       endsr;

       //****************************************************************
       //    SUBROUTINE - FillListPage                                  *
       //    PURPOSE    - Read up to one page's worth of purchase       *
       //                 orders in key order and append them to the    *
       //                 subfile, without re-reading what's already    *
       //                 loaded.                                       *
       //****************************************************************
       begsr FillListPage;
          fillCount = 0;
          dow fillCount < pageSize and moreInd;
             read pormstl1;
             if %eof(pormstl1);
                moreInd = *off;
                leave;
             endif;

             rrn = rrn + 1;
             write lstsfl;
             fillCount = fillCount + 1;
          enddo;
       endsr;

       //****************************************************************
       //    SUBROUTINE - SetMode                                       *
       //    PURPOSE    - Set maintenance mode from PF key              *
       //****************************************************************
       begsr SetMode;
          if addKey;
             mode = 'ADD';
          elseif closeKey;
             mode = 'CLOSE';
          elseif reopenKey;
             mode = 'REOPEN';
          elseif viewKey;
             mode = 'VIEW';
          endif;
       endsr;

      /end-free
