      //****************************************************************
      // PROGRAM NAME:   INVRCV                                        *
      // RELATED FILES:  INVMSTL1 (LF)                                 *
      //                 INVRCVD  (DSPF)                               *
      // DESCRIPTION:    Receive inventory. Prompts for item ID then   *
      //                 accepts quantity received and unit cost.      *
      //                 Updates QTYOH, LSTCST, and decrements QTYOO. *
      //****************************************************************

     Finvmstl1  uf a e           k disk
     Finvrcvd   cf   e             workstn indds(indicators)

     D indicators      ds
     D   exitKey                       n   overlay(indicators:3)
     D   prevKey                       n   overlay(indicators:12)
     D   itemNotFound                  n   overlay(indicators:52)
     D   itemInactv                    n   overlay(indicators:53)
     D   qtyRcvErr                     n   overlay(indicators:55)
     D   cstErr                        n   overlay(indicators:56)

     C     INVKEY        KLIST
     C                   KFLD                    INVID 

      /free

       exfmt hdrscn;

       dow not exitKey;
          itemNotFound = *off;
          itemInactv   = *off;

          chain invkey imlrec1;
          if not %found(invmstl1);
             itemNotFound = *on;
          elseif inactv = 'Y';
             itemInactv = *on;
             unlock invmstl1;
          else;
             qtyrcv    = 0;
             rcvcst    = 0;
             qtyRcvErr = *off;
             cstErr    = *off;

             dow '1';
                exfmt rcvscn;

                if prevKey;
                   unlock invmstl1;
                   leave;
                endif;

                qtyRcvErr = (qtyrcv <= 0);
                cstErr    = (rcvcst <= 0);

                if not qtyRcvErr and not cstErr;
                   qtyoh  = qtyoh + qtyrcv;
                   lstcst = rcvcst;
                   if qtyoo >= qtyrcv;
                      qtyoo = qtyoo - qtyrcv;
                   else;
                      qtyoo = 0;
                   endif;
                   update imlrec1;
                   leave;
                endif;
             enddo;
          endif;

          exfmt hdrscn;
          itemNotFound = *off;
          itemInactv   = *off;
       enddo;

       *inlr = *on;
      /end-free
