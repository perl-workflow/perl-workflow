CREATE TABLE ticket (
  ticket_id    int not null auto_increment,
  subject      varchar(50) not null,
  description  text null,
  creator_id   int not null,
  status       varchar(30) null,
  due_date     date null,
  last_update  timestamp,
  workflow_id  int not null,
  primary key( ticket_id )
)