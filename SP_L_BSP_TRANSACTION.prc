create or replace PROCEDURE        sp_l_bsp_transaction (fileToProcess VARCHAR2 ) AS 
-- DECLARE /*****  D E C L A R E  S E C T I O N  *****/
--===========================================================
-- sp_l_bsp_transaction - which takes the contents of bsp_transaction
-- and populates the bsp_transaction table
--
--===========================================================
-- Change History
--===========================================================
-- Date         Ver    Who        Comment
-- 22-Oct-19    1.0    SMartin    Original Version
-- 13-Nov-19    1.1    DScott     Calls to function isRecordTypeSeqValid to ensure full file processed.
-- 14-Nov-19    1.2    DScott     Jump outs to invalid_row EXCEPTION
--                                Added in 0'd conjunction records
-- 02-Dec-19    1.3    DScott     Call to dedupe procedure Added
-- 12-Dec-19    1.4    DScott     Version 230
--
--
-- @I:\MI\DarrenScott\Workspace\UK\Database\dtwlive\stella\procs\SP_L_BSP_TRANSACTION_1.5.prc
--
--
-- exec sp_l_bsp_transaction_dz ('TESTFILE_DELETE');
--
-- 869,035 original records in bsp_transaction
--
--===========================================================
-- EXCEPTION DEFINITIONS
--
primary_key_error EXCEPTION;
PRAGMA EXCEPTION_INIT(primary_key_error, -00001);
foreign_key_error EXCEPTION;
PRAGMA EXCEPTION_INIT(foreign_key_error, -02291);
already_loaded EXCEPTION;
invalid_row EXCEPTION;
--
--
v_commit_at CONSTANT PLS_INTEGER := 1000;
--
-- VARIABLES HOLDING DATA FROM CURSOR
--
v_bsp_trans_id                     bsp_transaction.bsp_trans_id%TYPE;
v_ticket_no                        bsp_transaction.ticket_no%TYPE;
v_refund_document_no               bsp_transaction.refund_document_no%TYPE;
v_transaction_code                 bsp_transaction.transaction_code%TYPE;
v_bsp_filename                     bsp_transaction.bsp_filename%TYPE;
v_bsp_period_ending_date           bsp_transaction.bsp_period_ending_date%TYPE;
v_entry_date_time                  bsp_transaction.entry_date_time%TYPE;
v_entry_user_id                    bsp_transaction.entry_user_id%TYPE;
v_bsp_crs_code                     bsp_transaction.bsp_crs_code%TYPE;
v_reconciled_ind                   bsp_transaction.reconciled_ind%TYPE;
v_last_reconciled_date             bsp_transaction.last_reconciled_date%TYPE;
v_airline_num                      bsp_transaction.airline_num%TYPE;
v_iata_num                         bsp_transaction.iata_num%TYPE;
v_tax_amt                          bsp_transaction.tax_amt%TYPE;
v_supp_commission_amt              bsp_transaction.supp_commission_amt%TYPE;
v_EffectiveCommissionAmt           bsp_transaction.commissionable_amt%TYPE;
v_commissionable_amt               bsp_transaction.commissionable_amt%TYPE;
v_commission_amt                   bsp_transaction.commission_amt%TYPE;
v_net_fare_amt                     bsp_transaction.net_fare_amt%TYPE;
v_ccy_code                         bsp_transaction.ccy_code%TYPE;
v_reason_code                      bsp_transaction.reason_code%TYPE;
v_conjunction_ind                  bsp_transaction.conjunction_ind%TYPE;
v_stella_seat_amt                  bsp_transaction.stella_seat_amt%TYPE;
v_stella_tax_amt                   bsp_transaction.stella_tax_amt%TYPE;
v_airline_penalty_amt              bsp_transaction.airline_penalty_amt%TYPE;
v_airline_penalty_amt2             bsp_transaction.airline_penalty_amt%TYPE;
v_airline_penalty_amt3             bsp_transaction.airline_penalty_amt%TYPE;
v_balance_payable_amt              bsp_transaction.balance_payable_amt%TYPE;
v_net_remit_ind                    bsp_transaction.net_remit_ind%TYPE;
v_netremitind                      VARCHAR2(2);
v_ub_tax_amt                       bsp_transaction.ub_tax_amt%TYPE;
v_gb_tax_amt                       bsp_transaction.gb_tax_amt%TYPE;
v_remaining_tax_amt                bsp_transaction.remaining_tax_amt%TYPE;
v_tax1                             bsp_transaction.tax_amt%TYPE;
v_tax2                             bsp_transaction.tax_amt%TYPE;
v_tax3                             bsp_transaction.tax_amt%TYPE;
v_remittance_amt                   bsp_transaction.remaining_tax_amt%TYPE;
v_discrepancy_amt                  bsp_transaction.stella_tax_amt%TYPE;
v_total_discrepancy_amt            bsp_transaction.stella_tax_amt%TYPE;

v_recid                            l_hot.recid%TYPE;
v_sequence_no                      l_hot.sequence_no%TYPE;
v_sequence                         l_hot.sequence_no%TYPE;
v_prevhighsequence                 l_hot.sequence_no%TYPE;
v_data_text                        l_hot.data_text%TYPE;
v_period                           NUMBER;   
v_stage                            VARCHAR2(200);
v_run_state                        VARCHAR2(50);
v_checkDup                         BOOLEAN := false;
v_countFiles                       NUMBER;
v_recdate                          NUMBER;
v_hightrans                        l_hot.sequence_no%TYPE;
v_prevHighTrans                    l_hot.sequence_no%TYPE;
v_tax_type                         VARCHAR2(2);
hadBKS24                           BOOLEAN;
hadBKS30                           BOOLEAN; 
hadBKS39                           BOOLEAN; 
processedThisTrans                 BOOLEAN;
v_prevBKSType                      NUMBER;
v_error_statement                  VARCHAR2(150) := '';

v_prevrecid                       l_hot.recid%TYPE;
v_valid                           VARCHAR2(1);  
--
-- Work Variables
--
v_null              CHAR(1);
v_count             CHAR(1);
v_insert_ok         CHAR(1);
v_update_ok         CHAR(1);
v_fk_error          CHAR(1);
v_foreign_key_error CHAR(1);
v_primary_key_error CHAR(1);
--
v_code          NUMBER(5);
v_error_message VARCHAR2(512);
--
CURSOR C001 IS
  SELECT recid,
         sequence_no,
         rec_type,
         data_text       
  FROM l_hot
--  WHERE sequence_no <17
--where sequence_no between 373 and 393
--or    sequence_no <4
  ORDER BY sequence_no;
  --
BEGIN
  /**** < OPEN Cursor Block > ****/
  --
  v_primary_key_error := 'N';
  v_foreign_key_error := 'N';
  --
  v_run_state     := NULL;
  v_sequence      := 0;
  v_hightrans     := 0;
  v_prevHighTrans := 0;
  processedThisTrans := False;

  FOR c1_rec IN c001 LOOP

    IF c1_rec.recid = 'BFH'
        THEN v_prevrecid := 'ONE';
        ELSE v_prevrecid   := v_recid;  
    END IF;     -- set previous_recid before overwrite current recid

  --
     v_recid       := c1_rec.recid;
     v_sequence_no := c1_rec.sequence_no;
     v_data_text   := c1_rec.data_text; 
        dbms_output.put_line('Recid is '||v_recid);
        --dbms_output.put_line('Previous Recid is '||v_prevrecid||' And this Recid is '||v_recid);
        dbms_output.put_line('Seq_No is '||to_char(v_sequence_no));
     EXIT WHEN c1_rec.recid = 'BFT';


     ---- Test rec Id to see if row is processed in sequence--------
     SELECT isRecordTypeSeqValid(v_prevrecid,v_recid) 
                  INTO v_valid FROM DUAL;

                  --dbms_output.put_line('Previous Recid is '||v_prevrecid||' And this Recid is '||v_recid);
                  --dbms_output.put_line('Is This Record valid?'||v_valid);

                  IF v_valid = 'N'
                  THEN
                  dbms_output.put_line('This Record Is not VALID!!!'||v_valid);
                  dbms_output.put_line('Previous Recid is '||v_prevrecid||' And this Recid is '||v_recid);
                  --core_dataw.sp_errors('BSP_TICKET','BSP_TICKET',SQLCODE,'Invalid Recid ' ||SQLERRM); 
                  --core_dataw.sp_errors('BSP','BSP_TRANSACTION',SQLCODE,'Invalid row-Sequence: '||v_sequence_no||' SqERRM' ||SQLERRM);
                  RAISE invalid_row;
                  END IF;
                    ---- End Test rec Id to see if row is processed in sequence--------



        --Does it have a header file and a valid rec id- If Not Bail Out.
        IF v_sequence_no = 1 AND v_recid != 'BFH'
            THEN    dbms_output.put_line('No Header Record!!!');
                    RAISE invalid_row;
        ELSIF v_recid IS NULL
            THEN    dbms_output.put_line('Null Rec ID');
                    RAISE invalid_row;
        ELSE NULL;
        END IF;





         IF v_recid NOT IN('BFH','BOH','BCH','BCT','BFT') THEN
        --if not one of these record types then validate the record sequence
        -- dbms_output.put_line( SUBSTR(v_data_text,7,6));
                v_sequence := TO_NUMBER( SUBSTR(v_data_text,2,5));

         END IF;

                v_prevHighSequence := v_sequence_no;

                v_stage := 'About to process BCH';
                --dbms_output.put_line(v_stage);
                IF v_recid = 'BCH' THEN
                 --isRecordTypeSeqValid

                --dbms_output.put_line('Batch Hdr: ' || v_data_text);  -- BCH record
                    IF core_dataw.is_number(SUBSTR(v_data_text,15,6)) = 0 THEN
                       dbms_output.put_line('ERROR datafile: ' || fileToProcess || ' file date non-numeric: ' ||
                                             SUBSTR(v_data_text,15,6) || ' (record was: ' || v_recid || ')');
                       RAISE invalid_row;
                    ELSE
                       v_period := TO_NUMBER(substr(v_data_text,15,6)); -- in format yymmdd
                    END IF;
                    v_stage := 'Finished processing BCH';
                -- office batch header, BOH
                v_stage := 'About to process BOH';

                dbms_output.put_line('Stage: '||v_stage);

                ELSIF v_recid = 'BOH' THEN 
                -- check if file is already loaded , check once

                    IF core_dataw.is_number(SUBSTR(v_data_text,9,6)) = 0 
                            THEN RAISE invalid_row;
                    ELSE    v_recdate := TO_NUMBER(SUBSTR(v_data_text,9,6));
                    END IF;



                    IF core_dataw.is_number(SUBSTR(v_data_text,1,8)) = 0 THEN
                       dbms_output.put_line('ERROR datafile: ' || fileToProcess || ' BOH IATA non-numeric: ' || 
                                            SUBSTR(v_data_text,1,8) || ' (record was: ' || v_recid || ')');
                       RAISE invalid_row;
                    ELSE
                       v_iata_num := TO_NUMBER(SUBSTR(v_data_text,1,8));
                    END IF;

                    v_stage := 'Checking if file has already been loaded';

                    --dbms_output.put_line('v_checkdupe is ' || v_checkDup);
                    dbms_output.put_line('Stage: '||v_stage);

                    IF NOT v_checkDup THEN
                        dbms_output.put_line('Covers period to ' || TO_CHAR(v_recdate)); 

                        v_checkDup := true;  
                    -- don't  do it again for another BOH

                    -- check to see if bsp_transaction table already has an entry in it for this filename
                    -- H&J and Citalia files are comign as a seperate BSP file and they have to be loaded , change validation to include iata number ,
                    -- so key in select below will be (bsp period ending date + iata no )
                        v_countFiles := 0;
                        BEGIN
                           SELECT COUNT(*)
                           INTO   v_countFiles
                           FROM   bsp_transaction
                           WHERE  bsp_period_ending_date = TO_DATE(TO_CHAR(v_recdate),'yymmdd')
                           AND    iata_num               = v_iata_num
                           AND    bsp_filename           = fileToProcess;

                           dbms_output.put_line('v_countfiles is ' ||v_countFiles);

                        EXCEPTION
                        WHEN NO_DATA_FOUND THEN 
                             v_countFiles := 0;
                        END;
                        IF v_countFiles > 0 THEN
                        -- have already seen this filename, ERROR
                           dbms_output.put_line('CRITICAL ERROR datafile: ' || fileToProcess || 
                                                ' filePeriod: ' || v_period || ' recDate: ' || TO_CHAR(v_recdate) || 
                                                ' iataNum: ' || v_iata_num || ' data already exists in BSP data. Processed already?' );
                           RAISE already_loaded;                 
                        END IF;
                    END IF; -- checkDup , do onlY once


                    dbms_output.put_line('v_countfiles is ' ||v_countFiles);

                -- End BOH processing              

                ELSIF v_recid = 'BKT' THEN

                    dbms_output.put_line('Batch Txt: ' || v_data_text);  -- BCH record  
                    -- transaction header
                    -- first validate
                    -- check sequence of transactions is correct , should increment by one each BKT record

                    v_sequence := TO_NUMBER(SUBSTR(v_data_text,2,5));
                    v_stage := 'About to process '|| v_recid || ' - sequence: '|| TO_CHAR(v_sequence);
                     --           dbms_output.put_line(v_stage);
                    -- BEGIN       
                    dbms_output.put_line(v_stage || to_char(v_sequence));
                        IF hadBKS24 AND NOT processedThisTrans THEN
                            dbms_output.put_line('ERROR datafile: ' || fileToProcess || 
                                                   ' BKT trans but have not finished prcoessing last trans: ' || TO_CHAR(v_highTrans) || 
                                                   ' vs.' || TO_CHAR(v_prevHighTrans) || ' (record was: ' || v_data_text || ')');
                        RAISE invalid_row;
--                       return 1;
                    END IF;

                    hadBKS24 := false;
                    hadBKS39 := false;
                    hadBKS30 := false;
                    processedThisTrans := false;      

-- Reset database variables

                    v_ticket_no              := NULL;
                    v_transaction_code       := NULL;
                    v_bsp_crs_code           := NULL;
                    v_airline_num            := NULL;
                    v_tax_amt                := 0;
                    v_commissionable_amt     := 0;
                    v_commission_amt         := 0;
                    v_net_fare_amt           := 0;
                    v_ccy_code               := NULL;
                    v_conjunction_ind        := NULL;
                    v_airline_penalty_amt    := 0;
                    v_balance_payable_amt    := 0;
                    v_net_remit_ind          := 'N';
                    v_ub_tax_amt             := 0;
                    v_gb_tax_amt             := 0;
                    v_remaining_tax_amt      := 0;
                    v_EffectiveCommissionAmt := 0;    
                    v_conjunction_ind  := 'N';

                    v_hightrans := v_sequence ;
                    IF v_hightrans != v_prevhightrans + 1 THEN
                        dbms_output.put_line('ERROR datafile: ' || fileToProcess || ' BKT transactions out of seq: ' || TO_CHAR(v_hightrans) || 
                                             ' vs. ' || TO_CHAR(v_prevhightrans) || ' (record was: ' || v_data_text || ')');
                        RAISE invalid_row;
                    END IF;           

                    v_prevhightrans := v_hightrans;       

                    IF core_dataw.is_number(SUBSTR(v_data_text,12,3)) = 0 THEN 
                        dbms_output.put_line('ERROR datafile: ' || fileToProcess || ' BKT airline non-numeric: ' || SUBSTR(v_data_text,38,3) ||
                                             ' (record was: ' || v_data_text || ')');
                        RAISE invalid_row;
                    ELSE
                       v_airline_num := SUBSTR(v_data_text,12,3);
                    END IF;                    

                    v_bsp_crs_code := SUBSTR(v_data_text,52,4);                 

                    --source of transaction
                    v_netremitind := SUBSTR(v_data_text,7,2);   
                        dbms_output.put_line('Net Remit Ind 1: '|| v_netremitind);

                    IF v_netremitind IS NULL OR v_netremitind = '  ' 
                        THEN    --dbms_output.put_line('Net Remit Ind IS NULL Or Empty!!!!!!!!!!!');
                                v_net_remit_ind := 'N';
                    END IF;

                    IF v_netremitind = 'NR' THEN
                        v_net_remit_ind := 'Y'; 
                    ELSIF v_netremitind = '  '
                        THEN v_net_remit_ind := 'N';
                    ELSE v_net_remit_ind := 'N';

                    END IF;

                      dbms_output.put_line('Net Remit Ind 2: '|| v_net_remit_ind);

                    -- reset                    
                    v_tax_amt                := 0;
                    v_ub_tax_amt             := 0;
                    v_gb_tax_amt             := 0;
                    v_remaining_tax_amt      := 0;
                    v_net_fare_amt           := 0;
                    v_commissionable_amt     := 0;
                    v_commission_amt         := 0;
                    v_EffectiveCommissionAmt := 0;
                    v_airline_penalty_amt    := 0;
                    v_balance_payable_amt    := 0;     

                -- end of BKT processing
                --exception
                --when others then  
                --dbms_output.put_line('ERROR datafile: ' ||  v_data_text );

                    --end;
                ELSIF  v_recid = 'BKS' THEN
                -- ticket id record
                -- first validate

                    v_sequence := SUBSTR(v_data_text,8,5);
                    v_stage := 'About to process ' || TO_CHAR(v_sequence);
                dbms_output.put_line(v_stage);
                dbms_output.put_line('BKS sequence: '||v_sequence);
                dbms_output.put_line('BKS hightrans: '||v_hightrans);

                -- it should be same sequence as corresponding BKT record above it

                    if v_sequence !=  v_hightrans THEN
                        dbms_output.put_line('ERROR datafile: ' || fileToProcess || ' BKT seq num out of sequence: ' || TO_CHAR(v_sequence) || 
                                             ' vs. ' || TO_CHAR(v_highTrans) || ' (record was: ' || v_data_text || ')');
                        RAISE invalid_row;
                    END IF;
                    --dbms_output.put_line('Type - ' || SUBSTR(v_data_text,7,6) || ' - ' ||v_data_text);
                    --dbms_output.put_line('RecType - ' || TO_CHAR(c1_rec.rec_type));
                    -- 24 indicates the first one in a batch
                    IF c1_rec.rec_type = 24 THEN





                    -- ticketID record
                    -- now populate necessary fields

--                        countBKS24 ++; 


                        v_iata_num         := TO_NUMBER(SUBSTR(v_data_text,35,8));  
                        --v_ticket_no        := SUBSTR(v_data_text,16,11);

                        dbms_output.put_line(' iata number '||v_iata_num);



                       IF SUBSTR(v_data_text,32,3) = 'CNJ' THEN
                        -- conjunction ticket, need to process what we already have within
                        -- this BKT batch
                        -- before we can process this conjunction one
                        -- call stored proc here -- needs to be in a subroutine so can be
                        -- called from
                        -- different places
                        -- again need to validate flags
                        -- now insert record to database
                                                    --v_conjunction_ind := 'N'; 
                        -- only the second in the pair should be set to Y in database
                        dbms_output.put_line('Loading CNJ');
                        --dbms_output.put_line(' Now Insert' ) ;
                        --now insert record to database 
                        -- This inserts effectively the previous ticket number to the one marked as conjunction record -- DScott v1.2

                            v_error_statement := p_stella_bsp_data.insert_transaction(
                                                v_ticket_no,
                                                v_transaction_code,
                                                fileToProcess,
                                                TO_DATE(v_recdate,'YYMMDD'),
                                                v_bsp_crs_code,
                                                v_airline_num,
                                                v_iata_num,
                                                NVL(v_commissionable_amt,0), 
                                                NVL(v_commission_amt,0), 
                                                NVL(v_tax_amt,0), 
                                                NVL(v_net_fare_amt,0), 
                                                v_ccy_code,
                                                v_net_remit_ind,
                                                v_conjunction_ind,
                                                NVL(v_airline_penalty_amt,0),   
                                                NVL(v_balance_payable_amt,0),    
                                                NVL(v_ub_tax_amt,0), 
                                                NVL(v_gb_tax_amt,0), 
                                                NVL(v_remaining_tax_amt,0));

                            IF v_error_statement IS NOT NULL THEN
                               dbms_output.put_line('ERROR BKS24 datafile: ' || fileToProcess ||
                                                   ' Error inserting transaction to database (bkp)');
                               raise_application_error(-20001,'ERROR BKA24 datafile: ' || fileToProcess || ' - ' ||
                                                       v_error_statement || ' Error inserting transaction to database (bkp)');
                            --ELSE

                            END IF; 


                            processedThisTrans := False; 

                            v_conjunction_ind  := 'Y';
                              --                     ELSE 'N'
                                --              END; 




                            --we have processed the previous 24, but not this one
                            v_conjunction_ind := 'Y'; 
                            --only the second in the pair should be set to Y in database
                            v_tax_amt                := 0;
                            v_ub_tax_amt             := 0;
                            v_gb_tax_amt             := 0;
                            v_remaining_tax_amt      := 0;
                            v_net_fare_amt           := 0;
                            v_commissionable_amt     := 0;
                            v_commission_amt         := 0;
                            v_EffectiveCommissionAmt := 0;
                            v_airline_penalty_amt    := 0;
                            v_balance_payable_amt    := 0;

                       -----End if conjunction ind = Y
                        END IF;


                       -- ElSE 
                       -- dbms_output.put_line('Conjunction ind = N');
                        -- Itsnot a conjunction rcord and therefore doesnt trigger the insert - just assign Ticket number of first pass through -- DScott v1.2
                        v_ticket_no        := SUBSTR(v_data_text,16,11);
                        dbms_output.put_line('Ticket Number '||v_ticket_no);
                        v_transaction_code := SUBSTR(v_data_text,59,3); 


                        hadBKS24 := true;



                        --dbms_output.put_line(' 3 ');

                        --hadBKS24 := true;

                        -- end of 24 BKS rec
                    ELSIF c1_rec.rec_type = 30 THEN
                    -- document amounts record
                    -- can get more than one record in succession if more than 2 taxes are applicable
                    -- amt fields are reset each BKT record
                    --                       if (!prevBKSType.equals('24') && !prevBKSType.equals('30')) {
                                IF v_prevBKSType NOT IN ( 24,30) THEN
                                    dbms_output.put_line('ERROR datafile: ' || fileToProcess || 
                                                         ' BKS seq type invalid - out of sequence?: '|| SUBSTR(v_data_text,7,6) || 
                                                         ', BKS24 was missing (record was: ' || v_data_text || ')');
                                    RAISE invalid_row;
        --                            return 1;
                                END IF;

                                -- now check we are talking about same ticket as the bks24 above it
                                IF SUBSTR(v_data_text,16,11) != v_ticket_no THEN
                                    dbms_output.put_line('ERROR datafile: ' || fileToProcess || 
                                                         ' BKS30 seq tkt invalid - diff to bks24: '|| SUBSTR(v_data_text,16,11) || 
                                                         ', (record was: ' || v_data_text || ')');
                                    RAISE invalid_row;
        --                            return 1;
                                END IF; 

                                IF  v_sequence !=  v_hightrans THEN
                                    dbms_output.put_line('ERROR datafile: ' || fileToProcess || 
                                                           ' BKS30 trans seq num out of sequence: ' || v_sequence || 
                                                           ' vs. ' || TO_CHAR(v_hightrans) || ' (record was: ' || v_data_text || ')');
                                    RAISE invalid_row;
        --                            return 1;
                                END IF;
                                --dbms_output.put_line(' 3 '|| SUBSTR(v_data_text,29,11));
                                -- this is the published fare
                                v_commissionable_amt :=  v_commissionable_amt + BSP_amt(SUBSTR(v_data_text,28,11));  
                                dbms_output.put_line('Comm Amount: '||v_commissionable_amt); 

                                -- this is the selling fare

                                v_net_fare_amt := v_net_fare_amt+BSP_amt(SUBSTR(v_data_text,39,11));
                                dbms_output.put_line('Net Fare Amount: '||v_net_fare_amt); 

                                    -- potentially two amounts representing taxes on the record

                                -- we don't care what parts make up the tax, just the total
                                -- but need to exclude CP tax type which is for airline penalty and is recorded separately

                                v_tax_type := SUBSTR(v_data_text,50,2);
                                --dbms_output.put_line('Tax Type1: '||v_tax_type);  

                                --dbms_output.put_line(' 6 ');
                                IF v_tax_type != 'CP' THEN 

                                    v_tax1 := BSP_amt(SUBSTR(v_data_text,58,11));                                    

                                    IF v_tax_type ='UB' THEN
                                        v_ub_tax_amt := v_ub_tax_amt + v_tax1;  
                                    ELSIF v_tax_type = 'GB' THEN
                                        v_gb_tax_amt := v_gb_tax_amt + v_tax1;
                                    ELSE
                                        v_remaining_tax_amt := v_remaining_tax_amt + v_tax1;
                                    END IF;

                                ELSE
                                -- CP airline penalty -- only usually used for RFND transactions for Galileo sourced refunds
                                                                                    -- DS Note - does this need to_number??
                                    v_airline_penalty_amt :=  v_airline_penalty_amt + BSP_amt(SUBSTR(v_data_text,58,11));
                                END IF;

                                v_tax_type := SUBSTR(v_data_text,69,2);
                                --dbms_output.put_line('Tax Type2: '||v_tax_type);  

                                IF v_tax_type !='CP' THEN
                                   v_tax2 := BSP_amt(SUBSTR(v_data_text,77,11));  

                                        IF v_tax_type = 'UB' THEN
                                          v_ub_tax_amt := v_ub_tax_amt + v_tax2;
                                        ELSIF v_tax_type = 'GB' THEN
                                          v_gb_tax_amt := v_gb_tax_amt + v_tax2; 
                                        ELSE
                                          v_remaining_tax_amt := v_remaining_tax_amt + v_tax2;
                                        END IF;
                                ELSE
                                -- CP airline penalty                                                               
                                --dbms_output.put_line('Airline_penalty 2 99,11: '||SUBSTR(v_data_text,99,11));
                                    v_airline_penalty_amt2 := v_airline_penalty_amt2 + BSP_amt(SUBSTR(v_data_text,77,11)); ----------CHECK HERE FOR CP VALUE-------------------
                                END IF;


                                v_tax_type := SUBSTR(v_data_text,88,2);
                                --dbms_output.put_line('Tax Type2: '||v_tax_type);  

                                IF v_tax_type !='CP' THEN
                                   v_tax3 := BSP_amt(SUBSTR(v_data_text,96,11));  

                                        IF v_tax_type = 'UB' THEN
                                          v_ub_tax_amt := v_ub_tax_amt + v_tax3;
                                        ELSIF v_tax_type = 'GB' THEN
                                          v_gb_tax_amt := v_gb_tax_amt + v_tax3; 
                                        ELSE
                                          v_remaining_tax_amt := v_remaining_tax_amt + v_tax3;
                                        END IF;
                                ELSE
                                -- CP airline penalty                                                               
                                --dbms_output.put_line('Airline_penalty 2 99,11: '||SUBSTR(v_data_text,99,11));
                                    v_airline_penalty_amt3 := v_airline_penalty_amt3 + BSP_amt(SUBSTR(v_data_text,96,11)); ----------CHECK HERE FOR CP VALUE-------------------
                                END IF;

                                --dbms_output.put_line('taxtype1: ' || v_tax_type || TO_CHAR(v_tax2,'999g999g999G990d00'));

                                -- capture the balance payable field -- called the document total in the bsp spec   
                                v_balance_payable_amt := v_balance_payable_amt + BSP_amt(SUBSTR(v_data_text,107,11)); --not 96

        --                        v_commission_amt := v_commission_amt + BSP_amt(SUBSTR(v_data_text,29,11);


                              --totalLateReportingAmt := totalLateReportingAmt + BSP_amt(SUBSTR(v_data_text,101,11));

                                -- there can be two or more bks30 records if more than 2 applicable taxes
                                -- so need to get total of these records
                                --dbms_output.put_line('Total Tax1 - ' ||TO_CHAR(v_tax1));     
                                --dbms_output.put_line('Total Tax2 - ' ||TO_CHAR(v_tax2));   
                                --dbms_output.put_line('Airline_penalty 1: '||v_airline_penalty_amt);
                                --dbms_output.put_line('Airline_penalty 2: '||v_airline_penalty_amt2);                        
                                v_tax_amt              := v_tax_amt + v_tax1 + v_tax2+ v_tax3;
                                --dbms_output.put_line('Total Tax - ' ||TO_CHAR(v_tax_amt));                        
                                v_tax1                 := 0;
                                v_tax2                 := 0;
                                v_tax3                 := 0;
                                v_airline_penalty_amt  := v_airline_penalty_amt + v_airline_penalty_amt2+ v_airline_penalty_amt3;  
                                v_airline_penalty_amt2 := 0;
                                v_airline_penalty_amt3 := 0;
                                v_ccy_code := SUBSTR(v_data_text,120,3);

                                dbms_output.put_line('Rec - 30');
                                dbms_output.put_line('Airline_penalty: '||v_airline_penalty_amt);

                                hadBKS30 := true; 
                    -- end of BKS30

                    ELSIF c1_rec.rec_type = 39 THEN
                    -- commission record
                    dbms_output.put_line('Rec - 39');
                    -- amt fields are reset each BKT record
                        IF v_prevBKSType != 30 THEN
                            dbms_output.put_line('ERROR datafile: ' || fileToProcess || ' BKS seq type invalid - out of sequence 39?: ' ||
                                 SUBSTR(v_data_text,7,6) || ', BKS30 was missing (record was: ' || v_data_text || '), prev was: ' ||
                                 TO_CHAR(v_prevBKSType));
                               RAISE invalid_row;
--                             return 1;
                        END IF;

                    -- now check we are talking about same ticket as the bks24 above it
                        IF SUBSTR(v_data_text,16,11) != v_ticket_no THEN
                            dbms_output.put_line('ERROR datafile: ' || fileToProcess || ' BKS39 seq tkt invalid - diff to bks24: ' || v_ticket_no ||
                                                 ', (record was: ' || v_data_text || ')');
                               RAISE invalid_row;
--                             return 1;
                        END IF;

                        IF v_sequence !=  v_hightrans  THEN
                            dbms_output.put_line('ERROR datafile: ' || fileToProcess || ' BKS39 trans seq num out of sequence: ' || 
                                                    TO_CHAR(v_sequence) || ' vs. '|| v_hightrans || ' (record was: ' || v_data_text ||')');
                            RAISE invalid_row;
--                             return 1;
                        END IF;
                        dbms_output.put_line('RecType - ' || TO_CHAR(c1_rec.rec_type));                        
                        v_commission_amt := v_commission_amt + BSP_amt(SUBSTR(v_data_text,42,11));
                        --dbms_output.put_line('RecType - '||SUBSTR(v_data_text,43,11));

--                        v_commissionable_amt   := v_balance_payable_amt - v_tax_amt;

                        -- commission stored as debit (-ve) in file

                        IF SUBSTR(v_data_text,120,3) != v_ccy_code THEN
                            dbms_output.put_line('ERROR datafile: ' || fileToProcess || ' BKS39 ccy different to bks30: vs. ' || v_ccy_code ||
                                                  ' (record was: '  || v_data_text || ')');
--                            return 1;
                        END IF;

                        hadBKS39 := true;
                        dbms_output.put_line('End - 39');
                        -- endof bks39 record
                        -- some other unexpected BKS rec type -- skip it, we don't need it
                    END IF;

                    v_prevBKSType := c1_rec.rec_type;  
                    --store the BKS type last encountered so can validate flow
                    -- End of BKS processing
                ELSIF v_recid = 'BKP' THEN
                -- first validate 

                    v_sequence := SUBSTR(v_data_text,8,5);
                    v_stage := 'About to process ' || TO_CHAR(v_sequence);
                dbms_output.put_line('About to process ' || v_recid || TO_CHAR(v_sequence));                    
                    IF v_sequence !=  v_hightrans THEN
                        dbms_output.put_line('ERROR datafile: ' || fileToProcess || ' BKP trans seq num out of sequence: ' || 
                                             TO_CHAR(v_sequence) || ' vs. ' || TO_CHAR(v_hightrans) ||
                                            ' (record was: ' || v_data_text || ')');
--                        return 1;
                    END IF;
                --dbms_output.put_line(' BKP 1 - ' ||SUBSTR(v_data_text,13,2));
                -- we sometimes get more than one bkp record in succession. this seems to be where
                -- there are multiple payment types. We don't care about this, so need to skip
                -- successive ones
                -- but ensure we do actually do the insert once -- when we encounter the CA 
                dbms_output.put_line(TO_CHAR(c1_rec.rec_type));
                    IF c1_rec.rec_type = 84 THEN
                    dbms_output.put_line(SUBSTR(v_data_text,1,6));                    
--                       v_recdate := TO_NUMBER(SUBSTR(v_data_text,1,6));
                        IF SUBSTR(v_data_text,13,2) = 'CA' THEN
                         dbms_output.put_line('CA');   
                        -- cash form of payment record -- present for every transaction
                        -- total for this transaction
                        -- use as control check for each transaction
                        -- remittance amt should be document amt less effective commission
                        --dbms_output.put_line('84 + CA');
                        --dbms_output.put_line(' Conj 1 ' || v_conjunction_ind ) ;    
                            IF v_conjunction_ind = 'Y' THEN
                                --dbms_output.put_line(' BKP 1 - conjunction'  || v_conjunction_ind);    

                               v_remittance_amt := BSP_amt(SUBSTR(v_data_text,85,11));-- not 96

                               v_discrepancy_amt := ROUND(v_remittance_amt -
                                                    (v_balance_payable_amt + v_effectivecommissionamt)); 

                                dbms_output.put_line(' BKP 2 - disc')  ;                                                     
                                IF v_discrepancy_amt != 0 THEN
                                -- mismatch between document total and remittance amt
                                    dbms_output.put_line('recbalpayable: ' || TO_CHAR(v_balance_payable_amt));
                                    dbms_output.put_line('receffectivecomm: ' || TO_CHAR(v_effectivecommissionamt));
                                    dbms_output.put_line('bkp84 remittance amt: ' || TO_CHAR(v_remittance_amt));
                                    dbms_output.put_line('datafile: ' || fileToProcess ||
                                    ' BKP remittance cross check discrep: ' ||
                                    v_remittance_amt || ' vs. ' ||TO_CHAR(v_balance_payable_amt + v_effectivecommissionamt) || 
                                    ' (tkt: ' || v_ticket_no|| ' filerecord was: ' || v_data_text || '), discrep was: ' 
                                    || TO_CHAR(v_discrepancy_amt) || '. Due to credit card internet payment?');
                                    --return 1; 
                                    --allow to continue - this is only a warning
                                    v_total_discrepancy_amt := v_total_discrepancy_amt + v_discrepancy_amt;
                                END IF;
                                dbms_output.put_line(' BKP 3' ) ; 
                            END IF; -- if cnj
                        --dbms_output.put_line(' Conj 2 ' || v_conjunction_ind ) ;                     
                        --dbms_output.put_line(' NOT Processed' ) ; 

                            IF NOT processedThisTrans THEN
                            dbms_output.put_line(' NOT Processed' ) ; 
                            -- insert the record here
                            -- first validate we have encountered all necessary types of record to get all data
                                IF v_conjunction_ind = 'Y' THEN
                                    IF NOT hadBKS24 THEN
                                        dbms_output.put_line('ERROR datafile: ' || fileToProcess || 
                                                               ' BKP, but conjn. tkt insuffient recs encountered to form data' ||
                                                               ' (record was: ' || v_data_Text || ')'); 
                                    ELSIF
                                        NOT hadBKS24 
                                    AND NOT hadBKS39 
                                    AND NOT hadBKS30 THEN
                                        dbms_output.put_line('ERROR datafile: ' || fileToProcess || 
                                                             ' BKP, but insufficient recs encountered to form data' ||
                                                             ' (record was: ' || v_data_Text || ')'); 
                                    END IF;
                                END IF;
                                dbms_output.put_line(' Now Insert ' ||v_recdate) ;
                                -- now insert record to database
                                v_error_statement :=       p_stella_bsp_data.insert_transaction(
                                                v_ticket_no,
                                                v_transaction_code,
                                                fileToProcess,
                                                TO_DATE(v_recdate,'YYMMDD'),
                                                v_bsp_crs_code,
                                                v_airline_num,
                                                v_iata_num,
                                                NVL(v_commissionable_amt,0), 
                                                NVL(v_commission_amt,0), 
                                                NVL(v_tax_amt,0), 
                                                NVL(v_net_fare_amt,0),
                                                v_ccy_code,
                                                v_net_remit_ind,
                                                v_conjunction_ind,
                                                NVL(v_airline_penalty_amt,0),  
                                                NVL(v_balance_payable_amt,0),   
                                                NVL(v_ub_tax_amt,0),
                                                NVL(v_gb_tax_amt,0),
                                                NVL(v_remaining_tax_amt,0));
--dbms_output.put_line(v_error_statement);                                                  
                                  IF v_error_statement IS NOT NULL THEN
                                     dbms_output.put_line('ERROR BKP datafile: ' || fileToProcess ||
                                                                    ' ' || v_error_statement ||
                                                         ' Error inserting transaction to database (bkp)');
                                     raise_application_error(-20001,'ERROR BKP datafile: ' || fileToProcess ||
                                                                    ' ' || v_error_statement ||
                                                                    ' Error inserting transaction to database (bkp)');
                                  ELSE
                                     processedThisTrans:= True;
                                  END IF;

-- End processed this trans

--                            IF (countBKS24 != countInsertedTrans ) {
--                                DBMS_OUTPUT.PUT_LINE('ERROR datafile: ' || fileToProcess ||
--                                ' end of file, not all bks24 loaded (inserted ' || countInsertedTrans ||
--                                ' vs. bks24: ' || countBKS24 || ')');
--                                return 1;
--                           END IF;
                            END IF;        
                        END IF; -- if CA
                    END IF; -- if 84
-- end of BKP processing
                ELSIF v_recid = 'BKI' THEN NULL;
-- itinerary record
-- not used, so skip
-- end of BKI processing
                ELSIF v_recid = 'BAR' THEN NULL;
-- payment record
-- not used, so skip
-- end of BAR processing
                END IF;

-- end while within loop of BOH
-- must have now a BCT record, previous will have been BOT
-- get any values needed from BCT
-- read next line
            v_stage := 'End of reading loop';
--dbms_output.put_line(v_stage) ;

     --
     IF C001%ROWCOUNT MOD v_commit_at = 0 THEN
     --
        COMMIT;
     -- 
     END IF;
   END LOOP; 

--dbms_output.put_line('End Of File' ) ;
--*** < END FETCH LOOP     >  ****
--
-- Final commit
   COMMIT;

-- Now Run dedupe procedure--   
SP_DEDUPE_BSP_TRANSACTION;   

--
EXCEPTION
  --
  -- A serious error has occured
  --
  WHEN already_loaded THEN
--    IF v('APP_USER') IS NULL THEN 
       --dbms_output.put_line('Error') ;
       ---CANT RAISE APPLCATOIN ERROR AS WELL AS DOING core_dataw.sp_errors !!!!!!!--
       --core_dataw.sp_errors('BSP_TICKET','BSP_TICKET',SQLCODE,'Already Loaded  ' ||SQLERRM);

--    ELSE 
       raise_application_error(-20002,('Already Loaded - ' ||SQLERRM));
--    END IF;

  WHEN invalid_row THEN
    --IF v('APP_USER') IS NULL THEN 
      -- core_dataw.sp_errors('BSP_TICKET','BSP_TICKET',SQLCODE,'Invalid Row - Sequence No '||v_sequence_no||' Sql Error: ' ||SQLERRM);
    --ELSE 
       raise_application_error(-20003,('Invalid Row - Sequence No '||v_sequence_no||' Sql Error: '||SQLERRM));
   --END IF;

  WHEN OTHERS THEN


    --
--    IF v('APP_USER') IS NULL THEN 
--       core_dataw.sp_errors('BSP_TRANSACTION','BSP_TRANSACTION',SQLCODE,TO_CHAR(V_TICKET_NO) || ' - ' ||SQLERRM);
--    ELSE 
        IF v_ticket_no IS NULL THEN
        raise_application_error(-20001,('Other Error - Sequence No'||v_sequence_no||' Sql Error: '||SQLERRM));

        ELSE
        raise_application_error(-20001, (TO_CHAR(V_TICKET_NO) || ' - ' ||SQLERRM));
        END IF;
--    END IF;
    --    
END sp_l_bsp_transaction;