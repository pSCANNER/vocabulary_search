# SQL Server Version of Vocabulary Search

## Procedure and Parameters
exec [database].[schema].pr_crawler_SQL_Server <br>
@param_database_src_name_    Source database to Query (can include schema name)<br>
@param_database_vocab_name_ OMOP vocabulary database (can include schema name) <br>
@param_run_db_               Database with Crawler procedures and tables (can include schema name) <br>

## Optional Parameters
@param_include_vocab_invalid   varchar(3) = 'Yes'  <br>
@sampleRows					   bit		   = 1    -- 1 will sample rows using newID(), 0 otherwise
@param_num_records_to_read	   int		     = 5000 --  0 - read all <br>
@param_min_records_to_consider int         = 5000 -- minimum number of records for table considered a fact table <br>
@param_percent_unique_cut_off  int         = 75   -- Percent of Unique code to consider the column as a lookup <br>
@p_param_percent_min_domain    int         = 20   -- At least so many percent of column values to be available <br>
@param_min_unique_codes        int         = 100  -- Have to have at least so many unique (different) codes <br>
@param_percent_min_match       int         = 25  -- Min percent of rows identified as codes <br>
@param_table_like              varchar(60) = '%'  -- '%' Will select all <br>
@param_table_not_like1         varchar(60) = 'xx' -- 'xx' Place 2 lower case xx to not use specific like <br>
@param_table_not_like2         varchar(60) = 'xx' <br>
@param_table_not_like3         varchar(60) = 'xx' <br>
@param_table_not_like4         varchar(60) = 'xx; <br>

## Preconditions
1. Create Crawler Tables -- see Crawler_tbls.txt
2. Populate the vocabulary list -- see vocabulary_list.sql
3. Create log procedure -- see pr_log.sql
4. Create crawler procedure -- see Crawler_procs.sql
5. Create crawler sequence -- see Crawler_Table_ddl.sql

** Note: ** If the crawler_vocab_concept table is already populated it is not recreated.  If changes are made to the vocabulary list then truncate crawler_vocab_concept so that it gets repopulated.

## Output
Table identifying source tables and columns that have codes of interest <br>
SELECT * FROM crawler_summary; <br>
<br>
Log of execution steps <br>
SELECT top 10 * FROM crawler_log ORDER BY created_on DESC;
## Procedure flow
### crawler_vocab_list 
Input: list of OHDSI vocabularies to check  
### crawler_table_list 
gets list of all tables in database/schema 
### crawler_vocab_concept
local table of concepts from vocab list

### crawler_column_list 
get columns for all table in database /schema 

### crawler_vocab_match 
for each table/column <br>
  * for each vocabulary  <br>
    *  number of rows that match vocabulary <br>
		
### crawler_domain_with_codes 
rows from crawler_vocab_match where there were matches to vocabulary codes
### crawler_table_fk_list
List foreign key relationships 

### crawler_summary 
rows from crawler_domain_with_code meeting code or lookup criteria <br>
rows from crawler_table_fk_list where the parent is a lookup table <br>
rows from crawler_domain_with_codes with columns that match the primary key of  lookup tables (pseudo foreign key relationship)
### crawler_log <br>
record of crawler procedure steps <br>

## Potential Improvements ##
Even it there is no Foreign Key to a look-up table, can determine the primary key for the lookup table and then check to see if that column exists in any other tables.

