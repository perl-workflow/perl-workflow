$VAR1 = {
          'persister' => 'TestPersister',
          'type' => 'Type2',
          'description' => 'This is a sample workflow of a different type',
          'state' => [
                     {
                       'action' => [
                                   {
                                     'name' => 'TIX_NEW',
                                     'resulting_state' => 'Ticket_Created'
                                   }
                                 ],
                       'name' => 'INITIAL',
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
