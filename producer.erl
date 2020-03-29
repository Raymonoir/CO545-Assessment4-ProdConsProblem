-module(producer).
-export([producer/3]).

%% Producer (PROVIDED CODE)

producer(0, _, _) -> ok;
producer(Count, Logger, Buffer) ->
  % Generate a random message string
  Msg = integer_to_list(round(rand:uniform()*10)),
  %% p0 -> p1
  Buffer!{isFullQ, self()},
  receive
    %% p1 -> p2
    full ->
      Logger!"P: Buffer full. I wait.",
      receive
        %% p2 -> p3
        notFull ->
          Logger!("P: Woke and putting data: " ++ Msg),
          producerGo(Count, Msg, Logger, Buffer)
      end;
    %% p1 -> p3
    notFull ->
      Logger!("P: Putting data: " ++ Msg),
      producerGo(Count, Msg, Logger, Buffer)
  end.

%% p3 -> p0
producerGo(Count, Msg, Logger, Buffer) ->
  Buffer!{data, Msg},
  producer(Count - 1, Logger, Buffer).