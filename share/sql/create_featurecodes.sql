-- Create feature codes reference table

create table featurecodes (
  fcode varchar(10),
  name varchar(100),
  description varchar(200)
 );

ALTER TABLE ONLY featurecodes
  ADD CONSTRAINT pk_fcode PRIMARY KEY (fcode);
