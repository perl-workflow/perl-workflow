CREATE TABLE ticket (
  ticket_id    varchar(8) not null primary key,
  type         varchar(10),
  subject      varchar(50) not null,
  description  text,
  creator      varchar(30) not null,
  status       varchar(30),
  due_date     varchar(10),
  last_update  varchar(20) not null
);

CREATE TABLE workflow_ticket (
  workflow_id  varchar(8) not null primary key,
  ticket_id    varchar(8) not null
);