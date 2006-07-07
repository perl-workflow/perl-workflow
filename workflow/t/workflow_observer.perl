$VAR1 = {
          'persister' => 'TestPersister',
          'type' => 'ObservedTicket',
          'description' => 'This is the workflow for sample application Ticket',
          'state' => {
                     'CLOSED' => {
                                 'action' => {
                                             'name' => 'null',
                                             'resulting_state' => 'FIRST'
                                           }
                               },
                     'FIRST' => {
                                'action' => {
                                            'null' => {
                                                      'resulting_state' => 'PROGRESS'
                                                    },
                                            'null2' => {
                                                       'resulting_state' => 'NOCHANGE'
                                                     }
                                          }
                              },
                     'INITIAL' => {
                                  'action' => {
                                              'name' => 'null',
                                              'resulting_state' => 'FIRST'
                                            }
                                },
                     'PROGRESS' => {
                                   'action' => {
                                               'name' => 'null',
                                               'resulting_state' => 'CLOSED'
                                             }
                                 }
                   },
          'observer' => [
                        {
                          'class' => 'SomeObserver'
                        },
                        {
                          'sub' => 'SomeObserver::other_sub'
                        }
                      ]
        };
