$VAR1 = {
          'persister' => 'TestPersister',
          'type' => 'Type3',
          'description' => 'This is a sample workflow of yet a different type',
	  initial_state => 'START',
          'state' => [
                     {
                       'action' => [
                                   {
                                     'name' => 'TIX_NEW',
                                     'resulting_state' => 'Ticket_Created'
                                   }
                                 ],
                       'name' => 'START',
                       'description' => 'This is the state the workflow enters when
        instantiated. It\'s like a \'state zero\' but since we\'re
        using names rather than IDs we cannot assume'
                     },
                     {
                       'action' => [
                                   {
                                     'name' => 'Ticket_Close',
                                     'resulting_state' => 'Ticket_Closed',
                                     'condition' => [
                                                    {
                                                      'name' => 'HasUser'
                                                    }
                                                  ]
                                   }
                                 ],
                       'name' => 'Ticket_Created',
                       'description' => 'State of ticket after it has been created'
                     },
                     {
                       'name' => 'Ticket_Closed',
                       'description' => 'State of ticket after creator approves the work done'
                     }
                   ]
        };
