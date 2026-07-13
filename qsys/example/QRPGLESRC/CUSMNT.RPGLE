      //****************************************************************
      // PROGRAM NAME:   CUSMNT                                        *
      // RELATED FILES:  CUSMSTL1 (LF)                                 *
      //                 MNTMENU  (DSPF)                               *
      // DESCRIPTION:    This program shows a customer master          *
      //                 maintenance program using a workstn file.     *
      //                 This program allows the user to add, update,  *
      //                 delete and display customer records.          *
      //                 PF3 is used to quit the program.              *
      //****************************************************************

     Fcusmstl1  uf a e           k disk
     Fmntmenu   cf   e             workstn sfile(lstsfl:rrn)
     F                                     indds(indicators)

      // Field definitions:

     D indicators      ds
     D   exitKey                       n   overlay(indicators:3)
     D   disableInput                  n   overlay(indicators:4)
     D   addKey                        n   overlay(indicators:5)
     D   updateKey                     n   overlay(indicators:6)
     D   deleteKey                     n   overlay(indicators:7)
     D   displayKey                    n   overlay(indicators:8)
     D   listKey                       n   overlay(indicators:11)
     D   prevKey                       n   overlay(indicators:12)
     D   custExists                    n   overlay(indicators:51)
     D   custNotFound                  n   overlay(indicators:52)
     D   listEmpty                     n   overlay(indicators:58)
     D   sflClear                      n   overlay(indicators:20)
     D   rollupKey                     n   overlay(indicators:95)
     D   moreInd                       n   overlay(indicators:96)

     D pageSize        s              5p 0 inz(13)
     D fillCount       s              5p 0
     D rrn             s              5p 0

      // Key list definitions:

     C     CSTKEY        KLIST
     C                   KFLD                    CUST
           //*****************************************************************
      //       MAINLINE                                                 *
      //*****************************************************************

      /free

       mode = 'DISPLAY';
       exfmt hdrscn;

       // Loop until exit key is pressed
       dow not exitKey;
          if listKey;
             exsr ListSub;
          else;
             exsr SetMaintenanceMode;

             if cust <> 0;
                if mode = 'ADD';
                   exsr AddSub;
                elseif mode = 'UPDATE';
                   exsr UpdateSub;
                elseif mode = 'DELETE';
                   exsr DeleteSub;
                elseif mode = 'DISPLAY';
                   exsr InquirySub;
                endif;
             endif;
          endif;

          exfmt hdrscn;
          custExists   = *off;   // turn off error messages
          CustNotFound = *off;
          listEmpty    = *off;
       enddo;

       *inlr = *on;
       //****************************************************************
       //    SUBROUTINE - AddSub                                        *
       //    PURPOSE    - Add new customer to file                      *
       //****************************************************************
       begsr AddSub;

          // Is customer number already in file?
          chain CstKey cmlrec1;
          if %found(cusmstl1);
             // Customer number is already being used
             custExists = *on;
             leavesr;
          endif;

          // Initialize new customer data
          custExists   = *off;   // turn off error messages
          CustNotFound = *off;
          name = *blank;
          addr1 = *blank;
          addr2 = *blank;
          city = *blank;
          state = *blank;
          zip = 0;

          // Prompt for updated data for this customer record
          exfmt cstbld;

          // If OK, add customer to the customer file
          if not *in12;
             write cmlrec1;
          endif;
       endsr;  // end of subroutine AddSub



       //****************************************************************
       //    SUBROUTINE - UpdateSub                                     *
       //    PURPOSE    - Update customer master record                 *
       //****************************************************************
       begsr UpdateSub;

          // Lookup customer number
          chain cstkey cmlrec1;
          if not %found(cusmstl1);
             // Customer is not found in file
             custNotFound = *on;
             leavesr;
          endif;

          // Display information for this customer
          disableInput = *off;
          exfmt cstinq;
          if not prevKey;
             // Update information in file
             update cmlrec1;
          else;
             // If we don't want to update, at least unlock
             // the record.
             unlock cusmstl1;
          endif;
       endsr;  // end of subroutine UpdateSub;
       //****************************************************************
       //    SUBROUTINE - DeleteSub                                     *
       //    PURPOSE    - Delete customer master record                 *
       //****************************************************************
       begsr DeleteSub;

          // Lookup customer number
          chain cstkey cmlrec1;
          if not %found(cusmstl1);
             // Customer is not found in file
             custNotFound = *on;
             leavesr;
          endif;

          // Display information for this customer
          disableInput = *on;
          exfmt cstinq;
          if not prevKey;
             // Delete customer record
             delete cmlrec1;
          else;
             // If we don't want to delete, at least unlock
             // the record.
             unlock cusmstl1;
          endif;
       endsr;  // end of subroutine DeleteSub



       //****************************************************************
       //    SUBROUTINE - InquirySub                                    *
       //    PURPOSE    - Display customer master record                *
       //****************************************************************
       begsr InquirySub;

          // Lookup customer number
          chain(n) cstkey cmlrec1;  // don't lock record
          if not %found(cusmstl1);
             // Customer is not found in file
             custNotFound = *on;
             leavesr;
          endif;

          // Display information for this customer
          disableInput = *on;
          exfmt cstinq;
       endsr;  // end of subroutine InquirySub;

       //****************************************************************
       //    SUBROUTINE - ListSub                                       *
       //    PURPOSE    - Scrollable list of all customers, loaded a    *
       //                 page at a time (see FillListPage)             *
       //****************************************************************
       begsr ListSub;
          rrn = 0;
          sflClear = *on;
          write lstctl;
          sflClear = *off;

          moreInd = *on;
          setll *loval cusmstl1;
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
       endsr;  // end of subroutine ListSub

       //****************************************************************
       //    SUBROUTINE - FillListPage                                  *
       //    PURPOSE    - Read up to one page's worth of customers in   *
       //                 key order and append them to the subfile,     *
       //                 without re-reading what's already loaded.     *
       //****************************************************************
       begsr FillListPage;
          fillCount = 0;
          dow fillCount < pageSize and moreInd;
             read cusmstl1;
             if %eof(cusmstl1);
                moreInd = *off;
                leave;
             endif;

             rrn = rrn + 1;
             write lstsfl;
             fillCount = fillCount + 1;
          enddo;
       endsr;  // end of subroutine FillListPage

       //****************************************************************
       //    SUBROUTINE - SetMaintenanceMode                            *
       //    PURPOSE    - Set maintenance mode                          *
       //****************************************************************
       begsr SetMaintenanceMode;
          if addKey;
             mode = 'ADD';
          elseif updateKey;
             mode = 'UPDATE';
          elseif deleteKey;
             mode = 'DELETE';
          elseif displayKey;
             mode = 'DISPLAY';
          endif;
       endsr;  // end of subroutine SetMaintenanceMode

      /end-free


