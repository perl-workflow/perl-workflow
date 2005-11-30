CREATE TABLE workflow (
  workflow_id       int not null auto_increment,
  type              varchar(50) not null,
  state             varchar(30) not null,
  last_update       timestamp,
  primary key ( workflow_id )
);

CREATE TABLE workflow_history (
  workflow_hist_id  int not null auto_increment,
  workflow_id       int not null,
  action            varchar(25) not null,
  description       varchar(255) null,
  state             varchar(30) not null,
  workflow_user     varchar(50) null,
  history_date      timestamp,
  primary key( workflow_hist_id )
);

