%%% ==========================================================================
%%% @author Damian T. Dobroczy\\'nski <qoocku@gmail.com>
%%% @since 19-11-2010
%%% @doc TODO: Add description to mqueue
%%% @end
%%% ==========================================================================
-module (mqueue).
-author ("Damian T. Dobroczy\\'nski <qoocku@gmail.com>").

%%% ==========================================================================
%%% I n c l u d e d  F i l e s
%%% ==========================================================================

-include_lib ("eunit/include/eunit.hrl").
-include ("erleos/include/proto/mqueue.hrl").

%%% ==========================================================================
%%% E x p o r t e d  A P I  F u n c t i o n s
%%% ==========================================================================

-export ([open/1,
          open/2,
          close/1,
          recv/1,
          recv/2,
          send/2,
          send/3,
          props/1,
          parse_options/1]).

%%% ==========================================================================
%%% E x p o r t e d  S e r v e r  F u n c t i o n s
%%% ==========================================================================

-export ([start/1,
          start/2,
          start/3,
          start_link/3,
          stop/1,
          set_options/2,
          get_options/1]).

%%% ==========================================================================
%%% A P I  F u n c ti o n s
%%% ==========================================================================

-record (mq, {ref = make_ref() :: reference(),
              hnd              :: any()}).
-opaque mq ()          :: #mq{}.
-type mqueue_options() :: [{size, pos_integer()}   |
                           {msgsize, pos_integer()}|
                           {active, pid()}         |
                           own                     |
                           noblock].
    
-spec parse_options (mqueue_options()) -> {pos_integer(),
                                            pos_integer(),
                                            pid() | undefined,
                                            []|[noblock|own|{active, pid()}]}.

parse_options (Options) ->
  GetArg     = fun (Key, Def) ->
                 case lists:keyfind(Key, 1, Options) of
                   {Key, Size} -> Size;
                   false        -> Def
                 end
               end,
  QueueSize  = GetArg(size, 8),
  MaxMsgSize = GetArg(msgsize, 256),
  Pid        = GetArg(active, undefined),
  Rest       = lists:filter(fun
                             (ValidOpt) when ValidOpt =:= own ; 
                                              ValidOpt =:= noblock ->
                                true;
                             ({active, Pid}) when is_pid(Pid) ->
                                true;
                             ({size, I1}) when is_integer(I1) ->
                                false;
                             ({msgsize, I2}) when is_integer(I2) ->
                                false;                              
                             (Opt) ->
                                exit({badarg, Opt})
                            end, Options),
  {QueueSize, MaxMsgSize, Pid, Rest}.

-spec open (string()) -> {ok, mq()}.
-spec open (string(), mqueue_options()) -> {ok, mq()}.

open (QueueName) when is_list(QueueName) ->
  open(QueueName, []).

open (QueueName, Options) when is_list(QueueName), is_list(Options) ->
  {QueueSize, MaxMsgSize, Pid, Rest} = parse_options(Options),
  case mqueue_drv:open(QueueName, QueueSize, MaxMsgSize,
                        case Pid of 
                          undefined -> Rest;
                          _         -> [Pid | Rest]
                        end) of
      {ok, Q} -> {ok, #mq{hnd = Q}};
      Other   -> Other
  end.

-spec send (mq(), binary()) -> ok | {error, atom()}.
-spec send (mq(), binary(), non_neg_integer()) -> ok | {error, atom()}.

send (#mq{hnd = Q}, Binary) when is_binary(Binary) ->
  mqueue_drv:send(Q, Binary, 0).

send (#mq{hnd = Q}, Binary, Priority) when is_binary(Binary), is_integer(Priority) ->
  mqueue_drv:send(Q, Binary, Priority).

-type callback() :: fun((mq(), binary()) -> any()).
-spec recv (mq()) -> {ok, binary()}.
-spec recv (mq(), callback()) -> {error, any()} | any().

recv (#mq{hnd = Q}) ->
  mqueue_drv:recv(Q).

recv (#mq{hnd = Q}, Callback) when is_function(Callback) ->
  case mqueue_drv:recv(Q) of
    {ok, Msg} -> Callback(Q, Msg);
    Other     -> Other
  end.

-spec close (mq()) -> ok | {error, atom()}.

close (#mq{hnd = Q}) ->
  case mqueue_drv:close(Q) of
    0              -> ok;
    E = {error, _} -> E
  end.

-type mqueue_props() :: [own|noblock].
-spec props (mq()) -> {ok, mqueue_props()}.

props (#mq{hnd = Q}) ->
  {ok, mqueue_drv:props(Q)}.

%%% ==========================================================================
%%% S e r v e r  A P I
%%% ==========================================================================

start (QueueName) when is_list(QueueName) ->
  start(QueueName, self()).

start (QueueName, Receiver) when is_list(QueueName),
                                  is_pid(Receiver) ->
  start(QueueName, Receiver, []).

start (QueueName, Receiver, Options) when is_list(QueueName),
                                          is_pid(Receiver),
                                          is_list(Options) ->
  gen_server:start(mqueue_srv, [QueueName, Receiver, Options], []).

start_link (QueueName, Receiver, Options) when is_list(QueueName),
                                               is_pid(Receiver),
                                               is_list(Options) ->
  gen_server:start_link(mqueue_srv, [QueueName, Receiver, Options], []).

set_options (Srv, Options)
  when (is_pid(Srv) orelse is_atom(Srv)) andalso is_list(Options) ->
  gen_server:call(Srv, #options{oper = set, args = Options}).

get_options (Srv) when is_pid(Srv) orelse is_atom(Srv) ->
  gen_server:call(Srv, #options{oper = get}).

stop (Srv) ->
  gen_server:cast(Srv, shutdown).

%%% ==========================================================================
%%% I n t e r n a l / L o c a l  F u n c t i o n s
%%% ==========================================================================

