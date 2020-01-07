create or replace PROCEDURE        sp_dedupe_bsp_transaction AS 
--===========================================================
-- SP_DEDUPE_BSP_TRANSACTION
-- dedupe BSP_TRANSACTION table after import processing
--
--===========================================================
-- Change History
--===========================================================
-- Date          Ver Who     Comment
-- 05-jun-19     1.0 tim     Original Version
--
-- @I:\MI\DarrenScott\Workspace\UK\Database\dtwlive\stella\procs\SP_DEDUPE_BSP_TRANSACTION.prc
--
-- exec sp_dedupe_bsp_transaction;
--
--===========================================================
--
--
g_sqlerrm   VARCHAR2(500) := '';

BEGIN
    dbms_output.put_line ('Start dedupe of BSP_TRANSACTION records:'||to_char(SYSDATE,'yy-mon-dd hh24:mi:ss'));

    BEGIN

        DELETE
        FROM BSP_TRANSACTION
        WHERE BSP_TRANS_ID IN
        (
            SELECT BSP_TRANS_ID
            FROM
            (
                SELECT 
                BSP_TRANS_ID
                ,TICKET_NO
                ,REFUND_DOCUMENT_NO
                ,TRANSACTION_CODE
                ,TRUNC(BSP_PERIOD_ENDING_DATE)
                ,TRUNC(ENTRY_DATE_TIME)
                ,IATA_NUM
                ,BSP_FILENAME
                ,BSP_CRS_CODE
                ,BALANCE_PAYABLE_AMT
                ,ROW_NUMBER() OVER (PARTITION BY TICKET_NO,REFUND_DOCUMENT_NO,TRANSACTION_CODE,TRUNC(BSP_PERIOD_ENDING_DATE),TRUNC(ENTRY_DATE_TIME),IATA_NUM,BSP_CRS_CODE,BALANCE_PAYABLE_AMT ORDER BY BSP_FILENAME) AS ROWNO
                FROM BSP_TRANSACTION
            ) NUMBERED_ROWS
            WHERE NUMBERED_ROWS.ROWNO > 1
        )
        ;

        COMMIT
        ;  

        EXCEPTION
            WHEN OTHERS THEN
                g_sqlerrm := substr(SQLERRM, 1, 500);
                ROLLBACK;
                dbms_output.put_line('Error performing dedupe of BSP_TRANSACTION records:'||g_sqlerrm);

    END
    ;

    dbms_output.put_line ('End dedupe of BSP_TRANSACTION records:'||to_char(SYSDATE,'yy-mon-dd hh24:mi:ss')); 

END sp_dedupe_bsp_transaction;
