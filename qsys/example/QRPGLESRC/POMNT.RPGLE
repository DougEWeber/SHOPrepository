      //****************************************************************
      // PROGRAM NAME:   POMNT                                         *
      // RELATED FILES:  PORMSTL1 (LF)                                 *
      //                 VNDMSTL1 (LF)                                 *
      //                 POMNT    (DSPF)                                *
      // DESCRIPTION:    Purchase order maintenance. Supports four      *
      //                 modes:                                         *
      //                 ADD    - creates a new PO (auto-assigns PO     *
      //                          number), validates vendor             *
      //                 CLOSE  - marks PO closed                       *
      //                 REOPEN - reopens a closed PO                   *
      //                 VIEW   - displays PO info, no changes          *
      //****************************************************************

     Fpormstl1  uf a e           k disk
     Fvndmstl1  if   e           k disk
     Fpomnt     cf   e             workstn indds(indicators)

     D indicators      ds
     D   exitKey                       n   overlay(indicators:3)
     D   addKey                        n   overlay(indicators:5)
     D   closeKey                      n   overlay(indicators:6)
     D   reopenKey                     n   overlay(indicators:7)
     D   viewKey                       n   overlay(indicators:8)
     D   prevKey                       n   overlay(indicators:12)
     D   poNotFound                    n   overlay(indicators:52)
     D   alrClosed                     n   overlay(indicators:53)
     D   alrOpen                       n   overlay(indicators:54)
     D   invalidVnd                    n   overlay(indicators:57)

     D nextNbr         s              7  0

     C     PONBRKEY      KLIST
     C                   KFLD                    PONBR

     C     VNDKY         KLIST
     C                   KFLD                    VNDID

      /free

       mode = 'VIEW';
       exfmt hdrscn;

       dow not exitKey;
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

          exfmt hdrscn;
          poNotFound = *off;
          alrClosed  = *off;
          alrOpen    = *off;
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
