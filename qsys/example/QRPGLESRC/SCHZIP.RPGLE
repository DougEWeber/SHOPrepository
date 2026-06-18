      //****************************************************************
      // PROGRAM NAME:    SCHZIP                                       *
      // RELATED FILES:  CUSMSTL2 (LOGICAL FILE)                       *
      //                 SCHZIPD (WORKSTN FILE)                        *
      // DESCRIPTION:    This program shows a customer master search   *
      //                 program using workstn subfile processing.     *
      //                 This program prompts the user for the zip code*
      //                 and displays the customer master records by   *
      //                 zip code.                                     *
      //                 Roll up key can be used to look at another    *
      //                 page. PF3 us used to quit the program.        *
      //****************************************************************
     Fcusmstl2  if   e           k disk
     Fschzipd   cf   e             workstn sfile(subfile:recnum)
     F                                     indds(indicators)


      // Field definitions:
     D recnum          s              5p 0
     D recordFound     s               n

     D indicators      ds
     D    exitKey                      n   overlay(indicators:3)
     D    restartKey                   n   overlay(indicators:4)
     D    sflClear                     n   overlay(indicators:55)
     D    zipNotFound                  n   overlay(indicators:61)
     D    rollupKey                    n   overlay(indicators:95)

      // Key list definitions:
     C     cstkey        klist
     C                   kfld                    zip
          //*******************************************************************
      //    MAINLINE                                                      *
      //*******************************************************************

      /free

       // Write out initial menu
       write foot1;
       write head;
       exfmt prompt;

       // loop until PF03 is pressed
       dow not exitKey;
          setll cstkey cmlrec2;
          recordFound = %equal(cusmstl2);
          if recordFound;
             exsr ProcessSubfile;
          endif;

          // Quit loop if PF03 was pressed in the subfile display
          if exitKey;
             leave;
          endif;

          // If PF04 was pressed, then redo search with the same
          // zip code.
          if restartKey;
             iter;
          endif;

          // Prompt for new zip code.
          if not recordFound;
             // If we didn't find a zip code, don't write header
             // and footer again
             write foot1;
             write head;
          endif;
          zipNotFound = not recordFound;
          exfmt prompt;
       enddo;

       *inlr = *on;
           //****************************************************************
       //    SUBROUTINE - ProcessSubfile                                *
       //    PURPOSE    - Process subfile and display it                *
       //****************************************************************
       begsr ProcessSubfile;

          // Keep looping while roll up key is pressed
          dou not rollupKey;
             // Do we have more information to add to subfile?
             if not %eof(cusmstl2);
                // Clear and fill subfile with customer data
                exsr ClearSubfile;
                exsr FillSubfile;
             endif;

             // Write out subfile and wait for response
             write foot2;
             exfmt subctl;
          enddo;

       endsr;  // end of subroutine ProcessSubfile



       //****************************************************************
       //    SUBROUTINE - FillSubfile                                   *
       //    PURPOSE    - Fill subfile with customer records matching   *
       //                 specified zip code.                           *
       //****************************************************************
       begsr FillSubfile;

          // Loop through all customer records with specified zip code
          recnum = 0;
          dou %eof(schzipd);
             // Read next record with specified zip code
             reade zip cmlrec2;
             if %eof(cusmstl2);
                // If no more records, we're done
                leavesr;
             endif;

             // Add information about this record to the subfile
             recnum = recnum + 1;
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

      /end-free
