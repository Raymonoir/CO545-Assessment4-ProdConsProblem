-module(rw468).
-compile(export_all).


% Task1
logger (Count) ->
    receive 
        %If any message received, output count + message
        Message -> io:fwrite("Logger Number [~w]: ~w",[Count,Message]), logger(Count+1) 
    end.



% Task2
consumer (Buffer,Logger,Count) ->
    %c0 -> c1
    Buffer!{isEmptyQ,self()},

    receive 
        %c1 -> c2
        empty ->
            Logger!"Consumer received empty",
            receive 
                notEmpty -> 
                    Logger!"Consumer received notEmpty",
                    subConsumer(Buffer,Logger, Count)
            end;
        %c1-> c3
        notEmpty -> 
            Logger!"Consumer received notEmpty",
            subConsumer(Buffer,Logger, Count)
    end.


subConsumer(Buffer, Logger,Count) ->
    %c3 -> c4
    Buffer!{getData,self()},

    receive
        %c4 -> c0
        {data,Msg} -> 
            Logger!"Consumer recieved data: #" + Count + " = " + Msg,
            consumer(Buffer,Logger,Count+1)
    end.



buffer(MaxSize) ->buffer([], MaxSize, none, none).
buffer(BufferData, MaxSize, WaitingConsumer, WaitingProducer) ->

    receive 
        %%%%%%%%PRODUCER%%%%%%%%
        {isFullQ,WP} when length(BufferData) < MaxSize ->
            WP!notFull,
            receive 
                {data,Msg} -> 
                    io:fwrite("WE GOT: ~s ~n",[Msg]),
                    io:fwrite("Buffer is now: ~s ~n",[[BufferData|Msg]]),
                    WaitingConsumer!notEmpty,
                    buffer([BufferData|Msg] , MaxSize, WaitingConsumer, WP)      
            end;
        {isFullQ,WP} ->
            WP!full,
            buffer(BufferData, MaxSize, WaitingConsumer, WP);
    


        %%%%%%%%CONSUMER%%%%%%%%
        {isEmptyQ,WC} when length(BufferData) > 0 -> 
            WC!notEmpty,
            io:fwrite("BufferData > 0 ~n"),
            receive 
                {getData,WC} -> [Head|Tail] = BufferData, 
                io:fwrite("Head: ~w, Tail: ~w ~n",[Head,Tail]),
                WC!{data,Head}, 
                WaitingProducer!notFull,
                buffer(Tail,MaxSize, WC, WaitingProducer)
                
            end;
        {isEmptyQ,WC} ->
            io:fwrite("BufferData = 0 ~n"),
            WC!empty,
            buffer(BufferData, MaxSize, WC, WaitingProducer) 
            
    end.



