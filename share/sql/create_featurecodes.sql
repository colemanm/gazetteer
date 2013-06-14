create table featurecodes (
  code varchar(1),
  class varchar(10),
  fcode varchar (10),
  label varchar(100),
  description varchar(1000)
 );

ALTER TABLE ONLY featurecodes
  ADD CONSTRAINT pk_fcode PRIMARY KEY (fcode);
