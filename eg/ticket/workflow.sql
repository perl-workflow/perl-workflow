CREATE TABLE workflow (
    workflow_id int not null auto_increment,
    type        varchar(30) not null,
    state       varchar(30) not null,
    last_update timestamp,
    primary key( workflow_id )
)