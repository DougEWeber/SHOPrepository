-- Smoke-test data for VNDMST, CUSMST, INVMST, PORMST, RCVTRN.
-- Run with RUNSQLSTM against a library where all 5 tables already exist.
-- Insert order follows the FK-like dependency chain:
--   vndmst -> cusmst -> invmst -> pormst -> rcvtrn

insert into vndmst (vndid, vndnam, vndad1, vndcty, vndst, vndzip, vnd30, vnd60, vnd90, vndowe, inactv)
  values (1, 'Acme Supply Co', '100 Main St', 'Springfield', 'IL', '62701', 10, 20, 30, 245.50, 'N');
insert into vndmst (vndid, vndnam, vndad1, vndcty, vndst, vndzip, vnd30, vnd60, vnd90, vndowe, inactv)
  values (2, 'Global Parts Inc', '200 Oak Ave', 'Columbus', 'OH', '43215', 5, 10, 15, 0.00, 'N');
insert into vndmst (vndid, vndnam, vndad1, vndcty, vndst, vndzip, vnd30, vnd60, vnd90, vndowe, inactv)
  values (3, 'Midwest Distributors', '300 Elm St', 'Chicago', 'IL', '60601', 15, 25, 35, 1200.75, 'N');

insert into cusmst (cust, name, addr1, addr2, city, state, zip, arbal)
  values (10001, 'John Smith', '123 Elm St', 'Apt 4', 'Springfield', 'IL', 62701, 0.00);
insert into cusmst (cust, name, addr1, addr2, city, state, zip, arbal)
  values (10002, 'Mary Jones', '456 Oak Av', '', 'Columbus', 'OH', 43215, 150.25);
insert into cusmst (cust, name, addr1, addr2, city, state, zip, arbal)
  values (10003, 'Bob Wilson', '789 Pine', 'Suite 2', 'Chicago', 'IL', 60601, 0.00);
insert into cusmst (cust, name, addr1, addr2, city, state, zip, arbal)
  values (10004, 'Ann Davis', '321 Maple', '', 'Peoria', 'IL', 61601, 500.00);

insert into invmst (invid, invdsc, invunt, qtyoh, qtyip, lstcst, qtyoo, inactv, vndid)
  values ('WIDGET001', 'Standard Widget', 'EA', 100, 0, 5.25, 0, 'N', 1);
insert into invmst (invid, invdsc, invunt, qtyoh, qtyip, lstcst, qtyoo, inactv, vndid)
  values ('WIDGET002', 'Deluxe Widget', 'EA', 50, 0, 8.75, 20, 'N', 1);
insert into invmst (invid, invdsc, invunt, qtyoh, qtyip, lstcst, qtyoo, inactv, vndid)
  values ('BOLT-1000', 'Steel Bolt 1in', 'BX', 200, 0, 12.00, 0, 'N', 2);
insert into invmst (invid, invdsc, invunt, qtyoh, qtyip, lstcst, qtyoo, inactv, vndid)
  values ('GASKET-A', 'Rubber Gasket A', 'EA', 75, 0, 2.50, 50, 'N', 2);
insert into invmst (invid, invdsc, invunt, qtyoh, qtyip, lstcst, qtyoo, inactv, vndid)
  values ('PANEL-XL', 'XL Metal Panel', 'EA', 20, 0, 45.00, 0, 'N', 3);

insert into pormst (ponbr, vndid, postat)
  values (1, 1, 'O');
insert into pormst (ponbr, vndid, postat)
  values (2, 2, 'O');
insert into pormst (ponbr, vndid, postat)
  values (3, 3, 'C');

insert into rcvtrn (invid, ponbr, vndinv, rcvdt, rcvtm, rtqord, rtqrcv, chkusr)
  values ('WIDGET002', 1, 'INV-1001', '2026-06-01', '09:15:00', 20, 20, 'DOUGW');
insert into rcvtrn (invid, ponbr, vndinv, rcvdt, rcvtm, rtqord, rtqrcv, chkusr)
  values ('WIDGET001', 1, 'INV-1002', '2026-06-10', '10:00:00', 30, 25, 'JSMITH');
insert into rcvtrn (invid, ponbr, vndinv, rcvdt, rcvtm, rtqord, rtqrcv, chkusr)
  values ('GASKET-A', 2, 'INV-2050', '2026-06-05', '13:30:00', 50, 50, 'DOUGW');
insert into rcvtrn (invid, ponbr, vndinv, rcvdt, rcvtm, rtqord, rtqrcv, chkusr)
  values ('BOLT-1000', 2, 'INV-2075', '2026-06-12', '08:45:00', 100, 100, 'DOUGW');
