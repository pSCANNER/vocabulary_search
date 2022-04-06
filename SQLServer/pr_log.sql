SET ANSI_NULLS ON
go
SET QUOTED_IDENTIFIER ON
go
CREATE  PROCEDURE [dbo].[pr_log] (@log_message VARCHAR(2000))
/*
** UT: pr_log @log_message='Test Message'
*/
AS
BEGIN
DECLARE @batch_id int

	SELECT @batch_id = Convert(int, current_value) FROM sys.sequences WHERE name = 'SEQ_CRAWLER_BATCH_LOG' ;

    INSERT INTO crawler_log (created_on, batch_id,
                            created_by,
                            message)
        VALUES (getdate(),
                @batch_id,
                CURRENT_USER,
                @log_message);
END
go