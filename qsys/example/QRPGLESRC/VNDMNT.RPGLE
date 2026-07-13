      //****************************************************************
      // PROGRAM NAME:   VNDMNT                                        *
      // RELATED FILES:  VNDMSTL1 (LF)                                 *
      //                 VNDMNT   (DSPF)                               *
      // DESCRIPTION:    Vendor maintenance. Supports five modes:       *
      //                 ADD    - creates a new vendor (auto-assigns   *
      //                          vendor ID)                           *
      //                 UPDATE - changes vendor info and/or amt owed  *
      //                 INACTV - marks vendor inactive                *
      //                 REACTV - reactivates vendor                   *
      //                 LIST   - scrollable list of all vendors,      *
      //                          loaded a page at a time              *
      //****************************************************************

     Fvndmstl1  uf a e           k disk
     Fvndmnt    cf   e             workstn sfile(lstsfl:rrn)
     F                                     indds(indicators)

     D indicators      ds
     D   exitKey                       n   overlay(indicators:3)
     D   disableInput                  n   overlay(indicators:4)
     D   addKey                        n   overlay(indicators:5)
     D   updateKey                     n   overlay(indicators:6)
     D   inactvKey                     n   overlay(indicators:7)
     D   reacKey                       n   overlay(indicators:8)
     D   viewKey                       n   overlay(indicators:9)
     D   listKey                       n   overlay(indicators:11)
     D   prevKey                       n   overlay(indicators:12)
     D   vndNotFound                   n   overlay(indicators:52)
     D   alrInactv                     n   overlay(indicators:53)
     D   alrActv                       n   overlay(indicators:54)
     D   listEmpty                     n   overlay(indicators:58)
     D   sflClear                      n   overlay(indicators:20)
     D   rollupKey                     n   overlay(indicators:95)
     D   moreInd                       n   overlay(indicators:96)

     D nextId          s              7  0
     D pageSize        s              5p 0 inz(13)
     D fillCount       s              5p 0
     D rrn             s              5p 0

     C     VNDKEY        KLIST
     C                   KFLD                    VNDID

      /free

       mode = 'UPDATE';
       exfmt hdrscn;

       dow not exitKey;
          if listKey;
             exsr ListSub;
          else;
             exsr SetMode;

             if mode = 'ADD';
                exsr AddSub;
             elseif vndid > 0;
                if mode = 'UPDATE';
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
          vndNotFound = *off;
          alrInactv   = *off;
          alrActv     = *off;
          listEmpty   = *off;
       enddo;

       *inlr = *on;

       //****************************************************************
       //    SUBROUTINE - AddSub                                        *
       //    PURPOSE    - Add new vendor (auto-assign vendor ID)        *
       //****************************************************************
       begsr AddSub;
          setll *hival vmlrec1;
          readp(n) vmlrec1;
          if %found(vndmstl1);
             nextId = vndid + 1;
          else;
             nextId = 1;
          endif;

          vndid  = nextId;
          vndnam = *blank;
          vndad1 = *blank;
          vndcty = *blank;
          vndst  = *blank;
          vndzip = *blank;
          vnd30  = 0;
          vnd60  = 0;
          vnd90  = 0;
          vndowe = 0;

          exfmt itmcrt;

          if not prevKey;
             vninactv = 'N';
             write vmlrec1;
          endif;
       endsr;

       //****************************************************************
       //    SUBROUTINE - UpdateSub                                     *
       //    PURPOSE    - Update vendor info and/or amount owed         *
       //****************************************************************
       begsr UpdateSub;
          chain vndkey vmlrec1;
          if not %found(vndmstl1);
             vndNotFound = *on;
             leavesr;
          endif;

          disableInput = *off;
          exfmt itminq;
          if not prevKey;
             update vmlrec1;
          else;
             unlock vndmstl1;
          endif;
       endsr;

       //****************************************************************
       //    SUBROUTINE - InactvSub                                     *
       //    PURPOSE    - Inactivate a vendor                           *
       //****************************************************************
       begsr InactvSub;
          chain vndkey vmlrec1;
          if not %found(vndmstl1);
             vndNotFound = *on;
             leavesr;
          endif;

          if vninactv = 'Y';
             alrInactv = *on;
             unlock vndmstl1;
             leavesr;
          endif;

          disableInput = *on;
          exfmt itminq;
          if not prevKey;
             vninactv = 'Y';
             update vmlrec1;
          else;
             unlock vndmstl1;
          endif;
       endsr;

       //****************************************************************
       //    SUBROUTINE - ReacSub                                       *
       //    PURPOSE    - Reactivate a vendor                           *
       //****************************************************************
       begsr ReacSub;
          chain vndkey vmlrec1;
          if not %found(vndmstl1);
             vndNotFound = *on;
             leavesr;
          endif;

          if vninactv = 'N';
             alrActv = *on;
             unlock vndmstl1;
             leavesr;
          endif;

          disableInput = *on;
          exfmt itminq;
          if not prevKey;
             vninactv = 'N';
             update vmlrec1;
          else;
             unlock vndmstl1;
          endif;
       endsr;

       //****************************************************************
       //    SUBROUTINE - ViewSub                                       *
       //    PURPOSE    - Display vendor record (read-only)             *
       //****************************************************************
       begsr ViewSub;
          chain(n) vndkey vmlrec1;
          if not %found(vndmstl1);
             vndNotFound = *on;
             leavesr;
          endif;

          disableInput = *on;
          exfmt itminq;
       endsr;

       //****************************************************************
       //    SUBROUTINE - ListSub                                       *
       //    PURPOSE    - Scrollable list of all vendors, loaded a      *
       //                 page at a time (see FillListPage)             *
       //****************************************************************
       begsr ListSub;
          rrn = 0;
          sflClear = *on;
          write lstctl;
          sflClear = *off;

          moreInd = *on;
          setll *loval vndmstl1;
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
       //    PURPOSE    - Read up to one page's worth of vendors in     *
       //                 key order and append them to the subfile,     *
       //                 without re-reading what's already loaded.     *
       //****************************************************************
       begsr FillListPage;
          fillCount = 0;
          dow fillCount < pageSize and moreInd;
             read vndmstl1;
             if %eof(vndmstl1);
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

      /end-free
