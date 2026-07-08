      //****************************************************************
      // PROGRAM NAME:   VNDMNT                                        *
      // RELATED FILES:  VNDMSTL1 (LF)                                 *
      //                 VNDMNT   (DSPF)                               *
      // DESCRIPTION:    Vendor maintenance. Supports four modes:      *
      //                 ADD    - creates a new vendor (auto-assigns   *
      //                          vendor ID)                           *
      //                 UPDATE - changes vendor info and/or amt owed  *
      //                 INACTV - marks vendor inactive                *
      //                 REACTV - reactivates vendor                   *
      //****************************************************************

     Fvndmstl1  uf a e           k disk
     Fvndmnt    cf   e             workstn indds(indicators)

     D indicators      ds
     D   exitKey                       n   overlay(indicators:3)
     D   disableInput                  n   overlay(indicators:4)
     D   addKey                        n   overlay(indicators:5)
     D   updateKey                     n   overlay(indicators:6)
     D   inactvKey                     n   overlay(indicators:7)
     D   reacKey                       n   overlay(indicators:8)
     D   viewKey                       n   overlay(indicators:9)
     D   prevKey                       n   overlay(indicators:12)
     D   vndNotFound                   n   overlay(indicators:52)
     D   alrInactv                     n   overlay(indicators:53)
     D   alrActv                       n   overlay(indicators:54)

     D nextId          s              7  0

     C     VNDKEY        KLIST
     C                   KFLD                    VNDID

      /free

       mode = 'UPDATE';
       exfmt hdrscn;

       dow not exitKey;
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

          exfmt hdrscn;
          vndNotFound = *off;
          alrInactv   = *off;
          alrActv     = *off;
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
