%%% ==========================================================================
%%% @author Damian T. Dobroczy\\'nski <qoocku@gmail.com> <email>
%%% @since 2011-02-28
%%% @doc TODO: Add description to erleos_us_sensor_module
%%% @end
%%% ==========================================================================
-module  (erleos_us_sensor_module).
-author  ("Damian T. Dobroczy\\'nski <qoocku@gmail.com> <email>").
-behavior (erleos_sensor).
-include ("vsn").

%%% --------------------------------------------------------------------
%%% C l i e n t  A P I  E x p o r t s
%%% --------------------------------------------------------------------

-export ([]).

-include ("erleos/include/proto/sensor.hrl").
-include ("erleos/include/proto/usir.hrl").

%%% --------------------------------------------------------------------
%%% I n t e r n a l  e x p o r t s
%%% --------------------------------------------------------------------

-export ([init/1, option/2, convert_data/4, terminate/2]).

%%% --------------------------------------------------------------------
%%% M a c r o s
%%% --------------------------------------------------------------------

%%% --------------------------------------------------------------------
%%% R e c o r d s ,  T y p e s  a n d  S p e c s
%%% --------------------------------------------------------------------

%%% ============================================================================
%%% C l i e n t  A P I / E x p o r t e d  F u n c t i o n s
%%% ============================================================================

init (Options) when is_list(Options) ->
  {ok, {}}.

option (router, _) ->
  usir_can_router;
option (sensor, _) ->
  us_sensor;
option (type, _) ->
  us;
option (data_id, _) ->
  us_data_id.

convert_data (Id, Timestamp, Data, _) ->
  <<V:16/little, C>> = Data,
  {#usir_data{type  = us,
              value = V,
              cycle = C,
              time  = ?can_ts_to_now(Timestamp),
              id    = Id}, #raw_data{sid   = Id,
                                     ts    = ?can_ts_to_ms(Timestamp),
                                     value = Data}}. % TODO: Convert the US value and Timestamp to now()
  
terminate (_, _) -> ok.

%%% ============================================================================
%%% L o c a l  F u n c t i o n s
%%% ============================================================================

