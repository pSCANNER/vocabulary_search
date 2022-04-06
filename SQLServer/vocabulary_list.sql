/* 
   Add vocabularies the exist in the source data
   vocabulary_name -- OHDSI vocabulary_id
   domain_id       -- primary domain_id for vocabulary
   remove_decimal  -- 1 if the decimal point should be remove 
                      from the code for matching source code 0 otherwise
   minimum_code_length  -- use to eliminate nuisance matches of small integer values
   Sample below


*/
DELETE FROM crawler_vocab_list;



INSERT INTO crawler_vocab_list(vocabulary_name, domain_id, remove_decimal, minimum_code_length) VALUES ('CPT4', 'Procedure', '0', '4');
INSERT INTO crawler_vocab_list(vocabulary_name, domain_id, remove_decimal, minimum_code_length) VALUES ('HCPCS', 'Procedure', '0', '4');
INSERT INTO crawler_vocab_list(vocabulary_name, domain_id, remove_decimal, minimum_code_length) VALUES ('ICD10CM', 'Condition', '0', '4');
INSERT INTO crawler_vocab_list(vocabulary_name, domain_id, remove_decimal, minimum_code_length) VALUES ('ICD10PCS', 'Procedure', '0', '4');
INSERT INTO crawler_vocab_list(vocabulary_name, domain_id, remove_decimal, minimum_code_length) VALUES ('ICD9CM', 'Condition', '0', '4');
INSERT INTO crawler_vocab_list(vocabulary_name, domain_id, remove_decimal, minimum_code_length) VALUES ('ICD9Proc', 'Procedure', '0', '4');
INSERT INTO crawler_vocab_list(vocabulary_name, domain_id, remove_decimal, minimum_code_length) VALUES ('LOINC', 'Observation', '0', '4');
INSERT INTO crawler_vocab_list(vocabulary_name, domain_id, remove_decimal, minimum_code_length) VALUES ('NDC', 'Drug', '0', '11');
INSERT INTO crawler_vocab_list(vocabulary_name, domain_id, remove_decimal, minimum_code_length) VALUES ('RxNorm', 'Drug', '0', '4');
INSERT INTO crawler_vocab_list(vocabulary_name, domain_id, remove_decimal, minimum_code_length) VALUES ('SNOMED', 'Condition', '0', '4');