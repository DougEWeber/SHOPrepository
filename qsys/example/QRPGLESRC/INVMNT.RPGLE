      //****************************************************************
      // PROGRAM NAME:   INVMNT                                        *
      // RELATED FILES:  INVMSTL1 (LF)                                 *
      //                 INVMNT   (DSPF)                               *
      // DESCRIPTION:    Inventory maintenance. Supports six modes:    *
      //                 ADD    - creates a new item (name/unit only)  *
      //                 UPDATE - changes name and/or unit             *
      //                 INACTV - marks item inactive                  *
      //                 REACTV - reactivates item, optionally zeros   *
      //                          quantity on hand                     *
      //                 VIEW   - displays item info, no changes       *
      //                 LIST   - scrollable list of all items,        *
      //                          loaded a page at a time              *
      //****************************************************************

     Finvmstl1  uf a e           k disk
     Fvndmstl1  if   e           k disk
     Finvmnt    cf   e             workstn sfile(lstsfl:rrn)
     F                                     indds(indicators)

     D indicators      ds
     D   exitKey                       n   overlay(indicators:3)
     D   disableInput                  n   overlay(indicators:4)
     D   addKey                        n   overlay(indicators:5)
     D   updateKey                     n   overlay(indicators:6)
     D   inactvKey                     n   overlay(indicators:7)
     D   reacKey                       n   overlay(indicators:8)
     D   viewKey                       n   overlay(indicators:9)
     D   showZeroQH                    n   overlay(indicators:10)
     D   listKey                       n   overlay(indicators:11)
     D   prevKey                       n   overlay(indicators:12)
     D   itemExists                    n   overlay(indicators:51)
     D   itemNotFound                  n   overlay(indicators:52)
     D   alrInactv                     n   overlay(indicators:53)
     D   alrActv                       n   overlay(indicators:54)
     D   invalidVnd                    n   overlay(indicators:57)
     D   listEmpty                     n   overlay(indicators:58)
     D   sflClear                      n   overlay(indicators:20)
     D   rollupKey                     n   overlay(indicators:95)
     D   moreInd                       n   overlay(indicators:96)

     D pageSize        s              5p 0 inz(13)
     D fillCount       s              5p 0
     D rrn             s              5p 0

     C     INVKEY        KLIST
     C                   KFLD                    INVID

     C     VNDKY         KLIST
     C                   KFLD                    VNDID

      /free

       mode = 'UPDATE';
       exfmt hdrscn;

       dow not exitKey;
          if listKey;
             exsr ListSub;
          else;
             exsr SetMode;

             if invid <> *blank;
                if mode = 'ADD';
                   exsr AddSub;
                elseif mode = 'UPDATE';
                   exsr UpdateSub;
                elseif mode = 'INACTV';
                   exsr InactvSub;
                elseif mode = 'REACTV';
                   exsr ReacSub;
                elseif mode = 'VIEW';
                   exsr ViewSub;
                endif;
             endif;
          endif;

          exfmt hdrscn;
          itemExists   = *off;
          itemNotFound = *off;
          alrInactv    = *off;
          alrActv      = *off;
          invalidVnd   = *off;
          listEmpty    = *off;
       enddo;

       *inlr = *on;

       //****************************************************************
       //    SUBROUTINE - AddSub                                        *
       //    PURPOSE    - Add new inventory item                        *
       //****************************************************************
       begsr AddSub;
          chain invkey imlrec1;
          if %found(invmstl1);
             itemExists = *on;
             leavesr;
          endif;

          invdsc     = *blank;
          invunt     = *blank;
          vndid      = 0;
          invalidVnd = *off;

          dow '1';
             exfmt itmcrt;
             if prevKey;
                leavesr;
             endif;

             invalidVnd = *off;
             if vndid > 0;
                chain(n) vndky vmlrec1;
                if not %found(vndmstl1);
                   invalidVnd = *on;
                endif;
             endif;

             if not invalidVnd;
                qtyoh  = 0;
                qtyip  = 0;
                lstcst = 0;
                qtyoo  = 0;
                inactv = 'N';
                write imlrec1;
                leavesr;
             endif;
          enddo;
       endsr;

       //****************************************************************
       //    SUBROUTINE - UpdateSub                                     *
       //    PURPOSE    - Update item name and unit only                *
       //****************************************************************
       begsr UpdateSub;
          chain invkey imlrec1;
          if not %found(invmstl1);
             itemNotFound = *on;
             leavesr;
          endif;

          disableInput = *off;
          showZeroQH   = *off;
          exfmt itminq;
          if not prevKey;
             update imlrec1;
          else;
             unlock invmstl1;
          endif;
       endsr;

       //****************************************************************
       //    SUBROUTINE - InactvSub                                     *
       //    PURPOSE    - Inactivate an inventory item                  *
       //****************************************************************
       begsr InactvSub;
          chain invkey imlrec1;
          if not %found(invmstl1);
             itemNotFound = *on;
             leavesr;
          endif;

          if inactv = 'Y';
             alrInactv = *on;
             unlock invmstl1;
             leavesr;
          endif;

          disableInput = *on;
          showZeroQH   = *off;
          exfmt itminq;
          if not prevKey;
             inactv = 'Y';
             update imlrec1;
          else;
             unlock invmstl1;
          endif;
       endsr;

       //****************************************************************
       //    SUBROUTINE - ReacSub                                       *
       //    PURPOSE    - Reactivate an inventory item                  *
       //****************************************************************
       begsr ReacSub;
          chain invkey imlrec1;
          if not %found(invmstl1);
             itemNotFound = *on;
             leavesr;
          endif;

          if inactv = 'N';
             alrActv = *on;
             unlock invmstl1;
             leavesr;
          endif;

          disableInput = *on;
          showZeroQH   = *on;
          zeroqh       = 'N';
          exfmt itminq;
          if not prevKey;
             inactv = 'N';
             if zeroqh = 'Y' or zeroqh = 'y';
                qtyoh = 0;
             endif;
             update imlrec1;
          else;
             unlock invmstl1;
          endif;
       endsr;

       //****************************************************************
       //    SUBROUTINE - SetMode                                       *
       //    PURPOSE    - Set maintenance mode from PF key              *
       //****************************************************************
       begsr SetMode;
          if addKey;
             mode = 'ADD';
          elseif updateKey;
             mode = 'UPDATE';
          elseif inactvKey;
             mode = 'INACTV';
          elseif reacKey;
             mode = 'REACTV';
          elseif viewKey;
             mode = 'VIEW';
          endif;
       endsr;

       //****************************************************************
       //    SUBROUTINE - ViewSub                                        *
       //    PURPOSE    - Display item info, no changes allowed          *
       //****************************************************************
       begsr ViewSub;
          chain(n) invkey imlrec1;
          if not %found(invmstl1);
             itemNotFound = *on;
             leavesr;
          endif;

          disableInput = *on;
          showZeroQH   = *off;
          exfmt itminq;
       endsr;

       //****************************************************************
       //    SUBROUTINE - ListSub                                       *
       //    PURPOSE    - Scrollable list of all inventory items,       *
       //                 loaded a page at a time (see FillListPage)     *
       //****************************************************************
       begsr ListSub;
          rrn = 0;
          sflClear = *on;
          write lstctl;
          sflClear = *off;

          moreInd = *on;
          setll *loval invmstl1;
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
       //    PURPOSE    - Read up to one page's worth of inventory      *
       //                 items in key order and append them to the     *
       //                 subfile, without re-reading what's already    *
       //                 loaded.                                       *
       //****************************************************************
       begsr FillListPage;
          fillCount = 0;
          dow fillCount < pageSize and moreInd;
             read invmstl1;
             if %eof(invmstl1);
                moreInd = *off;
                leave;
             endif;

             rrn = rrn + 1;
             write lstsfl;
             fillCount = fillCount + 1;
          enddo;
       endsr;

      /end-free
