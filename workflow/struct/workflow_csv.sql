CREATE TABLE workflow (
  workflow_id       varchar(8) not null primary key,
  type              varchar(50) not null,
  state             varchar(30) not null,
  last_update       varchar(20)
);

CREATE TABLE workflow_history (
  workflow_hist_id  varchar(8) not null primary key,
  workflow_id       varchar(8) not null,
  action            varchar(25) not null,
  description       varchar(255),
  state             varchar(30) not null,
  workflow_user     varchar(50),
  history_date      varchar(20)
);

