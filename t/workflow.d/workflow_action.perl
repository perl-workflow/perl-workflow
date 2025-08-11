$VAR1 = {
          'action' => [
                      {
                        'name' => 'TIX_NEW',
                        'class' => 'TestApp::Action::TicketCreate',
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
                        'name' => 'TIX_COMMENT',
                        'class' => 'TestApp::Action::TicketComment',
                        'field' => [
                                   {
                                     'is_required' => 'yes',
                                     'name' => 'ticket_id',
                                     'description' => 'Ticket to comment on'
                                   },
                                   {
                                     'is_required' => 'yes',
                                     'name' => 'comment',
                                     'description' => 'Comment to add'
                                   },
                                   {
                                     'is_required' => 'yes',
                                     'name' => 'current_user',
                                     'description' => 'User doing the commenting'
                                   }
                                 ]
                      },
                      {
                        'name' => 'TIX_EDIT',
                        'class' => 'TestApp::Action::TicketUpdate',
                        'field' => [
                                   {
                                     'is_required' => 'yes',
                                     'name' => 'ticket_id',
                                     'description' => 'Ticket to edit'
                                   },
                                   {
                                     'is_required' => 'yes',
                                     'name' => 'current_user',
                                     'description' => 'User working on the ticket'
                                   }
                                 ]
                      },
                      {
                        'name' => 'TIX_CLOSE',
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
                      {
                        'name' => 'TIX_REOPEN',
                        'class' => 'TestApp::Action::TicketUpdate',
                        'field' => [
                                   {
                                     'is_required' => 'yes',
                                     'name' => 'ticket_id',
                                     'description' => 'Ticket to reopen'
                                   },
                                   {
                                     'is_required' => 'yes',
                                     'name' => 'current_user',
                                     'description' => 'User reopening the ticket'
                                   }
                                 ]
                      },
                      {
                        'name' => 'null',
                        'class' => 'Workflow::Action::Null'
                      },
                      {
                        'name' => 'null2',
                        'class' => 'Workflow::Action::Null'
                      }
                    ]
        };
