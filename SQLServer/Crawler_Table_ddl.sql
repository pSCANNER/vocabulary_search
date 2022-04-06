
CREATE SEQUENCE SEQ_CRAWLER_BATCH_LOG
  START WITH 1  INCREMENT BY 1 ; 

CREATE TABLE crawler_column_list (
  table_id		int				NOT NULL,
  table_name	varchar (60)	NOT NULL,
  table_owner	varchar (60)	NOT NULL,
  column_name	varchar (60)	NOT NULL,
  column_order	int				NOT NULL,
  data_type		varchar (60)	NOT NULL,
  is_PK			int				NULL
)
	ON [PRIMARY]
go
CREATE TABLE crawler_domain_with_codes (
  table_id					int				NOT NULL,
  table_name				varchar (60)	NOT NULL,
  table_owner				varchar (60)	NOT NULL,
  column_name				varchar (60)	NOT NULL,
  domain_id					varchar (20)	NULL,
  is_PK						bit				NOT NULL default 0,
  num_records_read			int				NULL,
  not_null_records			int				NULL,
  num_domain_match			int				NULL,
  PERCENT_MATCH				int				NULL,
  num_domain_unique_match	int				NULL,
  percent_unique_match		int				NULL,
  is_lookup			        bit				NOT NULL default 0
)
	ON [PRIMARY]

go
CREATE TABLE CRAWLER_LOG (
  LOG_ID		int IDENTITY (1,1)	NOT NULL,
  BATCH_ID		int					NOT NULL,
  CREATED_ON	datetime			NULL,
  CREATED_BY	varchar (100)		NULL,
  MESSAGE		varchar (2000)		NULL
)
	ON [PRIMARY]
go
ALTER TABLE dbo.CRAWLER_LOG ADD CONSTRAINT PK_CRAWLER_LOG PRIMARY KEY CLUSTERED (LOG_ID)
	WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON)
	ON [PRIMARY]
go
CREATE TABLE crawler_table_fk_list (
  primary_table_name	varchar (60)	NOT NULL,
  primary_table_owner	varchar (60)	NOT NULL,
  primary_columns		varchar (2000)	NULL,
  foreign_table_name	varchar (60)	NOT NULL,
  foreign_table_owner	varchar (60)	NOT NULL,
  foreign_columns		varchar (2000)	NULL,
  constid				int				NULL,
  constraint_name		varchar (60)	NULL,
  p_constraint_name		varchar (60)	NULL
)
	ON [PRIMARY]
go
CREATE TABLE CRAWLER_TABLE_FK_MATCH (
  primary_table			varchar (60)	NOT NULL,
  primary_owner			varchar (60)	NOT NULL,
  primary_columns		varchar (2000)	NULL,
  foreign_table			varchar (60)	NOT NULL,
  foreign_owner			varchar (60)	NOT NULL,
  foreign_columns		varchar (2000)	NULL,
  NUM_TABLE_ROWS		int				NULL,
  DOMAIN_ID				varchar (20)	NULL,
  NUM_DOMAIN_MATCH_ROWS	int				NULL,
  PERCENT_DOMAIN_ROWS	int				NULL
)
	ON [PRIMARY]
go

CREATE TABLE crawler_table_list (
  table_id			int				NOT NULL,
  table_name		varchar (60)	NOT NULL,
  table_owner		varchar (60)	NOT NULL,
  num_records		int				NULL,
  num_records_read	int				NULL,
  is_lookup			bit				NOT NULL default 0,
  has_pk			bit				NOT NULL default 0
)
	ON [PRIMARY]
go
CREATE TABLE crawler_vocab_concept (
  concept_code	varchar(50)		NOT NULL
, vocabulary_name varchar(20)	NOT NULL  
, CONSTRAINT PK_Crawler_Vocab_Concept PRIMARY KEY(concept_code, vocabulary_name)
)
	ON [PRIMARY]
go

CREATE TABLE crawler_vocab_list
( vocabulary_name		varchar(20)	NOT NULL
, domain_id				varchar(20)	NOT NULL
, remove_decimal		bit			NOT NULL default 0
, minimum_code_length	smallInt	NOT NULL default 0
);
go
CREATE TABLE crawler_vocab_match (
  table_id					int				NOT NULL,
  table_name				varchar (60)	NOT NULL,
  table_owner				varchar (60)	NOT NULL,
  column_name				varchar (60)	NOT NULL,
  vocabulary_name			varchar (20)	NULL,
  domain_id					varchar (20)	NULL,
  num_records_read			int				NULL,
  num_records_match			int				NULL,
  not_null_records			int				NULL,
  num_records_unique_match	int				NULL,
  percent_match				int				NULL,
  percent_unique_match		int				NULL
)
	ON [PRIMARY]
go

/* summary table 
 */
 CREATE table crawler_summary
 ( table_schema varchar(60) NOT NULL
 , table_name   varchar(60) NOT NULL
 , column_name  varchar(60) NOT NULL
 , OMOP_domain	varchar(30) 
 , records_read  INT
 , records_with_code INT
 , unique_codes INT
 , include_reason varchar(250) NOT NULL
 ) ON [PRIMARY]
go
