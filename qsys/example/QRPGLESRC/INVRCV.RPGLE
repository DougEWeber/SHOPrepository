      //****************************************************************
      // PROGRAM NAME:   INVRCV                                        *
      // RELATED FILES:  INVMSTL1 (LF)                                 *
      //                 PORMSTL1 (LF)                                 *
      //                 RCVTRNL1 (LF)                                 *
      //                 INVRCVD  (DSPF)                               *
      // DESCRIPTION:    Receive inventory. Prompts for item ID then   *
      //                 accepts quantity received, unit cost, PO      *
      //                 number, invoice number, and quantity ordered. *
      //                 Updates QTYOH, LSTCST, and decrements QTYOO,  *
      //                 and logs a receiving transaction to RCVTRN.   *
      //****************************************************************

     Finvmstl1  uf a e           k disk
     Fvndmstl1  uf   e           k disk
     Fpormstl1  if   e           k disk
     Frcvtrnl1  o    e             disk
     Finvrcvd   cf   e             workstn indds(indicators)

     D indicators      ds
     D   exitKey                       n   overlay(indicators:3)
     D   prevKey                       n   overlay(indicators:12)
     D   itemNotFound                  n   overlay(indicators:52)
     D   itemInactv                    n   overlay(indicators:53)
     D   qtyRcvErr                     n   overlay(indicators:55)
     D   cstErr                        n   overlay(indicators:56)
     D   invalidPO                     n   overlay(indicators:58)

       dcl-ds pgmSts psds;
         jobUser char(10) pos(254);
       end-ds;

     C     INVKEY        KLIST
     C                   KFLD                    INVID

     C     VNDKY         KLIST
     C                   KFLD                    VNDID

     C     PONBRKEY      KLIST
     C                   KFLD                    PONBR

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
             ponbr     = 0;
             vndinv    = *blank;
             rtqord    = 0;
             chkusr    = %trim(jobUser);
             qtyRcvErr = *off;
             cstErr    = *off;
             invalidPO = *off;

             dow '1';
                exfmt rcvscn;

                if prevKey;
                   unlock invmstl1;
                   leave;
                endif;

                qtyRcvErr = (qtyrcv <= 0);
                cstErr    = (rcvcst <= 0);

                invalidPO = *on;
                if ponbr > 0;
                   chain(n) ponbrkey pmlrec1;
                   if %found(pormstl1) and postat = 'O';
                      invalidPO = *off;
                   endif;
                endif;

                if not qtyRcvErr and not cstErr and not invalidPO;
                   qtyoh  = qtyoh + qtyrcv;
                   lstcst = rcvcst;
                   if qtyoo >= qtyrcv;
                      qtyoo = qtyoo - qtyrcv;
                   else;
                      qtyoo = 0;
                   endif;
                   update imlrec1;
                   if vndid > 0;
                      chain vndky vmlrec1;
                      if %found(vndmstl1);
                         vndowe = vndowe + (qtyrcv * rcvcst);
                         update vmlrec1;
                      endif;
                   endif;

                   rcvdt  = %date();
                   rcvtm  = %time();
                   rtqrcv = qtyrcv;
                   write rtlrec1;
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
