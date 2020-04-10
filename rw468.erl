-module(rw468).
-compile(export_all).


% Task1
logger (Count) ->
    receive 
        %If any message received, output count + message
        Message -> io:fwrite("[~w] ~p ~n",[Count,Message]), logger(Count+1)
    end.



% Task2
% Consumer recieves messages from the buffer and keeps count of these messages
consumer (Buffer,Logger,Count) ->
    %c0 -> c1
    Buffer!{isEmptyQ,self()},

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

%Sub consumer is only called by consumer when it receives noEmpty
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


%Task 3
%Acts as a data store to be accesses by both consumer and producer concurrently
buffer(MaxSize) ->buffer([], MaxSize, none, none).
buffer(BufferData, MaxSize, WaitingConsumer, WaitingProducer) ->

    receive 
        %%%%%%%%PRODUCER%%%%%%%%
        {isFullQ,WP} when length(BufferData) < MaxSize ->
            WP!notFull,
            buffer(BufferData, MaxSize, WaitingConsumer, WP);


        {isFullQ,WP} ->
            WP!full,
            buffer(BufferData, MaxSize, none, none);


        %%%%%%%%CONSUMER%%%%%%%%
        {isEmptyQ,WC} when length(BufferData) > 0 -> 
            WC!notEmpty,
            buffer(BufferData, MaxSize, none, WaitingProducer);


        {isEmptyQ,WC} ->
            WC!empty,
            buffer(BufferData, MaxSize, WC, WaitingProducer);

        
        %%%%%%%%DATA%%%%%%%%
        {getData,WC} ->  
            if length(BufferData) == 0 -> 
                WC!empty,
                buffer(BufferData,MaxSize, none, WaitingProducer); 
            true ->
                [Head|Tail] = BufferData,
                WC!{data,Head}, 
                WaitingProducer!notFull,
                buffer(Tail,MaxSize, none, WaitingProducer)
            end;


           
        {data,Msg} -> 
            if length(BufferData) == 0 ->
                if WaitingConsumer /= none -> WaitingConsumer!notEmpty;
                true -> pass end,
                buffer([Msg] , MaxSize, WaitingConsumer, WaitingProducer);
            true ->
                if WaitingConsumer /= none -> WaitingConsumer!notEmpty;
                true -> pass end,
                buffer(BufferData ++ Msg , MaxSize, WaitingConsumer, WaitingProducer)
            end
    end.

%Task 4
%Main function to spawn Buffer, Logger and passes correct parameters to cosumer and producer
main () ->
    B = spawn(?MODULE,buffer,[5]),
    L = spawn(?MODULE, logger,[0]),
    C = spawn(?MODULE,consumer,[B,L,0]),
    P = spawn(producer, producer,[5,L,B]).
    


