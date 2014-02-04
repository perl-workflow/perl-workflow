          'persister' => 'TestPersister',
          'type' => 'Ticket',
          'description' => 'This is the workflow for sample application Ticket',
          'state' => [
                     {
                       'action' => [
                                   {
                                     'name' => 'TIX_NEW',
                                     'resulting_state' => 'TIX_CREATED'
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
                                     'name' => 'TIX_COMMENT',
                                     'resulting_state' => 'NOCHANGE'
                                   },
                                   {
                                     'name' => 'TIX_EDIT',
                                     'resulting_state' => 'TIX_IN_PROGRESS',
                                     'condition' => [
                                                    {
                                                      'name' => 'HasUser'
                                                    }
                                                  ]
                                   }
                                 ],
                       'name' => 'TIX_CREATED',
                       'description' => 'State of ticket after it has been created'
                     },
                     {
                       'action' => [
                                   {
                                     'name' => 'TIX_CLOSE',
                                     'resulting_state' => 'TIX_CLOSED',
                                     'condition' => [
                                                    {
                                                      'name' => 'HasUser'
                                                    }
                                                  ]
                                   }
                                 ],
                       'name' => 'TIX_IN_PROGRESS',
                       'description' => 'State of ticket after developers start work'
                     },
                     {
                       'action' => [
                                   {
                                     'name' => 'TIX_REOPEN',
                                     'resulting_state' => 'TIX_CREATED',
                                     'condition' => [
                                                    {
                                                      'name' => 'HasUser'
                                                    }
                                                  ]
                                   }
                                 ],
                       'name' => 'TIX_CLOSED',
                       'description' => 'State of ticket after creator approves the work done'
                     }
                   ]
};
