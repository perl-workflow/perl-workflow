CREATE TABLE workflow (
  workflow_id   %%INCREMENT%%,
  workflow_type varchar(50) not null,
  state         varchar(30) not null,
)

CREATE TABLE workflow_ticket (
  workflow_id int not null,
  ticket_id   int not null
)

CREATE TABLE workflow_history (
  workflow_history_id %%INCREMENT%%,
  workflow_id  int not null,
  state    varchar(30) not null,
  time,
  user,
  comment,
)

CREATE TABLE ticket (
 ...
 workflow_id   int not null,
)