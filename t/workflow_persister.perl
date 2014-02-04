$VAR1 = {
	'persister' => [
                       {
                        'history_sequence' => 'wf_history_seq',
                        'name' => 'BackupDatabase',
                        'workflow_sequence' => 'wf_seq',
                        'workflow_table' => 'wf',
                        'password' => 'mypass',
                        'dsn' => 'DBI:Pg:dbname=workflows',
                        'user' => 'wf',
                        'class' => 'Workflow::Persister::DBI',
                        'history_table' => 'wf_history'
                       }
                    ]
        };
