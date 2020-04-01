-module(rw468).
-compile(export_all).


% Task1
logger (Count) ->
    receive 
        %If any message received, output count + message
        Message -> io:fwrite("[~w] ~p ~n",[Count,Message]), logger(Count+1)
    end.



% Task2
consumer (Buffer,Logger,Count) ->
    %c0 -> c1
    Buffer!{isEmptyQ,self()}, Logger!"Consumer awoke, asking for data.",

    receive 
        %c1 -> c2
        empty ->
            Logger!"C: Buffer empty. I wait",
            receive 
                notEmpty -> 
                    subConsumer(Buffer,Logger, Count)
            end;
        %c1-> c3
        notEmpty -> 
            subConsumer(Buffer,Logger, Count)
    end.


subConsumer(Buffer, Logger,Count) ->
    %c3 -> c4
    Buffer!{getData,self()},
    Logger!"C: Asking for data.",
    receive
        %c4 -> c0
        {data,Msg} -> 
            Logger!("C: Got data: #" ++ integer_to_list(Count) ++ " = " ++ Msg),
            consumer(Buffer,Logger,Count+1)
    end.



buffer(MaxSize) ->buffer([], MaxSize, none, none).
buffer(BufferData, MaxSize, WaitingConsumer, WaitingProducer) ->

    receive 
        %%%%%%%%PRODUCER%%%%%%%%
        {isFullQ,WP} when length(BufferData) < MaxSize ->
            WP!notFull,
            buffer(BufferData, MaxSize, WaitingConsumer, WP);

        {isFullQ,WP} ->
            WP!full,
            buffer(BufferData, MaxSize, WaitingConsumer, WP);


        %%%%%%%%CONSUMER%%%%%%%%
        {isEmptyQ,WC} when length(BufferData) > 0 -> 
            WC!notEmpty,
            buffer(BufferData, MaxSize, WC, WaitingProducer);


        {isEmptyQ,WC} ->
            WC!empty,
            buffer(BufferData, MaxSize, WC, WaitingProducer);

           
        {getData,WC} ->  
                if length(BufferData) == 0 -> 
                    WC!{data,[]}, 
                    WaitingProducer!notFull,
                    buffer([],MaxSize, WC, WaitingProducer); 
                true ->
                    [Head|Tail] = BufferData,
                    WC!{data,Head}, 
                    WaitingProducer!notFull,
                    buffer(Tail,MaxSize, WC, WaitingProducer)
            end;


           
        {data,Msg} -> 
            if length(BufferData) == 0 ->
                if WaitingConsumer /= none -> WaitingConsumer!notEmpty;
                true -> pass end,
                buffer([Msg] , MaxSize, WaitingConsumer, WaitingProducer);
            true ->
                if WaitingConsumer /= none -> WaitingConsumer!notEmpty;
                true -> pass end,
                buffer([BufferData|Msg] , MaxSize, WaitingConsumer, WaitingProducer)
            end
                
            
    end.


main () ->
    B = spawn(?MODULE,buffer,[5]),
    L = spawn(?MODULE, logger,[0]),
    C = spawn(?MODULE,consumer,[B,L,0]),
    P = spawn(producer, producer,[5,L,B]).
    


