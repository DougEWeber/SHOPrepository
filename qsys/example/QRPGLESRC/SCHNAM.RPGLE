
      //****************************************************************
      // PROGRAM NAME:   SCHNAM                                        *
      // RELATED FILES:  CUSMSTL3 (LOGICAL FILE)                       *
      //                 SCHNAMD (WORKSTN FILE)                        *
      // DESCRIPTION:    This program shows a customer master search   *
      //                 program using workstn subfile processing.     *
      //                 This program prompts the user for the customer*
      //                 name and uses it to position the cusmstl3     *
      //                 file by the setll operation. Then it displays *
      //                 the records using subfiles.                   *
      //                 To fill another page, press the rollup key.   *
      //                 To display customer detail, enter 'X' beside  *
      //                 that customer and press enter.                *
      //                 To quit the program, press PF3.               *
      //****************************************************************

     Fcusmstl3  if   e           k disk
     Fschnamd   cf   e             workstn sfile(subfile:recnum)
     F                                     indds(indicators)

      // Field definitions:
     D recnum          s              5p 0

     D indicators      ds
     D    exitKey                      n   overlay(indicators:3)
     D    restartKey                   n   overlay(indicators:4)
     D    sflClear                     n   overlay(indicators:55)
     D    rollupKey                    n   overlay(indicators:95)

      // Key list definitions:
     C     cstkey        klist
     C                   kfld                    srcnam
     C     namekey       klist
     C                   kfld                    name
           //******************************************************************
      //   MAINLINE                                                      *
      //******************************************************************

      /free

       write foot1;
       write head;
       exfmt prompt;

       // loop until exit key is pressed
       dow not exitKey;
          setll cstkey cusrec;
          exsr ProcessSubfile;
          exsr DisplayCustomerDetail;

          // If exit key pressed in subfile display, leave loop
          if exitKey;
             leave;
          endif;

          // If restart key pressed in subfile display, repeat loop
          if restartKey;
             iter;
          endif;

          write foot1;
          write head;
          exfmt prompt;

       enddo;

       *inlr = *on;



       //*****************************************************************
       //  SUBROUTINE - ProcessSubfile                                   *
       //  PURPOSE    - Process subfile and display                      *
       //*****************************************************************
       begsr ProcessSubfile;

          // Keep looping while roll up key is pressed
          dou not rollupKey;
             // Do we have more information to add to subfile?
             if not %eof(cusmstl3);
                // Clear and fill subfile with customer data
                exsr ClearSubfile;
                exsr FillSubfile;
             endif;

             // Write out subfile and wait for response
             write foot2;
             exfmt subctl;
          enddo;

       endsr;  // end of subroutine ProcessSubfile

       //******************************************************************
       //   SUBROUTINE - FillSubfile                                      *
       //   PURPOSE    - Fill subfile                                     *
       //******************************************************************
       begsr FillSubfile;

          // Loop through all customer records
          recnum = 0;
          dou %eof(schnamd);
             // Read next record
             read cusrec;
             if %eof(cusmstl3);
                // If no more records, we're done
                leavesr;
             endif;

             // Add information about this record to the subfile
             recnum = recnum + 1;
             sel = *blank;
             write subfile;
          enddo;

       endsr;  // end of subroutine FillSubfile;



       //****************************************************************
       //    SUBROUTINE - ClearSubfile                                  *
       //    PURPOSE    - Clear subfile records                         *
       //****************************************************************
       begsr ClearSubfile;

          sflClear = *on;
          write subctl;
          sflClear = *off;

       endsr;  // end of subroutine ClearSubfile
           //*****************************************************************
       //  SUBROUTINE - DisplayCustomerDetail                            *
       //  PURPOSE    - Display selected customer records                *
       //*****************************************************************
       begsr DisplayCustomerDetail;

          // Loop through all changed record in subfile
          readc subfile;
          dow not %eof(schnamd);
             // Restart the display of requested customer records
             restartKey = *on;

             // Lookup customer record and display it
             chain namekey cusrec;
             exfmt cusdsp;

             // If exit key pressed, exit loop
             if exitKey;
                leave;
             endif;

             readc subfile;
          enddo;


       endsr;  // end of subroutine ChangeSubfile

      /end-free
