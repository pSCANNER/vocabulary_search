SET ANSI_NULLS ON
go
SET QUOTED_IDENTIFIER ON
go

-- drop procedure pr_crawler_SQL_Server
CREATE procedure pr_crawler_SQL_Server
      @param_database_src_name_ varchar(128) 
    , @param_database_vocab_name_ varchar(128)
    , @param_crawler_db_ varchar(128)
/*
** Created By:  Mark Khayter
** Create Date: 5/6/2021
** Last Update: 3/15/2022 Matched latest Oracle code (V4)
**
** UT: exec pr_crawler_SQL_Server

** SELECT max(batch_id) FROM crawler_log
** SELECT * FROM crawler_log WHERE batch_id=1
** SELECT * FROM crawler_table_list
** SELECT * FROM crawler_column_list
** SELECT * FROM crawler_table_fk_list
** SELECT * FROM crawler_vocab_match
** SELECT * FROM crawler_domain_with_codes
** SELECT * FROM crawler_table_fk_list
** SELECT * FROM crawler_table_fk_match

	Change Log
	Who		When			What
	dtk		23Mar2022		database name can include schema
	dtk		29Mar2022		Use local concept table with only concepts from the vocab list
	dtk		FoolsDay2022	Use local table copy of source table
*/
AS 
BEGIN
 /* the input argument defined here for testing 
declare @param_database_src_name_ varchar(128) = 'd2i.stage'
     , @param_database_vocab_name_ varchar(128) = 'vocab5.v5_dec_2021'
     , @param_crawler_db_ varchar(128) = 'vocabulary_search'; 
 */

DECLARE @sSQL varchar(max),
		@param_database_src_name       varchar(128) ,
		@param_schema_src_name		   varchar(123) ,
		@param_database_vocab_name     varchar(128) ,
		@param_schema_vocab_name       varchar(128) ,
		@param_crawler_db			   varchar(128) , -- DB from which search is executed (crawler tables)
		@param_crawler_schema		   varchar(128) ,
		@param_include_vocab_invalid   varchar(3)  = 'Yes' ,
		@param_num_records_to_read	   int		   = 5000, --  0 - read all
		@param_min_records_to_consider int         = 5000, --  0 - read all
		@param_percent_unique_cut_off  int         = 75, --- Percent of Unique code to consider the column as a lookup
		@param_percent_min_domain      int         = 20, --- At least so many percent of column values to be available
        @param_min_unique_codes        int         = 250, --- Have to have at least so many unique (different) codes
		@param_min_match			   int		   = 25,  --- Min % of rows identified as codes
        @param_table_like              varchar(60) = '%', --- '%' Will select all
        @param_table_not_like1         varchar(60) = 'xx',--- 'xx' Place 2 lower case xx to not use specific like
        @param_table_not_like2         varchar(60) = 'xx',
        @param_table_not_like3         varchar(60) = 'xx',
        @param_table_not_like4         varchar(60) = 'xx',
		@log_message				   varchar(250),
		@sampleRows					   bit		   = 1 ,
		@sampleRowsText				   varchar(30) = ' ORDER BY newID()';	

	SELECT NEXT VALUE FOR SEQ_CRAWLER_BATCH_LOG;

	truncate table crawler_table_List;

	exec pr_log @log_message='START Crawler' ;

	/* used schema if passed in else default schema to dbo 
	 */
	declare @nameLen int ;
	declare @schemaStart int ;

	SET @nameLen = len(@param_database_src_name_);
	SET @schemaStart = charIndex('.', @param_database_src_name_) ;

	IF @schemaStart > 0
		BEGIN
			Set @param_database_src_name = subString(@param_database_src_name_, 1, @schemaStart - 1);
			Set @param_schema_src_name = subString(@param_database_src_name_, @schemaStart + 1, 99  );
		END
	ELSE BEGIN
				Set @param_database_src_name = @param_database_src_name_;
				Set @param_schema_src_name = 'dbo';
		END

    SET @nameLen = len(@param_database_vocab_name_);
	SET @schemaStart = charIndex('.', @param_database_vocab_name_) ;

	IF @schemaStart > 0
		BEGIN
			Set @param_database_vocab_name = subString(@param_database_vocab_name_, 1, @schemaStart - 1);
			Set @param_schema_vocab_name = subString(@param_database_vocab_name_, @schemaStart + 1, 99  );
		END
	ELSE BEGIN
				Set @param_database_vocab_name = @param_database_vocab_name_;
				Set @param_schema_vocab_name = 'dbo';
		END

    SET @nameLen = len(@param_crawler_db_);
	SET @schemaStart = charIndex('.', @param_crawler_db_) ;

	IF @schemaStart > 0
		BEGIN
			Set @param_crawler_db = subString(@param_crawler_db_, 1, @schemaStart - 1);
			Set @param_crawler_schema = subString(@param_crawler_db_, @schemaStart + 1, 99  );
		END
	ELSE BEGIN
				Set @param_crawler_db = @param_crawler_db_;
				Set @param_crawler_schema = 'dbo';
		END

	IF @sampleRows = 0 SET @sampleRowsText = ''; 

 /* get list of table to process */
	SET @sSQL = 
	 'INSERT INTO crawler_table_List (table_id, table_name, table_owner) ' +
		'SELECT id, NAME , OBJECT_SCHEMA_NAME(id,  DB_ID ( '''+ @param_database_src_name + ''' ))  AS schema_name '  +
	'  FROM ' + @param_database_src_name + '..sysobjects ' +
	' WHERE type = ''U''' +
	' AND OBJECT_SCHEMA_NAME(id,  DB_ID ( ''' + @param_database_src_name + ''' ))  = ''' +  @param_schema_src_name + '''';

	EXEC (@sSQL)

/* populate local concept table if empty */
DECLARE @rowCount int;
SET @rowCount = (SELECT count(*) FROM crawler_vocab_concept);

IF @rowCount = 0
BEGIN

	DECLARE @vocabulary_name varchar(20),
			@remove_decimal bit,
			@minimum_code_length int;

		DECLARE vocabList_cursor CURSOR FOR
		SELECT vocabulary_name, remove_decimal, minimum_code_length
		FROM crawler_vocab_list;

		OPEN vocabList_cursor;
		FETCH NEXT FROM vocabList_cursor INTO @vocabulary_name, @remove_decimal, @minimum_code_length;
		WHILE @@FETCH_STATUS = 0
		BEGIN
			SET @sSQL =
				'INSERT INTO crawler_vocab_concept( concept_code, vocabulary_name )' +
			   ' SELECT CASE ' + CAST(@remove_decimal AS CHAR(1) ) +
						 ' WHEN 0 THEN concept.concept_code ' + 
			 			 ' WHEN 1 THEN replace(concept.concept_code, ''.'', '''' )' +
					  ' END AS concept_code , vocabulary_id' +
				' FROM ' + @param_database_vocab_name + '.' + @param_schema_vocab_name + '.' + 'concept' +
			   ' WHERE vocabulary_id = ''' + @vocabulary_name + '''' +
				' AND len(concept_code) >=' + CAST( @minimum_code_length AS varchar(3) ) +
				' AND (invalid_reason IS NULL OR ''' +  @param_include_vocab_invalid + '''=''Yes'')';
				;

			 EXEC (@sSQL)

			 FETCH NEXT FROM vocabList_cursor INTO @vocabulary_name, @remove_decimal, @minimum_code_length;
		END
		CLOSE vocabList_cursor ;
		DEALLOCATE vocabList_cursor ;

		exec pr_log @log_message='Vocabulary concept refreshed';
END; /* end if crawler crawler_vocab_concept has rows */


DECLARE @table_name varchar(128),
        @table_owner varchar(128),
		@column_name varchar(128),
		@table_id int,
		@num_records_read int,
		@domain_id varchar(20);

	-- Populate tables count
	DECLARE db_cursor CURSOR FOR 
		SELECT table_name, table_owner, table_id
		FROM crawler_table_List

	OPEN db_cursor  
	FETCH NEXT FROM db_cursor INTO @table_name, @table_owner, @table_id

	WHILE @@FETCH_STATUS = 0  
	BEGIN  
		SET @sSQL = 
			'UPDATE crawler_table_List SET num_records=' +
				'(SELECT count(*) FROM ' + @param_database_src_name + '.' + @table_owner + '.' + @table_name + ')' +
			'WHERE table_id=' + convert(varchar, @table_id)

		EXEC (@sSQL)

		FETCH NEXT FROM db_cursor INTO @table_name, @table_owner, @table_id
	END 

	CLOSE db_cursor  
	DEALLOCATE db_cursor 

	UPDATE crawler_table_List SET num_records_read =
		CASE 
			WHEN @param_num_records_to_read = 0 OR num_records <=@param_num_records_to_read THEN num_records
			ELSE @param_num_records_to_read
		END

	exec pr_log @log_message='Crawler tables populated';
	exec pr_log @log_message='Updated count for ';

	truncate table crawler_column_List;
	/* get column information for each table
	 */
	SET @sSQL =
	'INSERT INTO crawler_column_list (table_id, table_name, table_owner, column_name, column_order, data_type, is_PK) ' +
	'SELECT tab.object_id AS tableId, tab.name AS table_name, schemas.name as schema_name' +
		' , col.name as column_name, col.column_id as column_order' +
		' , type_name(col.system_type_id) as dataType, COALESCE(indexes.is_primary_key, 0) as is_PK'+
	  ' FROM ' + @param_crawler_db + '.' + @param_crawler_schema + '.crawler_table_List crawler' +
	  ' INNER JOIN ' + @param_database_src_name + '.sys.tables tab ON tab.object_id = crawler.table_id' +
	  ' INNER JOIN ' + @param_database_src_name + '.sys.schemas' +
			  ' ON schemas.schema_id = tab.schema_id' +
	  ' INNER JOIN ' + @param_database_src_name + '.sys.columns col' +
			  ' ON col.object_id = tab.object_id' +
	  ' LEFT OUTER JOIN ' + @param_database_src_name + '.sys.index_columns indexColumn' +
					' ON indexColumn.object_id = col.object_id' +
				   ' AND indexColumn.column_id = col.column_id' +
	  ' LEFT OUTER JOIN ' + @param_database_src_name + '.sys.indexes' +
				   ' ON indexes.object_id = indexColumn.object_id' +
				  ' AND indexes.index_id = indexColumn.index_id' +
				  ' AND indexes.is_primary_key = 1';

	EXEC (@sSQL)

	UPDATE crawler_table_list set has_pk = 1
	WHERE table_id IN
	( SELECT distinct table_id FROM crawler_column_list WHERE is_PK = 1);

	exec pr_log @log_message='Column list tables populated';

	truncate table crawler_vocab_match;

	-- Only fields with strings to compare

	DECLARE @tempTableName varchar(80);
	DECLARE @tableCursorTableName varchar(128);
	DECLARE @tableCursorTableOwner varchar(128);
	DECLARE @tableCursorTableId int;

	DECLARE vocab_cursor CURSOR FOR 
		SELECT vocabulary_name, domain_id
			FROM crawler_vocab_list;
	
	DECLARE tableCursor CURSOR FOR
		SELECT DISTINCT table_name, table_owner, table_id
		FROM crawler_column_list;

	OPEN tableCursor;
	FETCH NEXT FROM tableCursor INTO @tableCursorTableName, @tableCursorTableOwner, @tableCursorTableId
	WHILE @@FETCH_STATUS = 0  
	BEGIN
		begin transaction;

		set @tempTableName = 'temp_' + @tableCursorTableName;

	/* Calculate how many records to read */
		SELECT @num_records_read = num_records_read
		FROM crawler_table_list WHERE table_id=@tableCursorTableId;

	/* create temporary table of source rows */
		SET @sSQL = 'SELECT TOP ' + convert(varchar, @num_records_read) + ' * ' +
				 	 ' INTO ' + @tempTableName +
		             ' FROM ' + @param_database_src_name + '.' + @tableCursorTableOwner + '.' + @tableCursorTableName +
					 ' ' + @sampleRowsText + ';'

		exec(@sSQL)

		DECLARE db_cursor CURSOR FOR 
		SELECT table_name, table_owner, table_id, column_name
		FROM crawler_column_list
		WHERE table_name = @tableCursorTableName AND table_owner = @tableCursorTableOwner
		  AND data_type in ('varchar', 'char', 'nchar', 'nvarchar');

		OPEN db_cursor;
		FETCH NEXT FROM db_cursor INTO @table_name, @table_owner, @table_id, @column_name
		WHILE @@FETCH_STATUS = 0  
		BEGIN
			OPEN vocab_cursor  	
			FETCH NEXT FROM vocab_cursor INTO @vocabulary_name, @domain_id

			WHILE @@FETCH_STATUS = 0 
			BEGIN 
				SET @sSQL = 
					'INSERT INTO crawler_vocab_match ' +
						'(table_name, table_owner, table_id, column_name, ' + 
						' vocabulary_name, domain_id, num_records_match, num_records_unique_match, ' +
						'num_records_read) ' +
					'SELECT ''' + @table_name + ''', ''' + @table_owner + ''', ' + 
							convert(varchar, @table_id) + ', ''' + @column_name + ''' AS source_code, ' + 
							'''' + @vocabulary_name + ''', ' +
							'''' + @domain_id + ''', ' +
							'count(*) AS num_matches, ' + 
							'count(DISTINCT source_code) AS num_records_unique_match, ' +
							convert(varchar, @num_records_read) +
					' FROM ('  +
							'SELECT [' + @column_name + '] AS source_code ' +
							' FROM ' + @tempTableName +
							') T ' +
					'INNER JOIN crawler_vocab_concept C' +
						' ON C.concept_code=T.source_code' +
						' AND C.vocabulary_name=''' + @vocabulary_name + '''' ;
				EXEC (@sSQL)

				FETCH NEXT FROM vocab_cursor INTO @vocabulary_name, @domain_id
			END
			CLOSE vocab_cursor  
		/*	exec pr_log @log_message='Completed insert into crawler_vocab_match'; */

			SET @sSQL = 
				'UPDATE crawler_vocab_match SET not_null_records=' +
					' (SELECT count(*) FROM ' + @tempTableName + ' WHERE [' + @column_name + '] IS NOT NULL) ' +
				' WHERE table_id=' + convert(varchar, @table_id) + ' AND column_name=''' + @column_name + ''''

			EXEC (@sSQL)

			FETCH NEXT FROM db_cursor INTO @table_name, @table_owner, @table_id, @column_name

		END /*db_cursor */
		CLOSE db_cursor ;
		DEALLOCATE db_cursor ;

		set @sSQL = 'TRUNCATE TABLE ' + @tempTableName + ';'
		EXEC(@sSQL);
		set @sSQL = 'DROP TABLE ' + @tempTableName + ';'
		EXEC(@sSQL);

		commit transaction;
		FETCH NEXT FROM tableCursor INTO @tableCursorTableName, @tableCursorTableOwner, @tableCursorTableId;
	END /* table_cursor */
	DEALLOCATE vocab_cursor;
	CLOSE tableCursor;
	DEALLOCATE tableCursor;
	exec pr_log @log_message='Completed insert /Update crawler_vocab_match';

	UPDATE crawler_vocab_match SET 
		percent_match =
			CASE
				WHEN num_records_read > 0 THEN CAST(num_records_match AS FLOAT) * 100 / num_records_read
				ELSE 0
			END,
		percent_unique_match = 
			CASE
				WHEN num_records_match > 0 THEN CAST(num_records_unique_match AS FLOAT) * 100 / num_records_match
				ELSE 0
			END
	
	truncate table crawler_domain_with_codes;

	INSERT INTO crawler_domain_with_codes 
	   ( table_id, table_name, table_owner, column_name, is_PK, domain_id, num_records_read
	   , not_null_records, num_domain_match, percent_match, num_domain_unique_match, percent_unique_match)
	SELECT T.table_id, T.table_name, T.table_owner, T.column_name, C.is_PK, T.domain_id, 
	    num_records_read, 
		not_null_records, num_domain_match
	  , CASE WHEN not_null_records > 0 THEN (CAST(num_domain_match aS FLOAT) / not_null_records) * 100
									   ELSE 0
		END aS percent_match
	  , num_domain_unique_match, 
		CASE
			WHEN num_domain_match > 0 THEN (CAST(num_domain_unique_match aS FLOAT) / num_domain_match ) * 100
			ELSE 0
		END AS percent_unique_match
	FROM (
		SELECT table_id, table_name, table_owner, column_name, domain_id, num_records_read, not_null_records 
			 , IIF(sum(num_records_match) < not_null_records, sum(num_records_match), not_null_records ) AS num_domain_match
			 , sum(num_records_unique_match) AS num_domain_unique_match
		  FROM crawler_vocab_match 
		  GROUP BY table_id, table_name, table_owner, column_name, domain_id, num_records_read, not_null_records) T
	INNER JOIN crawler_column_list C ON C.table_id=T.table_id and C.column_name=T.column_name
	WHERE num_domain_match > 0
	
	/* this test fails if the PK for the table is numeric 
	UPDATE crawler_domain_with_codes SET is_lookup = 1 
	WHERE is_PK = 1
	  AND percent_unique_match >= @param_percent_unique_cut_off
	  AND  num_domain_unique_match >=  @param_min_unique_codes
	  AND percent_match >= @param_percent_min_domain;
    */

	UPDATE crawler_table_list SET is_lookup = 1
	WHERE table_id IN
	( SELECT distinct table_id 
	   FROM crawler_domain_with_codes 
	  WHERE percent_unique_match >= @param_percent_unique_cut_off
	    AND  num_domain_unique_match >=  @param_min_unique_codes
	    AND percent_match >= @param_percent_min_domain
	);

    /* get source table foreign keys
	 */
	truncate table crawler_table_fk_list;
	SET @sSQL = 
	'INSERT INTO ' + @param_crawler_db + '.' + @param_crawler_schema + '.' + 
	'crawler_table_fk_list (primary_table_name, primary_table_owner, primary_columns' +
	                     ', foreign_table_name, foreign_table_owner, foreign_columns' +
						 ', constraint_name )' +
	'SELECT pk_tab.name as primary_table, pk_schema.name' +
		 ', substring(column_names, 1, len(column_names)-1) as [pk_columns]' +
		 ', fk_tab.name as foreign_table, fk_schema.name ' +
		 ',  substring(column_names, 1, len(column_names)-1) as [fk_columns]' +
		 ',  fk.name as fk_constraint_name' +
	' FROM ' + @param_database_src_name + '.sys.foreign_keys fk' +
	' INNER JOIN ' + @param_database_src_name + '.sys.tables fk_tab' +
			' ON fk_tab.object_id = fk.parent_object_id' +
	' INNER JOIN ' + @param_database_src_name + '.sys.schemas fk_schema' +
				  ' ON fk_schema.schema_id = fk_tab.schema_id' +
	' INNER JOIN ' + @param_crawler_db + '.' + @param_crawler_schema +'.crawler_table_list ' +
			' ON crawler_table_list.table_id = fk_tab.object_id' +
	' INNER JOIN ' + @param_database_src_name + '.sys.tables pk_tab' +
			' ON pk_tab.object_id = fk.referenced_object_id' +
	' INNER JOIN ' + @param_database_src_name + '.sys.schemas pk_schema' +
				  ' ON pk_schema.schema_id = pk_tab.schema_id' +
	' CROSS APPLY (SELECT col.[name] + '', ''' +
				   ' FROM ' + @param_database_src_name + '.sys.foreign_key_columns fk_c' +
				   ' INNER JOIN ' + @param_database_src_name + '.sys.columns col' +
						   ' ON fk_c.parent_object_id = col.object_id' +
						  ' AND fk_c.parent_column_id = col.column_id' +
				  ' WHERE fk_c.parent_object_id = fk_tab.object_id' +
					' AND fk_c.constraint_object_id = fk.object_id' +
				  ' ORDER BY col.column_id for xml path ('''') ' + 
				 ' ) D (column_names)' +
	' order by schema_name(fk_tab.schema_id) + ''.'' + fk_tab.name,' +
	   ' schema_name(pk_tab.schema_id) + ''.'' + pk_tab.name';

exec pr_log @sSQL
	EXEC (@sSQL)

	exec pr_log @log_message='Loaded crawler_table_fk_list';

/*
 Update summary table
*/
	truncate table crawler_summary;

	INSERT INTO crawler_summary
	(table_schema, table_name, column_name, OMOP_domain, records_read, records_with_code, unique_codes, include_reason )
	SELECT table_owner, table_name, column_name, domain_id, num_records_read, num_domain_match, num_domain_unique_match, 'by concept table'
	FROM
	(
	select table_owner, table_name, column_name, domain_id, num_records_read, num_domain_match , num_domain_unique_match
		, ROW_NUMBER() OVER( partition by table_owner, table_name, column_name ORDER BY num_domain_unique_match ) AS rowNum
	FROM crawler_domain_with_codes 
	WHERE num_records_read >= @param_min_records_to_consider 
	  AND num_domain_unique_match >= @param_min_unique_codes
	  AND percent_match  >= @param_min_match
	)x
	WHERE rownum = 1;
/*
	FK to Lookup table
 */
    INSERT INTO crawler_summary( table_schema, table_name, column_name, include_reason ) 
	SELECT foreign_table_owner, foreign_table_name, foreign_columns, 'indirect: FK to lookup table ' + primary_table_name AS include_reason
	  FROM crawler_table_fk_list
	 WHERE primary_table_name IN
		(
			SELECT Table_name 
			  FROM crawler_table_list
			 WHERE is_lookup = 1
		);
/*
	Other potential relationships, Foreign key not defined, matching lookup table
	by column name
 */
	INSERT INTO crawler_summary( table_schema, table_name, column_name, include_reason ) 
	SELECT t_child.table_owner, t_child.table_name, t_child.column_name
	     , 'potential: FK to lookup table ' + lookup_table
	FROM crawler_column_list t_child
	JOIN
	( /* lookup table id, table_name and first column of primary key */
		SELECT t_lookup.table_id AS lookup_table_id, T_LOOKUP.TABLE_NAME as LOOKUP_TABLE
		     , C_LOOKUP_PK.COLUMN_NAME As LOOKUP_TABLE_PK
		FROM CRAWLER_TABLE_LIST T_LOOKUP
		JOIN crawler_column_list C_LOOKUP_PK on C_LOOKUP_PK.TABLE_ID = T_LOOKUP.TABLE_ID
		WHERE T_LOOKUP.IS_LOOKUP = 1 AND C_LOOKUP_PK.IS_PK = 1 and c_lookup_pk.column_order = 1
	) lookup ON lookup.LOOKUP_TABLE_PK = t_child.column_name 
			AND lookup.lookup_table_id != t_child.table_id
	AND not exists  /* not already in the summary table */
	( SELECT 'x'
		FROM crawler_summary
		WHERE crawler_summary.table_schema =  t_child.table_owner
		  AND crawler_summary.table_name = t_child.table_name
		  AND crawler_summary.column_name = t_child.column_name)
	ORDER BY lookup_table, t_child.table_name, t_child.column_name;

	exec pr_log @log_message='Completed execution!';

END