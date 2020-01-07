create or replace PACKAGE P_STELLA_BSP_DATA IS
  -- Author  : leigh ashton
  -- Created : 03/01/03
  -- Purpose : Defines the procedures and functions for the Stella system
  --         : data extracts. These stored procedures / functions are used by java programs to 
  --         : read data from Oracle


  -- Public type declarations
  
--  amended:
-- nov 03 Leigh added breakdown of tax fields

  
  
  TYPE return_refcursor IS REF CURSOR;


  g_version NUMBER:= 1.06;
  g_statement NUMBER := 0;
  g_sqlerrm VARCHAR2(500);
  g_sqlcode CHAR(20);
  g_package_name     CONSTANT VARCHAR2(100) := 'STLBSPGD';
  g_debug BOOLEAN := FALSE;
  g_log_sequence jutil.application_log.log_sequence%TYPE;     

  
  
----------------------------------------------------------------
----------------------------------------------------------------                      
-- run_bsp_load is the call specification/wrapper to the java Stored procedure
  -- uk.co.firstchoice.stella.StellaBSPLoad.runBSPLoad
  -- It loads transactions from source files in file system
  -- The routine
  -- is configured via the application registry (JUTIL.APPLICATION_REGISTRY)  
FUNCTION run_bsp_load(driverClass       VARCHAR2,
                       connectionURL   VARCHAR2,
                       dbUserID   VARCHAR2,
                       dbUserPwd VARCHAR2,
                       singleFileName VARCHAR2,
                       runMode   VARCHAR2
                       )
                       RETURN CHAR;

----------------------------------------------------------------
----------------------------------------------------------------                      
                       
                       
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
         p_tax_amt IN NUMBER, -- tax total
         p_net_fare_amt IN NUMBER,
         p_ccy_code IN CHAR,
         p_net_remit_ind IN CHAR,
         p_conjunction_ind IN CHAR,
         p_airline_penalty_amt IN NUMBER,
         p_balance_payable_amt IN NUMBER,
         p_ub_tax_amt IN NUMBER,
         p_gb_tax_amt IN NUMBER,
         p_remaining_tax_amt IN NUMBER
                           ) RETURN CHAR;
----------------------------------------------------------------
----------------------------------------------------------------                      


  
 /* return all bsp related details for all linked bsp transactions as a result set 
   -- may return more than one row if mor than one bsp transaction for a ticket / refund doc  */                    
 /* params are mutually exclusive, but one must be passed */
  FUNCTION get_bsp_tran_details (p_ticket_no NUMBER, p_refund_document_no NUMBER, p_bsp_trans_id NUMBER)
                               
                      RETURN p_stella_bsp_data.return_refcursor;
----------------------------------------------------------------
----------------------------------------------------------------          



end P_STELLA_BSP_DATA;   -- end of package HEADER