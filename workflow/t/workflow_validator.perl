$VAR1 = {
          'validator' => [
                         {
                           'name' => 'DateValidator',
                           'class' => 'Workflow::Validator::MatchesDateFormat',
                           'param' => [
                                      {
                                        'value' => '%Y-%m-%d %H:%M',
                                        'name' => 'date_format'
                                      }
                                    ],
                           'description' => 'Validator to ensure dates are proper'
                         }
                       ]
        };
