$VAR1 = {
	  'type'   => 'Type2',
	  'description' => 'Actions for the Type2 workflow only.',
          'action' => [
                      {
                        'name' => 'TIX_NEW',
                        'class' => 'TestApp::Action::TicketCreateType',
                        'description' => 'Create a new ticket',
                        'validator' => [
                                       {
                                         'arg' => [
                                                  '$due_date'
                                                ],
                                         'name' => 'DateValidator'
                                       }
                                     ],
                        'field' => [
                                   {
                                     'is_required' => 'yes',
                                     'name' => 'subject',
                                     'label' => 'Subject',
                                     'description' => 'Subject of ticket'
                                   },
                                   {
                                     'is_required' => 'yes',
                                     'name' => 'description',
                                     'label' => 'Description',
                                     'description' => 'Text describing the problem and any details to reproduce, if possible'
                                   },
                                   {
                                     'is_required' => 'yes',
                                     'source_class' => 'TestApp::User',
                                     'name' => 'creator',
                                     'label' => 'Creator',
                                     'description' => 'Name of user who is creating the ticket'
                                   },
                                   {
                                     'is_required' => 'yes',
                                     'name' => 'type',
                                     'label' => 'Type',
                                     'description' => 'Type of ticket',
                                     'source_list' => 'Bug,Feature,Improvement,Task'
                                   },
                                   {
                                     'name' => 'due_date',
                                     'label' => 'Due Date',
                                     'description' => 'Date ticket is due (format: yyyy-mm-dd hh:mm)'
                                   }
                                 ]
                      },
                      {
                        'name' => 'Ticket_Close',
                        'class' => 'TestApp::Action::TicketUpdate',
                        'field' => [
                                   {
                                     'is_required' => 'yes',
                                     'name' => 'ticket_id',
                                     'description' => 'Ticket to close'
                                   },
                                   {
                                     'is_required' => 'yes',
                                     'name' => 'current_user',
                                     'description' => 'User closing the ticket'
                                   }
                                 ]
                      },
                    ]
        };
