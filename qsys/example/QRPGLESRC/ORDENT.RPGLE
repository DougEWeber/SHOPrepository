      //****************************************************************
      // PROGRAM NAME:   ORDENT                                        *
      // RELATED FILES:  CUSMSTL1 (LF), INVMSTL1 (LF), ORDMSTL1 (LF),  *
      //                 ORDDTL (PF), ORDCTL (PF), ORDENT (DSPF)       *
      // DESCRIPTION:    Order entry. Enter a customer and PO on the    *
      //                 header, up to 8 lines (item, quantity ordered, *
      //                 unit price), then F5 to save. The order id is  *
      //                 assigned from ORDCTL under a record lock. Orders*
      //                 are refused for customers in collections.     *
      //****************************************************************

     Fcusmstl1  if   e           k disk
     Finvmstl1  if   e           k disk
     Fordmstl1  uf a e           k disk
     Forddtl    uf a e           k disk
     Fordctl    uf a e           k disk
     Fordent    cf   e             workstn sfile(ordlin:rrn)
     F                                     indds(indicators)

     D indicators      ds
     D   exitKey                       n   overlay(indicators:3)
     D   saveKey                       n   overlay(indicators:5)
     D   cancelKey                     n   overlay(indicators:12)
     D   sflClear                      n   overlay(indicators:20)

     D rrn             s              5p 0
     D lineCount       s              5p 0
     D errFound        s               n
     D i               s              5p 0

      /free

       exsr ClearSfl;

       dow not exitKey and not cancelKey;
          exfmt ordctlr;
          if exitKey or cancelKey;
             leave;
          endif;

          if not saveKey;
             errtxt = *blank;
          endif;

          exsr LookupCust;

          if saveKey;
             exsr SaveOrder;
          endif;
       enddo;

       *inlr = *on;
       return;

       //****************************************************************
       //    SUBROUTINE - LookupCust                                    *
       //    PURPOSE    - Show the customer name next to the number      *
       //****************************************************************
       begsr LookupCust;
          cusname = *blank;
          if cust <> 0;
             chain cust cmlrec1;
             if %found(cusmstl1);
                cusname = name;
             else;
                cusname = 'CUSTOMER NOT ON FILE';
             endif;
          endif;
       endsr;

       //****************************************************************
       //    SUBROUTINE - ClearSfl                                      *
       //    PURPOSE    - Blank the header and the 8 order lines          *
       //****************************************************************
       begsr ClearSfl;
          cust = 0;
          cusname = *blank;
          cuspo = *blank;
          errtxt = *blank;

          sflClear = *on;
          write ordctlr;
          sflClear = *off;

          for i = 1 to 8;
             rrn = i;
             itemid = *blank;
             qtyord = 0;
             price = 0;
             write ordlin;
          endfor;
       endsr;

       //****************************************************************
       //    SUBROUTINE - SaveOrder                                     *
       //    PURPOSE    - Validate the header and lines, then write the  *
       //                 order header and detail lines                 *
       //****************************************************************
       begsr SaveOrder;
          errFound = *off;
          lineCount = 0;

          if cust = 0;
             errtxt = 'CUSTOMER NUMBER REQUIRED';
             leavesr;
          endif;

          chain cust cmlrec1;
          if not %found(cusmstl1);
             errtxt = 'CUSTOMER NOT ON FILE';
             leavesr;
          endif;

          if incoll = 'Y';
             errtxt = 'CUSTOMER IS IN COLLECTIONS - ORDERS NOT ALLOWED';
             leavesr;
          endif;

          for rrn = 1 to 8;
             chain rrn ordlin;
             if itemid <> *blank and not errFound;
                chain itemid imlrec1;
                if not %found(invmstl1) or inactv = 'Y';
                   errtxt = 'ITEM NOT ON FILE OR INACTIVE: ' + %trim(itemid);
                   errFound = *on;
                elseif qtyord <= 0;
                   errtxt = 'QUANTITY MUST BE GREATER THAN ZERO';
                   errFound = *on;
                elseif price <= 0;
                   errtxt = 'UNIT PRICE MUST BE GREATER THAN ZERO';
                   errFound = *on;
                else;
                   lineCount += 1;
                endif;
             endif;
          endfor;

          if errFound;
             leavesr;
          endif;

          if lineCount = 0;
             errtxt = 'ENTER AT LEAST ONE ORDER LINE';
             leavesr;
          endif;

          exsr NextOrderId;

          ordid = nextord;
          orddt = %date();
          ordstat = 'O';
          write omlrec1;

          lineCount = 0;
          for rrn = 1 to 8;
             chain rrn ordlin;
             if itemid <> *blank;
                lineCount += 1;
                line = lineCount;
                qtyshp = 0;
                write orddrec;
             endif;
          endfor;

          exsr ClearSfl;
          errtxt = 'ORDER ' + %char(ordid) + ' SAVED';
       endsr;

       //****************************************************************
       //    SUBROUTINE - NextOrderId                                   *
       //    PURPOSE    - Take the next order id from ORDCTL under a     *
       //                 record lock, creating the control record once *
       //                 if it does not exist yet.                     *
       //****************************************************************
       begsr NextOrderId;
          ctlkey = '1';
          chain ctlkey ordcrec;
          if not %found(ordctl);
             ctlkey = '1';
             nextord = 1;
             write ordcrec;
             chain ctlkey ordcrec;
          endif;
          ordid = nextord;
          nextord += 1;
          update ordcrec;
       endsr;

      /end-free
