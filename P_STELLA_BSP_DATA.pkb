create or replace PACKAGE BODY p_stella_bsp_data IS

  -- Author  : leigh ashton
  -- Created : 29/5/03
  -- Purpose : Defines the procedures and functions for the Stella system
  --         : bsp data loads



  -- Define the application key, used to retrieve properties from the registry
  -- and as the top level key for logging.
  v_app_key CHAR(8)  := 'STELBSPD';

----------------------------------------------------------------
----------------------------------------------------------------                      
  
  FUNCTION run_bsp_load(driverClass       VARCHAR2,
                       connectionURL   VARCHAR2,
                       dbUserID   VARCHAR2,
                       dbUserPwd VARCHAR2,
                       singleFileName VARCHAR2,
                       runMode   VARCHAR2
                       )
                       RETURN CHAR
  AS
  LANGUAGE JAVA
  NAME 'uk.co.firstchoice.stella.StellaBSPLoad.runBSPLoad(
     java.lang.String,
     java.lang.String,
     java.lang.String,
     java.lang.String,
     java.lang.String,
     java.lang.String
     )
     return java.lang.String'
  ;
  


----------------------------------------------------------------
----------------------------------------------------------------                      



 

  -----------------------------------------------------------------------------------------
  -----------------------------------------------------------------------------------------
  
  -- stored proc to insert a row from the bsp financial data
  -- called from java based BSP data load

FUNCTION insert_transaction (
         p_ticket_no IN NUMBER,
         p_transaction_code IN CHAR,
         p_bsp_filename IN CHAR,
         p_bsp_date IN DATE,
         p_crs_code IN CHAR,
         p_airline_num IN NUMBER,
         p_iata_num IN NUMBER,
         p_commissionable_amt IN NUMBER,
         p_commission_amt IN NUMBER,
         p_tax_amt IN NUMBER,  -- tax total
         p_net_fare_amt IN NUMBER,
         p_ccy_code IN CHAR,
         p_net_remit_ind IN CHAR,
         p_conjunction_ind IN CHAR,
         p_airline_penalty_amt IN NUMBER,
         p_balance_payable_amt IN NUMBER,
         p_ub_tax_amt IN NUMBER,
         p_gb_tax_amt IN NUMBER,
         p_remaining_tax_amt IN NUMBER    
                           ) RETURN CHAR IS 

                           
v_proc_name CHAR(8) := 'STLBSPIN';




v_error_statement VARCHAR2(150) := '';
ex_data_invalid EXCEPTION;

v_net_fare_amt        NUMBER(18,2) := 0;
v_commissionable_amt  NUMBER(18,2) := 0;
v_commission_amt      NUMBER(18,2) := 0;
v_tax_amt             NUMBER(18,2) := 0;
v_supp_commission_amt NUMBER(18,2) := 0;

v_ticket_no bsp_transaction.ticket_no%TYPE;
v_refund_document_no bsp_transaction.refund_document_no%TYPE;


BEGIN

   g_statement  := 10;
   -- dbms_output.put_line('Src:'||p_source_ind||' P:'||v_proc_name||' strt:'||to_char(sysdate,'dd-mon-yy hh24:mi:ss'));
   p_common.debug_message('tkt:'||         p_ticket_no||
         ' cd:'||p_transaction_code||
         ' file:'||p_bsp_filename||
         ' dt:'||p_bsp_date||
         ' crs:'||p_crs_code||
         ' air:'||p_airline_num||
         ' iata:'||p_iata_num||
         ' comable:'||p_commissionable_amt||
         ' comm:'||p_commission_amt||
         ' tax:'||p_tax_amt||
         ' net:'||p_net_fare_amt||
         ' nr:'||p_net_remit_ind||
         ' cnj:'||p_conjunction_ind||
         ' airpen:'||p_airline_penalty_amt||
         ' balpay:'||p_balance_payable_amt||
         ' ubtx:'||p_ub_tax_amt||
         ' gbtx:'||p_gb_tax_amt||
         ' remtx:'||p_remaining_tax_amt||
         ' ');

   
   -- validate passed values
   
 
     IF p_ticket_no IS NULL THEN
        v_error_statement := 'Error, ticket no. is blank';
        RAISE ex_data_invalid;
     END IF;
     
     -- note that this ticket number field is also used for refund document number
     
     IF p_bsp_filename IS NULL THEN
       v_error_statement := 'Error, filename blank';
       RAISE ex_data_invalid;
       
     END IF;
     IF p_bsp_date IS NULL THEN
       v_error_statement := 'Error, bspdate blank';
       RAISE ex_data_invalid;
     END IF;
     IF p_crs_code IS NULL THEN
       v_error_statement := 'Error, crs code blank';
       RAISE ex_data_invalid;
     END IF;
     IF p_airline_num IS NULL THEN
       v_error_statement := 'Error, airline blank';
       RAISE ex_data_invalid;
     END IF;
     IF p_iata_num IS NULL THEN
       v_error_statement := 'Error, iata blank';
       RAISE ex_data_invalid;
     END IF;
     IF p_commissionable_amt IS NULL THEN
       v_error_statement := 'Error, comm able amt blank';
       RAISE ex_data_invalid;
     END IF;
     IF p_commission_amt IS NULL THEN
       v_error_statement := 'Error, comm amt blank';
       RAISE ex_data_invalid;
     END IF;
     
     IF p_airline_penalty_amt IS NULL THEN
       v_error_statement := 'Error, penalty amt blank';
       RAISE ex_data_invalid;
     END IF;

     IF p_balance_payable_amt IS NULL THEN
       v_error_statement := 'Error, bal payable amt blank';
       RAISE ex_data_invalid;
     END IF;
     
     IF p_tax_amt IS NULL THEN
       v_error_statement := 'Error, tax amt blank';
       RAISE ex_data_invalid;
     END IF;
     
     IF p_ub_tax_amt IS NULL THEN
       v_error_statement := 'Error, ub tax amt blank';
       RAISE ex_data_invalid;
     END IF;
          
     IF p_gb_tax_amt IS NULL THEN
       v_error_statement := 'Error, gb tax amt blank';
       RAISE ex_data_invalid;
     END IF;
     
     
     IF p_remaining_tax_amt IS NULL THEN
       v_error_statement := 'Error, rem. tax amt blank';
       RAISE ex_data_invalid;
     END IF;

        
     IF p_net_fare_amt IS NULL THEN
       v_error_statement := 'Error, net fare blank';
       RAISE ex_data_invalid;
     END IF;
     IF p_ccy_code IS NULL THEN
       v_error_statement := 'Error, currency code is blank';
       RAISE ex_data_invalid;
     END IF;

     IF p_net_remit_ind IS NULL THEN
       v_error_statement := 'Error, net remit ind is blank';
       RAISE ex_data_invalid;
     END IF;
     
     IF p_net_remit_ind NOT IN ('Y','N') THEN
       v_error_statement := 'Error, net remit ind is not Y/N';
       RAISE ex_data_invalid;
     END IF;
     
     IF p_conjunction_ind NOT IN ('Y','N') THEN
       v_error_statement := 'Error, conjunction ind is not Y/N';
       RAISE ex_data_invalid;
     END IF;
     
     
     
     
     
   g_statement  := 20;
   p_common.debug_message(g_statement);  
   IF NOT app_util.is_number(p_ticket_no) THEN
      v_error_statement := 'Error, ticket no. is not numeric';
      RAISE ex_data_invalid;
   END IF;
   IF NOT app_util.is_number(p_iata_num) THEN
      v_error_statement := 'Error, iata no. is not numeric';
      RAISE ex_data_invalid;
   END IF;
   IF NOT app_util.is_number(p_airline_num) THEN
      v_error_statement := 'Error, airline no. is not numeric';
      RAISE ex_data_invalid;
   END IF;
   IF NOT app_util.is_number(p_commission_amt) THEN
      v_error_statement := 'Error, comm amt is not numeric';
      RAISE ex_data_invalid;
   END IF;
   IF NOT app_util.is_number(p_commissionable_amt) THEN
      v_error_statement := 'Error, commable amt is not numeric';
      RAISE ex_data_invalid;
   END IF;
   IF NOT app_util.is_number(p_tax_amt) THEN
      v_error_statement := 'Error, tax amt. is not numeric';
      RAISE ex_data_invalid;
   END IF;
   
   IF NOT app_util.is_number(p_ub_tax_amt) THEN
      v_error_statement := 'Error, ub tax amt is not numeric';
      RAISE ex_data_invalid;
   END IF;
   IF NOT app_util.is_number(p_gb_tax_amt) THEN
      v_error_statement := 'Error, gb tax amt is not numeric';
      RAISE ex_data_invalid;
   END IF;
   IF NOT app_util.is_number(p_remaining_tax_amt) THEN
      v_error_statement := 'Error, rem. tax amt is not numeric';
      RAISE ex_data_invalid;
   END IF;

   
   IF NOT app_util.is_number(p_net_fare_amt) THEN
      v_error_statement := 'Error, net fare is not numeric';
      RAISE ex_data_invalid;
   END IF;
   
   g_statement  := 30;
   p_common.debug_message(g_statement);
   IF length(p_ticket_no) > 12 THEN
      v_error_statement := 'Error, ticket no too long';
      RAISE ex_data_invalid;
   END IF;
   IF length(p_airline_num) > 3 THEN
      v_error_statement := 'Error, airline too long';
      RAISE ex_data_invalid;
   END IF;
   IF length(p_iata_num) > 10 THEN
      v_error_statement := 'Error, iata no too long';
      RAISE ex_data_invalid;
   END IF;
   IF length(p_bsp_filename) > 32 THEN
      v_error_statement := 'Error, filename too long';
      RAISE ex_data_invalid;
   END IF;
   IF length(p_transaction_code) > 3 THEN
      v_error_statement := 'Error, tran code too long';
      RAISE ex_data_invalid;
   END IF;
   IF length(p_crs_code) > 4 THEN
      v_error_statement := 'Error, crs code too long';
      RAISE ex_data_invalid;
   END IF;
   IF length(p_net_fare_amt) > 16 THEN
      v_error_statement := 'Error, net fare too long';
      RAISE ex_data_invalid;
   END IF;
   IF length(p_commission_amt) > 16 THEN
      v_error_statement := 'Error, comm amt too long';
      RAISE ex_data_invalid;
   END IF;
   IF length(p_commissionable_amt) > 12 THEN
      v_error_statement := 'Error, commable amt too long';
      RAISE ex_data_invalid;
   END IF;
   IF length(p_tax_amt) > 12 THEN
      v_error_statement := 'Error, tax amt too long';
      RAISE ex_data_invalid;
   END IF;
   IF length(p_ub_tax_amt) > 12 THEN
      v_error_statement := 'Error, ub tax amt too long';
      RAISE ex_data_invalid;
   END IF;
   IF length(p_gb_tax_amt) > 12 THEN
      v_error_statement := 'Error, gb tax amt too long';
      RAISE ex_data_invalid;
   END IF;
   IF length(p_remaining_tax_amt) > 12 THEN
      v_error_statement := 'Error, rem. tax amt too long';
      RAISE ex_data_invalid;
   END IF;
   
   
   
   g_statement  := 40;
   IF p_bsp_date < '1-jan-2003' THEN   
      v_error_statement := 'Error, bsp date too old. Cannot be pre2003';
      RAISE ex_data_invalid;
   END IF;
   IF p_bsp_date > SYSDATE + 365 THEN   
      v_error_statement := 'Error, bsp date too much in future. Cannot be a year away';
      RAISE ex_data_invalid;
   END IF;
   
   g_statement  := 50;
   p_common.debug_message(g_statement);
   
   -- commission amt is stored as -ve (debit) in bsp file, we want to store it as +ve, so....
   v_commission_amt := p_commission_amt * -1;   
   
   -- now do business rules to work out the key financial amounts
   IF p_transaction_code IN ('MCO','MPD','TKT','CAN') THEN
      v_ticket_no := p_ticket_no;
      v_refund_document_no := NULL;
      v_net_fare_amt := p_net_fare_amt;
      v_commissionable_amt := p_commissionable_amt;
      v_tax_amt := p_tax_amt; 
      
     /* Removed this validation from David Hill's request, 
     this was making BSP hang and not loading BSP file
     
     IF p_airline_penalty_amt <> 0 THEN
        v_error_statement := 'Error, ticket trans type , but has airline penalty set';
        RAISE ex_data_invalid;
      END IF;  
     */
     
   ELSE
      v_ticket_no := NULL;
      v_refund_document_no := p_ticket_no;
      -- refund amounts come in as negative numbers
      
      v_net_fare_amt := p_net_fare_amt;
      v_commissionable_amt := p_commissionable_amt;
      v_tax_amt := p_tax_amt; 
      
   END IF;
   
   
   IF p_net_remit_ind = 'Y'
   AND v_net_fare_amt <> v_commissionable_amt 
   AND v_commissionable_amt <> 0 THEN
     v_supp_commission_amt := v_commissionable_amt - v_net_fare_amt - v_commission_amt;
   ELSE
     v_supp_commission_amt := 0;
   END IF;
     
   
   
   
   INSERT INTO bsp_transaction 
   (bsp_trans_id,
    ticket_no, 
    refund_document_no,
    transaction_code, 
    bsp_filename, 
    bsp_period_ending_date, 
    entry_date_time, 
    entry_user_id, 
    bsp_crs_code, 
    reconciled_ind, 
    last_reconciled_date, 
    airline_num, 
    iata_num, 
    tax_amt, 
    supp_commission_amt,
    commissionable_amt,
    commission_amt,
    net_fare_amt,
    ccy_code,
    conjunction_ind,
    stella_seat_amt,
    stella_tax_amt,
    airline_penalty_amt,
    balance_payable_amt,
    net_remit_ind,
    ub_tax_amt,
    gb_tax_amt,
    remaining_tax_amt
    )
    VALUES
    (bsp_transaction_seq.NEXTVAL,
    v_ticket_no,
    v_refund_document_no,
    decode(p_transaction_code,'SSA','MAN',p_transaction_code),
    p_bsp_filename,
    p_bsp_date,
    SYSDATE,
    USER,
    p_crs_code,
    'N', -- reconciled_ind   
    NULL,
    p_airline_num,
    p_iata_num,
    v_tax_amt,
    v_supp_commission_amt,
    v_commissionable_amt,
    v_commission_amt,
    v_net_fare_amt,
    p_ccy_code,
    p_conjunction_ind,
    0, -- stella_seat_amt
    0, -- stella_tax_amt
    p_airline_penalty_amt,  -- should only be populated on refunds
    p_balance_payable_amt,
    p_net_remit_ind,
    p_ub_tax_amt,
    p_gb_tax_amt,
    p_remaining_tax_amt
    );
    
    
    -- there is no update of existing data    
   



   g_statement  := 999;

   p_common.debug_message('Proc:'||v_proc_name||' ended:'||to_char(sysdate,'dd-mon-yyyy hh24:mi:ss'));
   
   -- commit control is handled in calling program
   RETURN null;
   

EXCEPTION
WHEN ex_data_invalid THEN
ROLLBACK;
RETURN v_error_statement;

WHEN OTHERS THEN

g_sqlerrm := substr(sqlerrm,1,150);
g_sqlcode := sqlcode;
ROLLBACK;
p_common.debug_message('Excp others, state:'||g_statement);

v_error_statement := ' Statement:'||to_number(g_statement);
p_common.debug_message(v_error_statement||' '||g_sqlcode);
/*IF g_sqlcode = -2291 THEN
   -- foreign key raised, give decent error message to users
   v_error_statement := '(fk) '||f_format_fk_statement(g_sqlerrm);
ELSE
   -- other error, just send back sqlerrm
   v_error_statement := v_error_statement||' '||g_sqlerrm;
END IF;
*/

v_error_statement := v_error_statement||' '||g_sqlerrm;
p_common.debug_message(v_error_statement);

RETURN 'Error, '||v_error_statement;



END insert_transaction;  -- end function

  
-----------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------
 /* return all bsp related details for all linked bsp transactions as a result set 
   -- may return more than one row if mor than one bsp transaction for a ticket / refund doc  */                    
  FUNCTION get_bsp_tran_details (p_ticket_no NUMBER, p_refund_document_no NUMBER, p_bsp_trans_id NUMBER)                              
                      RETURN p_stella_bsp_data.return_refcursor IS                      
  
  
  v_result p_stella_get_data.return_refcursor;
  
  BEGIN
     -- parameters are mutually exclusive
     IF p_ticket_no IS NULL AND p_refund_document_no IS NULL AND p_bsp_trans_id IS NULL THEN
        RAISE_application_error(-20111, 'Error, no parameter specified to retrieve bsp tran details');
     END IF;
     
     IF p_ticket_no IS NOT NULL AND p_refund_document_no IS NOT NULL THEN
        RAISE_application_error(-20111, 'Error, cannot have ticket number and refund number passed as parameters');     
     END IF;
     
         
  
  
      OPEN v_result FOR
      -- may return more than one row if mor than one bsp transaction for a ticket / refund doc  
           SELECT decode(nvl(b.refund_document_no,0),0,'T','R') reconcile_type, -- gets set to T or R if ticket or refund
                b.airline_num,
                to_char(nvl(b.ticket_no,b.refund_document_no))  tkt_or_refund_num,
                b.bsp_crs_code,
                b.transaction_code,
                b.reason_code,
                b.bsp_period_ending_date,
                r.reason_type_code discrepancy_type,
                b.last_reconciled_date,
                b.commissionable_amt - b.supp_commission_amt - b.commission_amt bsp_seat_cost ,
                b.tax_amt,
                b.commissionable_amt - b.supp_commission_amt - b.commission_amt + b.tax_amt total_bsp_cost, -- total bsp cost
                b.stella_seat_amt,
                b.stella_tax_amt,
                b.stella_seat_amt + b.stella_tax_amt total_stella_cost, -- total stella cost
                (b.commissionable_amt - b.supp_commission_amt - b.commission_amt + b.tax_amt) - (b.stella_seat_amt + b.stella_tax_amt) unmatched_amt, -- unmatched amt
                r.short_desc reason_short_desc,
                b.bsp_trans_id bsp_trans_id,
                b.supp_commission_amt bsp_supp_comm_amt,
                b.commissionable_amt bsp_commissionable_amt,
                b.commission_amt bsp_commission_amt,                
                b.net_fare_amt bsp_net_fare_amt, 
                b.conjunction_ind,
                b.iata_num
            FROM 
               bsp_transaction b  ,
               reason r
            WHERE
                r.reason_code = b.reason_code
                /* optional parameters used in where clause */
            AND nvl(p_bsp_trans_id,b.bsp_trans_id) = b.bsp_trans_id
            AND (p_ticket_no IS NULL OR (p_ticket_no IS NOT NULL AND p_ticket_no = b.ticket_no))
            AND (p_refund_document_no IS NULL OR (p_refund_document_no IS NOT NULL AND p_refund_document_no = b.refund_document_no))            
            AND b.last_reconciled_date IS NOT NULL -- exclude those not reconciled yet            
            ORDER BY b.bsp_period_ending_date, to_char(nvl(b.ticket_no,b.refund_document_no))
               ;
               
      RETURN(v_result);               


END get_bsp_tran_details;

----------------------------------------------------------------
----------------------------------------------------------------                      
                      
END p_stella_bsp_data; -- end of package body