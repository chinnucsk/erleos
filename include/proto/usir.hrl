-ifndef(ERLEOS_PROTO_USIR_HRL).
-define(ERLEOS_PROTO_USIR_HRL, true).

-record (usir_status, {id        = 0 :: pos_integer(),
                       serial_nr = 0 :: pos_integer(),
                       voltage   = 0 :: pos_integer(),
                       wtime     = 0 :: pos_integer()}).

-record (usir_data, {type  = undefined :: us | ir | undefined,
                     id    = 0 :: pos_integer(),
                     time  = now() :: ts(),
                     value = 0 :: pos_integer(),
                     cycle = 0 :: pos_integer()}).

-endif.