      //****************************************************************
      // PROGRAM NAME:   DATACHURN                                      *
      // RELATED FILES:  CUSMSTL1, VNDMSTL1, INVMSTL1, PORMSTL1,        *
      //                 ORDMSTL1                                       *
      // DESCRIPTION:    Load/soak-test utility. Continuously creates,  *
      //                 modifies, and deletes records across the       *
      //                 customer, vendor, inventory, purchase-order,   *
      //                 and order files, each at its own tick          *
      //                 frequency -- orders churn every tick (fastest),*
      //                 the rest less often. Batch program, no display *
      //                 file; meant to be run as a plain CALL, e.g.    *
      //                 against SHOPLIVE by having it first/only in    *
      //                 the job's *LIBL (this program never hardcodes  *
      //                 a library -- same convention as every other    *
      //                 program in this app).                          *
      //                                                                 *
      //                 Every record this program creates gets an ID   *
      //                 in a high, dedicated range (customer 90000+,   *
      //                 vendor/PO/order 900000+, item "CH" + 7 digits) *
      //                 so it never collides with real or seeded test  *
      //                 data -- modify/delete only ever act on records *
      //                 this run itself created (tracked in-memory),   *
      //                 never on pre-existing rows.                    *
      //                                                                 *
      //                 Parameters (both optional):                    *
      //                   1 (10i 0): number of ticks to run.            *
      //                      omitted/0 = run until the job is           *
      //                      ended/cancelled (a very large loop bound,  *
      //                      not truly infinite).                       *
      //                   2 (10i 0): seconds to delay between ticks.    *
      //                      omitted/0 defaults to 2.                   *
      //****************************************************************

     Fcusmstl1  uf a e           k disk
     Fvndmstl1  uf a e           k disk
     Finvmstl1  uf a e           k disk
     Fpormstl1  uf a e           k disk
     Fordmstl1  uf a e           k disk

       dcl-pi *n;
         pTicks     int(10) const options(*nopass);
         pDelaySec  int(10) const options(*nopass);
       end-pi;

       dcl-pr QCmdExc extpgm('QCMDEXC');
         command    char(200) const;
         cmdLength  packed(15:5) const;
       end-pr;

      // Tick frequencies -- order churns every tick (most frequent);
      // everything else churns less often (larger number = slower).
       dcl-c FREQ_ORDER 1;
       dcl-c FREQ_PO 3;
       dcl-c FREQ_INV 4;
       dcl-c FREQ_VND 5;
       dcl-c FREQ_CUST 6;

       dcl-c MAXTRACK 200;
       dcl-c INFINITE_TICKS 999999999;

      // In-memory ID tracking (per file) so modify/delete only ever
      // touch records this run created itself.
       dcl-s custIds packed(5:0) dim(200);
       dcl-s custCount int(10) inz(0);
       dcl-s vndIds packed(7:0) dim(200);
       dcl-s vndCount int(10) inz(0);
       dcl-s invIds char(10) dim(200);
       dcl-s invCount int(10) inz(0);
       dcl-s poIds packed(7:0) dim(200);
       dcl-s poCount int(10) inz(0);
       dcl-s ordIds packed(7:0) dim(200);
       dcl-s ordCount int(10) inz(0);

      // Next-id counters, seeded from time of day so back-to-back runs
      // don't collide with each other either.
       dcl-s nextCust packed(5:0);
       dcl-s nextVnd packed(7:0);
       dcl-s nextInvSeq packed(7:0);
       dcl-s nextPo packed(7:0);
       dcl-s nextOrd packed(7:0);

       dcl-s tickCount int(10);
       dcl-s runTicks int(10);
       dcl-s delaySec int(10);

      // Small native pseudo-random generator (Lehmer/MINSTD LCG) --
      // deliberately not calling out to the C library's rand()/srand(),
      // to avoid any binding-directory uncertainty at build time. Not
      // cryptographic, fine for test-data variety.
       dcl-s gSeed packed(15:0);
       dcl-s randMax packed(15:0);
       dcl-s randResult packed(15:0);

       dcl-s action int(10);
       dcl-s idx int(10);
       dcl-s dlyCmd char(50);

       dcl-s custKey packed(5:0);
       dcl-s vndKey packed(7:0);
       dcl-s invKey char(10);
       dcl-s poKey packed(7:0);
       dcl-s ordKey packed(7:0);

     C     CUSTKY        KLIST
     C                   KFLD                    custKey
     C     VNDKY         KLIST
     C                   KFLD                    vndKey
     C     INVKY         KLIST
     C                   KFLD                    invKey
     C     POKY          KLIST
     C                   KFLD                    poKey
     C     ORDKY         KLIST
     C                   KFLD                    ordKey

      /free

       if %parms >= 1;
          runTicks = pTicks;
       else;
          runTicks = 0;
       endif;
       if runTicks <= 0;
          runTicks = INFINITE_TICKS;
       endif;

       if %parms >= 2;
          delaySec = pDelaySec;
       else;
          delaySec = 0;
       endif;
       if delaySec <= 0;
          delaySec = 2;
       endif;

       exsr InitRandom;
       exsr InitCounters;

       tickCount = 0;
       dow tickCount < runTicks;
          tickCount += 1;

          if %rem(tickCount : FREQ_ORDER) = 0;
             exsr ChurnOrder;
          endif;
          if %rem(tickCount : FREQ_PO) = 0;
             exsr ChurnPO;
          endif;
          if %rem(tickCount : FREQ_INV) = 0;
             exsr ChurnInventory;
          endif;
          if %rem(tickCount : FREQ_VND) = 0;
             exsr ChurnVendor;
          endif;
          if %rem(tickCount : FREQ_CUST) = 0;
             exsr ChurnCustomer;
          endif;

          exsr DelayTick;
       enddo;

       *inlr = *on;
       return;

       //****************************************************************
       //    SUBROUTINE - InitRandom                                    *
       //    PURPOSE    - Seed the LCG from the time of day so repeated *
       //                 runs don't all draw the same sequence.        *
       //****************************************************************
       begsr InitRandom;
          gSeed = (%subdt(%time():*hours) * 3600
                 + %subdt(%time():*minutes) * 60
                 + %subdt(%time():*seconds));
          if gSeed <= 0;
             gSeed = 1;
          endif;
       endsr;

       //****************************************************************
       //    SUBROUTINE - NextRandom (function-style, via return value) *
       //    PURPOSE    - Advance the LCG, return a value in            *
       //                 0..randMax-1 (randMax passed in, result out   *
       //                 via randResult).                              *
       //****************************************************************
       begsr NextRandom;
          gSeed = %rem(gSeed * 16807 : 2147483647);
          if gSeed <= 0;
             gSeed += 2147483647;
          endif;
          randResult = %rem(gSeed : randMax);
       endsr;

       //****************************************************************
       //    SUBROUTINE - InitCounters                                  *
       //    PURPOSE    - Seed the next-id counters for each file from  *
       //                 the time of day, in dedicated non-colliding   *
       //                 ranges.                                       *
       //****************************************************************
       begsr InitCounters;
          nextCust   = 90000 + %rem(gSeed : 9000);
          nextVnd    = 900000 + %rem(gSeed + 111 : 90000);
          nextInvSeq = 9000000 + %rem(gSeed + 222 : 900000);
          nextPo     = 900000 + %rem(gSeed + 333 : 90000);
          nextOrd    = 900000 + %rem(gSeed + 444 : 90000);
       endsr;

       //****************************************************************
       //    SUBROUTINE - ChurnCustomer                                 *
       //    PURPOSE    - Randomly create, modify, or delete a churn-   *
       //                 owned customer record.                        *
       //****************************************************************
       begsr ChurnCustomer;
          if custCount = 0;
             action = 0;
          else;
             randMax = 3;
             exsr NextRandom;
             action = randResult;
          endif;

          if action = 0;
             cust   = nextCust;
             nextCust += 1;
             name   = 'CHURN CUST ' + %char(cust);
             addr1  = 'TEST ADDR';
             addr2  = *blank;
             city   = 'TESTVILLE';
             state  = 'TS';
             zip    = 99999;
             write cmlrec1;
             if custCount < MAXTRACK;
                custCount += 1;
                custIds(custCount) = cust;
             endif;
          else;
             randMax = custCount;
             exsr NextRandom;
             idx = randResult + 1;
             custKey = custIds(idx);
             chain custky cmlrec1;
             if %found(cusmstl1);
                if action = 1;
                   randMax = 10000;
                   exsr NextRandom;
                   zip = 90000 + randResult;
                   update cmlrec1;
                else;
                   delete cmlrec1;
                   custIds(idx) = custIds(custCount);
                   custCount -= 1;
                endif;
             else;
                custIds(idx) = custIds(custCount);
                custCount -= 1;
             endif;
          endif;
       endsr;

       //****************************************************************
       //    SUBROUTINE - ChurnVendor                                   *
       //    PURPOSE    - Randomly create, modify, or delete a churn-   *
       //                 owned vendor record.                          *
       //****************************************************************
       begsr ChurnVendor;
          if vndCount = 0;
             action = 0;
          else;
             randMax = 3;
             exsr NextRandom;
             action = randResult;
          endif;

          if action = 0;
             vndid  = nextVnd;
             nextVnd += 1;
             vndnam = 'CHURN VENDOR ' + %char(vndid);
             vndad1 = 'TEST ADDR';
             vndcty = 'TESTVILLE';
             vndst  = 'TS';
             vndzip = '99999';
             vnd30  = 0;
             vnd60  = 0;
             vnd90  = 0;
             vndowe = 0;
             vndeml = *blank;
             write vmlrec1;
             if vndCount < MAXTRACK;
                vndCount += 1;
                vndIds(vndCount) = vndid;
             endif;
          else;
             randMax = vndCount;
             exsr NextRandom;
             idx = randResult + 1;
             vndKey = vndIds(idx);
             chain vndky vmlrec1;
             if %found(vndmstl1);
                if action = 1;
                   randMax = 10001;
                   exsr NextRandom;
                   vndowe = vndowe + (randResult - 5000) / 100;
                   update vmlrec1;
                else;
                   delete vmlrec1;
                   vndIds(idx) = vndIds(vndCount);
                   vndCount -= 1;
                endif;
             else;
                vndIds(idx) = vndIds(vndCount);
                vndCount -= 1;
             endif;
          endif;
       endsr;

       //****************************************************************
       //    SUBROUTINE - ChurnInventory                                *
       //    PURPOSE    - Randomly create, modify, or delete a churn-   *
       //                 owned inventory item. Needs an existing       *
       //                 churn-owned vendor to link to, since VNDID is *
       //                 validated by other programs -- skips create   *
       //                 if none exist yet.                            *
       //****************************************************************
       begsr ChurnInventory;
          if invCount = 0;
             action = 0;
          else;
             randMax = 3;
             exsr NextRandom;
             action = randResult;
          endif;

          if action = 0;
             if vndCount = 0;
                leavesr;
             endif;
             randMax = vndCount;
             exsr NextRandom;
             invid  = 'CH' + %char(nextInvSeq);
             nextInvSeq += 1;
             invdsc = 'CHURN ITEM';
             invunt = 'EA';
             qtyoh  = 0;
             qtyip  = 0;
             lstcst = 1.00;
             qtyoo  = 0;
             inactv = 'N';
             vndid  = vndIds(randResult + 1);
             write imlrec1;
             if invCount < MAXTRACK;
                invCount += 1;
                invIds(invCount) = invid;
             endif;
          else;
             randMax = invCount;
             exsr NextRandom;
             idx = randResult + 1;
             invKey = invIds(idx);
             chain invky imlrec1;
             if %found(invmstl1);
                if action = 1;
                   randMax = 21;
                   exsr NextRandom;
                   qtyoh = qtyoh + (randResult - 10);
                   if qtyoh < 0;
                      qtyoh = 0;
                   endif;
                   update imlrec1;
                else;
                   delete imlrec1;
                   invIds(idx) = invIds(invCount);
                   invCount -= 1;
                endif;
             else;
                invIds(idx) = invIds(invCount);
                invCount -= 1;
             endif;
          endif;
       endsr;

       //****************************************************************
       //    SUBROUTINE - ChurnPO                                       *
       //    PURPOSE    - Randomly create, modify (toggle open/closed), *
       //                 or delete a churn-owned purchase order. Needs *
       //                 an existing churn-owned vendor to link to --  *
       //                 skips create if none exist yet.               *
       //****************************************************************
       begsr ChurnPO;
          if poCount = 0;
             action = 0;
          else;
             randMax = 3;
             exsr NextRandom;
             action = randResult;
          endif;

          if action = 0;
             if vndCount = 0;
                leavesr;
             endif;
             randMax = vndCount;
             exsr NextRandom;
             ponbr  = nextPo;
             nextPo += 1;
             vndid  = vndIds(randResult + 1);
             postat = 'O';
             write pmlrec1;
             if poCount < MAXTRACK;
                poCount += 1;
                poIds(poCount) = ponbr;
             endif;
          else;
             randMax = poCount;
             exsr NextRandom;
             idx = randResult + 1;
             poKey = poIds(idx);
             chain poky pmlrec1;
             if %found(pormstl1);
                if action = 1;
                   if postat = 'O';
                      postat = 'C';
                   else;
                      postat = 'O';
                   endif;
                   update pmlrec1;
                else;
                   delete pmlrec1;
                   poIds(idx) = poIds(poCount);
                   poCount -= 1;
                endif;
             else;
                poIds(idx) = poIds(poCount);
                poCount -= 1;
             endif;
          endif;
       endsr;

       //****************************************************************
       //    SUBROUTINE - ChurnOrder                                    *
       //    PURPOSE    - Randomly create, modify, or delete a churn-   *
       //                 owned order. Needs an existing churn-owned    *
       //                 customer to link to -- skips create if none   *
       //                 exist yet. Fires every tick (most frequent).  *
       //****************************************************************
       begsr ChurnOrder;
          if ordCount = 0;
             action = 0;
          else;
             randMax = 3;
             exsr NextRandom;
             action = randResult;
          endif;

          if action = 0;
             if custCount = 0;
                leavesr;
             endif;
             randMax = custCount;
             exsr NextRandom;
             ordid = nextOrd;
             nextOrd += 1;
             cust  = custIds(randResult + 1);
             randMax = 10000000;
             exsr NextRandom;
             cuspo = 'PO' + %char(randResult);
             orddt = %date();
             write omlrec1;
             if ordCount < MAXTRACK;
                ordCount += 1;
                ordIds(ordCount) = ordid;
             endif;
          else;
             randMax = ordCount;
             exsr NextRandom;
             idx = randResult + 1;
             ordKey = ordIds(idx);
             chain ordky omlrec1;
             if %found(ordmstl1);
                if action = 1;
                   orddt = %date();
                   update omlrec1;
                else;
                   delete omlrec1;
                   ordIds(idx) = ordIds(ordCount);
                   ordCount -= 1;
                endif;
             else;
                ordIds(idx) = ordIds(ordCount);
                ordCount -= 1;
             endif;
          endif;
       endsr;

       //****************************************************************
       //    SUBROUTINE - DelayTick                                     *
       //    PURPOSE    - Pause between ticks via DLYJOB (issued        *
       //                 through QCMDEXC -- there's no native RPG      *
       //                 sleep).                                       *
       //****************************************************************
       begsr DelayTick;
          dlyCmd = 'DLYJOB DLY(' + %trim(%char(delaySec)) + ')';
          QCmdExc(dlyCmd : %len(%trimr(dlyCmd)));
       endsr;

      /end-free
