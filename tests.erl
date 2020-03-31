-module(tests).
-export([tests/1]).

tests(Mod) ->
  testSimple(Mod).
  %testFullandEmpty(Mod).

testSimple(Mod) ->
    Buffer = spawn(Mod, buffer, [5]),
    Parent = self(),


    % Consumer
    spawn(fun () ->
       Buffer!{isEmptyQ, self()},
       receive
          empty -> empty,io:fwrite("passed D0 ~n");
          X0      -> io:fwrite("[D0] Consumer test fail. Buffer should be empty. Got ~w~n", [X0])
          after 1000 -> io:fwrite("[D0] Consumer test fail. Buffer should be empty but timed out.~n")
       end,
       receive
          notEmpty -> notEmpty,io:fwrite("passed D1 ~n");
          X1      -> io:fwrite("[D1] Consumer test fail. Buffer should be notEmpty. Got ~w~n", [X1])
          after 1000 -> io:fwrite("[D1] Consumer test fail. Buffer should be notEmpty but timed out.~n")
       end,

       Buffer!{getData, self()},
       receive
          {data, "Helo"} -> Parent!done1,io:fwrite("passed D2 ~n");
          X2      -> io:fwrite("[D2] Consumer test fail. Should have received Helo data, but got ~w~n", [X2])
          after 1000 -> io:fwrite("[D2] Consumer test fail. Should have received Helo data, but timed out.~n")
       end end),


    % Producer
    spawn(fun () ->
      Buffer!{isFullQ, self()},
      receive
        notFull -> notFull,io:fwrite("passed D3 ~n");
        Y0      -> io:fwrite("[D3] Producer test fail. Buffer should be notFull. Got ~w~n", [Y0])
        after 1000 -> io:fwrite("[D3] Producer test fail. Buffer should be notFull but timed out.~n")
      end,
      Buffer!{data, "Helo"},
      Parent!done2 end),




    receive done1 ->
      receive done2 ->
        io:fwrite("Test for simple interactions done.~n")
      end
    end.




  testFullandEmpty(Mod) ->
    Buffer = spawn(Mod, buffer, [1]),
    Parent = self(),

    P = spawn(fun () ->
      % Wait for the consumer to tell us who they are
      receive {consumer, C} -> C end,
      % Buffer should be initially empty
      Buffer!{isFullQ, self()},
      receive
        notFull -> ok;
        X       -> io:fwrite("[0] Producer test fail. Empty buffer should be notFull. Got ~w~n", [X])
        after 1000 -> io:fwrite("[0] Producer test fail. Empty buffer should be notFull but timed out.~n")
      end,
      % Fill the buffer
      Buffer!{data, "Helo"},
      % Confirm it is indeed now full
      Buffer!{isFullQ, self()},
      receive
        full -> ok;
        Y    -> io:fwrite("[1] Producer test fail. Full buffer should be full. Got ~w~n", [Y])
        after 1000 -> io:fwrite("[1] Producer test fail. Full buffer should be full but timed out.~n")
      end,
      % Sync with consumer
      C!ack,
      %% Producer again to wait for the buffer to be not full
      receive
        notFull -> ok;
        Y5      -> io:fwrite("[5] Producer test fail. Buffer should now be empty but got.~w~n", [Y5])
        after 1000 -> io:fwrite("[5] Producer test fail. Buffer should now be empty but got timed out.~n")
      end,
      %% Producer again to rework
      receive sync -> ok end, %% WAIT FOR CONSUMER in this test
      Buffer!{data, "K"},
      Parent!done1
      end),

    spawn(fun () ->
      % Tell the producer who I am to do a bit of syncing later for this test
      P!{consumer, self()},
      % Wait to receive an ack from the producer in order to proceed
      receive ack -> ack end,
      % Consumer
      Buffer!{isEmptyQ, self()},
      receive
        notEmpty -> ok;
        Y2 -> io:fwrite("[2] Consumer test fail. Full buffer is notEmpty. Got ~w~n", [Y2])
        after 1000 -> io:fwrite("[2] Consumer test fail. Full buffer is notEmpty but timed out.~n")
      end,
      Buffer!{getData, self()},
      receive
        {data, "Helo"} -> ok;
        Y3 -> io:fwrite("[3] Consumer test fail. Should get 'Helo' string data. Got ~w~n", [Y3])
        after 1000 -> io:fwrite("[3] Consumer test fail. Should get 'Helo' string data but timed out.~n")
      end,
      %% Consumer again
      Buffer!{isEmptyQ, self()},
      receive
        empty -> ok;
        Y4 -> io:fwrite("[4] Consumer test fail. Buffer should be empty now. Got ~w~n", [Y4])
        after 1000 -> io:fwrite("[4] Consumer test fail. Buffer should be empty now but timed out.~n")
      end,
      P!sync,
      %% Consumer again
      receive
        notEmpty -> ok;
        Y6 -> io:fwrite("[6] Consumer test fail. Consumer should be reawakened but got ~w~n", [Y6])
        after 1000 -> io:fwrite("[6] Consumer test fail. Consumer should be reawakened but timed out.~n")
      end,
      Buffer!{getData, self()},
      receive
        {data, "K"} -> ok;
        Y7 -> io:fwrite("[7] Consumer test fail. Consumer should have got 'K': ~w~n", [Y7])
        after 1000 -> io:fwrite("[7] Consumer test fail. Consumer should have got 'K' but timed out.~n")
      end,
      Parent!done2
      end),
      receive done1 ->
        receive done2 ->
          io:fwrite("Test for more complex interactions of producer and consumers done.~n")
        end
      end.